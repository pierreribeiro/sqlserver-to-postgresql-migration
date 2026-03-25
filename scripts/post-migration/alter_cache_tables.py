"""
Phase 2b: ALTER COLUMN TYPE — Cache Tables.

Converts cache table VARCHAR columns to CITEXT using Direct ALTER (no TRUNCATE).
Order: dirty_leaves -> m_downstream -> m_upstream (largest last).

Usage:
    python 02b-alter-cache-tables.py [--config PATH] [--dry-run] [--resume]
"""

import argparse
import logging
import os
import sys
from pathlib import Path

from lib.db import execute_sql, execute_sql_safe
from lib.dependency import get_cache_columns, load_config
from lib.logger import setup_logger
from lib.manifest import Manifest
from lib.sql_templates import alter_column_sql, verify_column_type_sql


def _is_already_citext(
    schema: str, table: str, column: str, db_config: dict | None = None
) -> bool:
    """Check if a column is already CITEXT via information_schema."""
    sql = verify_column_type_sql(schema, table, column)
    try:
        result = execute_sql(sql, config=db_config).strip()
        return result == "citext"
    except RuntimeError:
        return False


def alter_cache_column(
    schema: str,
    table: str,
    column: str,
    db_config: dict | None = None,
    run_id: str | None = None,
) -> str | None:
    """ALTER a single cache table column to CITEXT. Returns SQL or None on error."""
    sql = alter_column_sql(schema, table, column)
    success, _, error = execute_sql_safe(
        sql,
        config=db_config,
        run_id=run_id,
        phase="02b-alter-cache-tables",
        context={
            "schema_name": schema,
            "table_name": table,
            "column_name": column,
            "object_type": "column",
            "operation": "ALTER",
        },
    )
    if success:
        return sql
    logger = logging.getLogger("citext.alter-cache-tables")
    logger.error(f"ALTER {schema}.{table}.{column} failed: {error}")
    return None


def run_alter_cache_tables(
    config: dict,
    manifest_path: str,
    log_dir: str = "./logs",
    schema: str = "perseus",
    db_config: dict | None = None,
    run_id: str | None = None,
) -> dict:
    """
    Orchestrate Phase 2b: ALTER cache table columns.

    Order: cache_dirty_leaves -> cache_downstream -> cache_upstream.
    Uses Direct ALTER (no TRUNCATE).
    """
    manifest = Manifest(manifest_path)
    if Path(manifest_path).exists():
        manifest.load()
    else:
        manifest.create()
    manifest.start_phase("02b-alter-cache-tables")

    logger = logging.getLogger("citext.alter-cache-tables")
    cache_tables_config = config.get("cache_tables", {}).get("tables", [])

    columns_converted = 0
    errors_count = 0
    tables_processed = []
    executed_sqls = []

    # Process cache tables in config order (dirty_leaves -> downstream -> upstream)
    for table_group in cache_tables_config:
        for col in table_group.get("columns", []):
            table = col["table"]
            column = col["column"]
            if _is_already_citext(schema, table, column, db_config=db_config):
                logger.warning(
                    f"Cache column {schema}.{table}.{column} already CITEXT — skipping"
                )
                manifest.record_column_converted(table, column, "citext", None)
                continue
            sql = alter_cache_column(
                schema, table, column, db_config=db_config, run_id=run_id
            )
            if sql:
                manifest.record_column_converted(
                    table, column, "character varying", None
                )
                columns_converted += 1
                executed_sqls.append(sql)
                if table not in tables_processed:
                    tables_processed.append(table)
            else:
                errors_count += 1

    manifest.complete_phase("02b-alter-cache-tables")

    return {
        "columns_converted": columns_converted,
        "tables_processed": tables_processed,
        "executed_sqls": executed_sqls,
        "errors_count": errors_count,
    }


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Phase 2b: ALTER COLUMN TYPE — Cache Tables"
    )
    parser.add_argument("--config", default="config/citext-conversion.yaml")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--log-dir", default=os.environ.get("LOG_DIR", "./logs"))
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
