"""
Phase 2b: ALTER COLUMN TYPE — Cache Tables.

Converts cache table VARCHAR columns to CITEXT using Direct ALTER (no TRUNCATE).
Order: dirty_leaves -> m_downstream -> m_upstream (largest last).

Usage:
    python 02b-alter-cache-tables.py [--config PATH] [--dry-run] [--resume]
"""

import argparse
import sys

from lib.db import execute_sql
from lib.dependency import get_cache_columns, load_config
from lib.logger import setup_logger
from lib.manifest import Manifest
from lib.sql_templates import alter_column_sql


def alter_cache_column(
    schema: str, table: str, column: str, db_config: dict | None = None
) -> str:
    """ALTER a single cache table column to CITEXT and return the SQL used."""
    sql = alter_column_sql(schema, table, column)
    execute_sql(sql, config=db_config)
    return sql


def run_alter_cache_tables(
    config: dict,
    manifest_path: str,
    log_dir: str = "./logs",
    schema: str = "perseus",
    db_config: dict | None = None,
) -> dict:
    """
    Orchestrate Phase 2b: ALTER cache table columns.

    Order: cache_dirty_leaves -> cache_downstream -> cache_upstream.
    Uses Direct ALTER (no TRUNCATE).
    """
    manifest = Manifest(manifest_path)
    manifest.create()
    manifest.start_phase("02b-alter-cache-tables")

    cache_tables_config = config.get("cache_tables", {}).get("tables", [])

    columns_converted = 0
    tables_processed = []
    executed_sqls = []

    # Process cache tables in config order (dirty_leaves -> downstream -> upstream)
    for table_group in cache_tables_config:
        for col in table_group.get("columns", []):
            table = col["table"]
            column = col["column"]
            sql = alter_cache_column(schema, table, column, db_config=db_config)
            manifest.record_column_converted(table, column, "character varying", None)
            columns_converted += 1
            executed_sqls.append(sql)
            if table not in tables_processed:
                tables_processed.append(table)

    manifest.complete_phase("02b-alter-cache-tables")

    return {
        "columns_converted": columns_converted,
        "tables_processed": tables_processed,
        "executed_sqls": executed_sqls,
    }


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Phase 2b: ALTER COLUMN TYPE — Cache Tables"
    )
    parser.add_argument("--config", default="config/citext-conversion.yaml")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--log-dir", default="./logs")
    parser.add_argument("--resume", action="store_true")

    args = parser.parse_args()

    logger = setup_logger("02b-alter-cache-tables", log_dir=args.log_dir)
    logger.info("Phase 2b: ALTER COLUMN TYPE — Cache Tables — Starting")

    config = load_config(args.config)
    report = run_alter_cache_tables(
        config=config,
        manifest_path=args.manifest,
        log_dir=args.log_dir,
    )

    logger.ok(f"Phase 2b complete: {report['columns_converted']} columns converted")


if __name__ == "__main__":
    main()
