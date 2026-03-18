"""
Phase 2a: ALTER COLUMN TYPE — Regular Tables.

Converts VARCHAR columns to CITEXT. FK groups converted in single transaction.
Cache tables excluded (handled in Phase 2b).

Usage:
    python 02-alter-columns.py [--config PATH] [--dry-run] [--resume]
"""

import argparse
import sys

from lib.db import execute_sql
from lib.dependency import (
    get_all_target_columns,
    get_cache_columns,
    get_fk_group_columns,
    get_regular_columns,
    load_config,
)
from lib.logger import setup_logger
from lib.manifest import Manifest
from lib.sql_templates import (
    alter_column_sql,
    fk_group_alter_sql,
    verify_column_type_sql,
)


def alter_single_column(
    schema: str, table: str, column: str, db_config: dict | None = None
) -> str:
    """ALTER a single column to CITEXT and return the SQL used."""
    sql = alter_column_sql(schema, table, column)
    execute_sql(sql, config=db_config)
    return sql


def alter_table_columns(
    schema: str, table: str, columns: list[str], db_config: dict | None = None
) -> list[str]:
    """ALTER all columns of a table to CITEXT."""
    sqls = []
    for col in columns:
        sql = alter_single_column(schema, table, col, db_config=db_config)
        sqls.append(sql)
    return sqls


def alter_table_columns_with_resume(
    schema: str,
    table: str,
    columns: list[str],
    manifest: Manifest,
    db_config: dict | None = None,
) -> list[str]:
    """ALTER columns with resume support — skip already converted."""
    sqls = []
    for col in columns:
        if manifest.is_column_converted(table, col):
            continue
        sql = alter_single_column(schema, table, col, db_config=db_config)
        manifest.record_column_converted(table, col, "character varying", None)
        sqls.append(sql)
    return sqls


def alter_fk_group(
    schema: str, columns: list[dict], db_config: dict | None = None
) -> str:
    """ALTER FK group columns in a single transaction."""
    sql = fk_group_alter_sql(schema, columns)
    execute_sql(sql, config=db_config)
    return sql


def verify_column_type(
    schema: str, table: str, column: str, db_config: dict | None = None
) -> bool:
    """Verify a column has been converted to CITEXT."""
    sql = verify_column_type_sql(schema, table, column)
    result = execute_sql(sql, config=db_config)
    return result.strip() == "citext"


def run_alter_columns(
    config: dict,
    manifest_path: str,
    log_dir: str = "./logs",
    schema: str = "perseus",
    db_config: dict | None = None,
) -> dict:
    """
    Orchestrate Phase 2a: ALTER regular table columns.

    Excludes cache tables (m_upstream, m_downstream).
    FK groups converted in single transaction.
    """
    manifest = Manifest(manifest_path)
    manifest.create()
    manifest.start_phase("02-alter-columns")

    cache_tables = {c["table"] for c in get_cache_columns(config)}
    regular_columns = get_regular_columns(config)

    columns_converted = 0
    tables_processed = []

    # Group regular columns by table
    table_columns: dict[str, list[str]] = {}
    for col in regular_columns:
        if col["table"] in cache_tables:
            continue
        table_columns.setdefault(col["table"], []).append(col["column"])

    # Process regular tables
    for table, columns in sorted(table_columns.items()):
        if not columns:
            continue
        sqls = alter_table_columns_with_resume(
            schema, table, columns, manifest, db_config=db_config
        )
        columns_converted += len(sqls)
        if sqls:
            tables_processed.append(table)

    # Process FK groups
    for group in config.get("fk_groups", []):
        fk_columns = group.get("columns", [])
        if fk_columns:
            alter_fk_group(schema, fk_columns, db_config=db_config)
            for col in fk_columns:
                manifest.record_column_converted(
                    col["table"], col["column"], "character varying", None
                )
                columns_converted += 1
                if col["table"] not in tables_processed:
                    tables_processed.append(col["table"])

    manifest.complete_phase("02-alter-columns")

    return {
        "columns_converted": columns_converted,
        "tables_processed": tables_processed,
    }


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Phase 2a: ALTER COLUMN TYPE — Regular Tables"
    )
    parser.add_argument("--config", default="config/citext-conversion.yaml")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--log-dir", default="./logs")
    parser.add_argument("--resume", action="store_true")

    args = parser.parse_args()

    logger = setup_logger("02-alter-columns", log_dir=args.log_dir)
    logger.info("Phase 2a: ALTER COLUMN TYPE — Starting")

    config = load_config(args.config)
    report = run_alter_columns(
        config=config,
        manifest_path=args.manifest,
        log_dir=args.log_dir,
    )

    logger.ok(f"Phase 2a complete: {report['columns_converted']} columns converted")


if __name__ == "__main__":
    main()
