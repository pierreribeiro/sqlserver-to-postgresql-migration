"""
Phase 0: Pre-flight Analysis for CITEXT Column Conversion.

Verifies prerequisites, discovers dependencies, checks for case-variant
duplicates, and generates the conversion manifest.

Usage:
    python 00-preflight-check.py [--test-connection] [--config PATH] [--dry-run]
"""

import argparse
import json
import os
import sys
from pathlib import Path

from lib.db import execute_sql, load_db_config, test_connection as _test_conn
from lib.dependency import load_config, get_all_target_columns
from lib.logger import setup_logger
from lib.manifest import Manifest


def check_citext_extension(config: dict | None = None) -> bool:
    """Check if the citext extension is enabled."""
    result = execute_sql(
        "SELECT extname FROM pg_extension WHERE extname = 'citext';",
        config=config,
    )
    return "citext" in result.strip()


def check_permissions(config: dict | None = None) -> bool:
    """Check if current user has superuser or ALTER privileges."""
    result = execute_sql(
        "SELECT current_setting('is_superuser');",
        config=config,
    )
    return result.strip() == "t"


def check_case_variant_duplicates(
    schema: str, table: str, column: str, config: dict | None = None
) -> list[dict]:
    """
    Check for case-variant duplicates on a column.

    Returns list of {value, count} dicts for duplicate groups.
    """
    sql = (
        f"SELECT LOWER({column}) AS val, COUNT(*) AS cnt "
        f"FROM {schema}.{table} "
        f"GROUP BY LOWER({column}) "
        f"HAVING COUNT(*) > 1;"
    )
    result = execute_sql(sql, config=config)
    dupes = []
    for line in result.strip().splitlines():
        if not line.strip():
            continue
        parts = line.split("|")
        if len(parts) >= 2:
            dupes.append({"value": parts[0].strip(), "count": int(parts[1].strip())})
    return dupes


def discover_fk_constraints(
    schema: str, table: str, config: dict | None = None
) -> list[dict]:
    """
    Discover FK constraints referencing a table's columns.

    Returns list of constraint info dicts.
    """
    sql = (
        f"SELECT c.conname, child_t.relname, child_a.attname, "
        f"parent_t.relname, parent_a.attname "
        f"FROM pg_constraint c "
        f"JOIN pg_class child_t ON c.conrelid = child_t.oid "
        f"JOIN pg_class parent_t ON c.confrelid = parent_t.oid "
        f"JOIN pg_namespace n ON parent_t.relnamespace = n.oid "
        f"JOIN pg_attribute child_a ON child_a.attrelid = child_t.oid "
        f"AND child_a.attnum = ANY(c.conkey) "
        f"JOIN pg_attribute parent_a ON parent_a.attrelid = parent_t.oid "
        f"AND parent_a.attnum = ANY(c.confkey) "
        f"WHERE c.contype = 'f' "
        f"AND n.nspname = '{schema}' "
        f"AND parent_t.relname = '{table}';"
    )
    result = execute_sql(sql, config=config)
    fks = []
    for line in result.strip().splitlines():
        if not line.strip():
            continue
        parts = line.split("|")
        if len(parts) >= 5:
            fks.append(
                {
                    "constraint_name": parts[0].strip(),
                    "child_table": parts[1].strip(),
                    "child_column": parts[2].strip(),
                    "parent_table": parts[3].strip(),
                    "parent_column": parts[4].strip(),
                }
            )
    return fks


def discover_indexes(
    schema: str, table: str, column: str, config: dict | None = None
) -> list[dict]:
    """Discover indexes on a specific column."""
    sql = (
        f"SELECT i.relname, t.relname, pg_get_indexdef(i.oid) "
        f"FROM pg_index ix "
        f"JOIN pg_class t ON ix.indrelid = t.oid "
        f"JOIN pg_class i ON ix.indexrelid = i.oid "
        f"JOIN pg_namespace n ON t.relnamespace = n.oid "
        f"JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey) "
        f"WHERE n.nspname = '{schema}' "
        f"AND t.relname = '{table}' "
        f"AND a.attname = '{column}' "
        f"AND NOT EXISTS (SELECT 1 FROM pg_constraint pc WHERE pc.conindid = i.oid);"
    )
    result = execute_sql(sql, config=config)
    indexes = []
    for line in result.strip().splitlines():
        if not line.strip():
            continue
        parts = line.split("|")
        if len(parts) >= 3:
            indexes.append(
                {
                    "index_name": parts[0].strip(),
                    "table_name": parts[1].strip(),
                    "ddl": parts[2].strip(),
                }
            )
    return indexes


def discover_dependent_views(
    schema: str, table: str, config: dict | None = None
) -> list[dict]:
    """Discover views that DIRECTLY depend on a table (flat, no recursion)."""
    sql = (
        f"SELECT DISTINCT c.relname, c.relkind "
        f"FROM pg_depend d "
        f"JOIN pg_rewrite r ON d.objid = r.oid "
        f"JOIN pg_class c ON r.ev_class = c.oid "
        f"JOIN pg_class t ON d.refobjid = t.oid "
        f"JOIN pg_namespace n ON t.relnamespace = n.oid "
        f"WHERE n.nspname = '{schema}' "
        f"AND t.relname = '{table}' "
        f"AND c.relname != t.relname "
        f"AND c.relkind IN ('v', 'm');"
    )
    result = execute_sql(sql, config=config)
    views = []
    for line in result.strip().splitlines():
        if not line.strip():
            continue
        parts = line.split("|")
        if len(parts) >= 2:
            kind = "materialized_view" if parts[1].strip() == "m" else "view"
            views.append({"name": parts[0].strip(), "type": kind})
    return views


def discover_all_dependent_views(
    schema: str, table: str, config: dict | None = None
) -> list[dict]:
    """
    Recursively discover ALL views/MVs depending on a table (direct + transitive).

    Uses a recursive CTE to walk the full dependency tree via pg_depend/pg_rewrite.
    Returns list of {name, type, depth} dicts ordered by depth (deepest last).
    """
    sql = (
        f"WITH RECURSIVE view_deps AS ("
        f"  SELECT DISTINCT c.oid, c.relname, c.relkind, 0 AS depth "
        f"  FROM pg_depend d "
        f"  JOIN pg_rewrite r ON d.objid = r.oid "
        f"  JOIN pg_class c ON r.ev_class = c.oid "
        f"  JOIN pg_class t ON d.refobjid = t.oid "
        f"  JOIN pg_namespace n ON t.relnamespace = n.oid "
        f"  WHERE n.nspname = '{schema}' AND t.relname = '{table}' "
        f"    AND c.relname != t.relname AND c.relkind IN ('v', 'm') "
        f" UNION "
        f"  SELECT DISTINCT c2.oid, c2.relname, c2.relkind, vd.depth + 1 "
        f"  FROM view_deps vd "
        f"  JOIN pg_depend d2 ON d2.refobjid = vd.oid "
        f"  JOIN pg_rewrite r2 ON d2.objid = r2.oid "
        f"  JOIN pg_class c2 ON r2.ev_class = c2.oid "
        f"  WHERE c2.relname != vd.relname AND c2.relkind IN ('v', 'm') "
        f") "
        f"SELECT DISTINCT relname, relkind, MAX(depth) AS depth "
        f"FROM view_deps GROUP BY relname, relkind ORDER BY depth;"
    )
    result = execute_sql(sql, config=config)
    views = []
    for line in result.strip().splitlines():
        if not line.strip():
            continue
        parts = line.split("|")
        if len(parts) >= 3:
            kind = "materialized_view" if parts[1].strip() == "m" else "view"
            views.append(
                {
                    "name": parts[0].strip(),
                    "type": kind,
                    "depth": int(parts[2].strip()),
                }
            )
    return views


def generate_manifest(
    config: dict,
    manifest_path: str,
    schema: str = "perseus",
    db_config: dict | None = None,
) -> None:
    """Generate the conversion manifest from config and discovered dependencies."""
    m = Manifest(manifest_path)
    if Path(manifest_path).exists():
        m.load()
    else:
        m.create()

    # Store all target columns' original types
    columns = get_all_target_columns(config)
    original_types = {}
    for col in columns:
        key = f"{schema}.{col['table']}.{col['column']}"
        try:
            result = execute_sql(
                f"SELECT udt_name FROM information_schema.columns "
                f"WHERE table_schema = '{schema}' "
                f"AND table_name = '{col['table']}' "
                f"AND column_name = '{col['column']}';",
                config=db_config,
            )
            original_types[key] = {
                "type": result.strip() or "character varying",
                "length": None,
            }
        except RuntimeError:
            original_types[key] = {"type": "character varying", "length": None}

    m.data["original_types"] = original_types
    m.data["target_columns"] = [
        {"table": c["table"], "column": c["column"]} for c in columns
    ]
    m._save()


def validate_columns_exist(
    config: dict,
    schema: str = "perseus",
    db_config: dict | None = None,
) -> tuple[list[dict], list[dict]]:
    """
    Check all YAML columns against information_schema.columns.

    Returns (valid_columns, phantom_columns).
    Each entry is {table, column}.

    Raises RuntimeError if phantom_count > 50% of total (safety valve D5).
    """
    all_columns = get_all_target_columns(config)
    if not all_columns:
        return ([], [])

    # Build batch query — single round-trip to DB
    pairs = ", ".join(f"('{col['table']}', '{col['column']}')" for col in all_columns)
    sql = (
        f"SELECT table_name, column_name "
        f"FROM information_schema.columns "
        f"WHERE table_schema = '{schema}' "
        f"AND (table_name, column_name) IN ({pairs});"
    )
    result = execute_sql(sql, config=db_config).strip()

    existing = set()
    for line in result.splitlines():
        if not line.strip():
            continue
        parts = line.split("|")
        if len(parts) >= 2:
            existing.add((parts[0].strip(), parts[1].strip()))

    valid = []
    phantoms = []
    for col in all_columns:
        if (col["table"], col["column"]) in existing:
            valid.append(col)
        else:
            phantoms.append(col)

    # Safety valve (D5): if phantom_count > 50% → abort
    if phantoms and len(phantoms) > len(all_columns) * 0.5:
        raise RuntimeError(
            f"SAFETY VALVE: {len(phantoms)}/{len(all_columns)} columns "
            f"({len(phantoms) * 100 // len(all_columns)}%) appear phantom. "
            f"Likely wrong schema/database. Aborting — YAML NOT rewritten."
        )

    return (valid, phantoms)


def run_preflight(
    config: dict | None = None,
    manifest_path: str = "./manifest.json",
    log_dir: str = "./logs",
    test_connection_only: bool = False,
    db_config: dict | None = None,
) -> dict:
    """
    Run the full pre-flight analysis.

    Args:
        config: parsed citext-conversion.yaml dict
        manifest_path: path for manifest.json output
        log_dir: directory for log files
        test_connection_only: if True, only test connectivity

    Returns:
        Report dict with check results
    """
    report = {}

    # Test connection
    report["connection"] = _test_conn(config=db_config)

    if test_connection_only:
        return report

    # Check citext extension
    report["citext_extension"] = check_citext_extension(config=db_config)

    # Check permissions
    report["permissions"] = check_permissions(config=db_config)

    # Generate manifest
    if config:
        generate_manifest(
            config=config,
            manifest_path=manifest_path,
            db_config=db_config,
        )
        report["manifest_generated"] = True

    return report


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Phase 0: Pre-flight Analysis for CITEXT Conversion"
    )
    parser.add_argument(
        "--test-connection", action="store_true", help="Only test DB connectivity"
    )
    parser.add_argument(
        "--config",
        default="config/citext-conversion.yaml",
        help="Path to citext-conversion.yaml",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Show SQL without executing"
    )
    parser.add_argument("--manifest", default="./manifest.json", help="Manifest path")
    parser.add_argument(
        "--log-dir", default=os.environ.get("LOG_DIR", "./logs"), help="Log directory"
    )

    args = parser.parse_args()

    logger = setup_logger("00-preflight-check", log_dir=args.log_dir)
    logger.info("Phase 0: Pre-flight Analysis — Starting")

    config = load_config(args.config) if not args.test_connection else None

    report = run_preflight(
        config=config,
        manifest_path=args.manifest,
        log_dir=args.log_dir,
        test_connection_only=args.test_connection,
    )

    if not report.get("connection"):
        logger.abort("Database connection FAILED")
        sys.exit(1)

    logger.ok("Pre-flight analysis complete")
    logger.info(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
