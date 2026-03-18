"""
Phase 0: Pre-flight Analysis for CITEXT Column Conversion.

Verifies prerequisites, discovers dependencies, checks for case-variant
duplicates, and generates the conversion manifest.

Usage:
    python 00-preflight-check.py [--test-connection] [--config PATH] [--dry-run]
"""

import argparse
import json
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
        f"AND a.attname = '{column}';"
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
    """Discover views that depend on a table."""
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


def generate_manifest(
    config: dict,
    manifest_path: str,
    schema: str = "perseus",
    db_config: dict | None = None,
) -> None:
    """Generate the conversion manifest from config and discovered dependencies."""
    m = Manifest(manifest_path)
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
    parser.add_argument("--log-dir", default="./logs", help="Log directory")

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
