"""
Phase 2a: ALTER COLUMN TYPE — Regular Tables.

Converts VARCHAR columns to CITEXT. FK groups converted in single transaction.
Cache tables excluded (handled in Phase 2b).

Usage:
    python 02-alter-columns.py [--config PATH] [--dry-run] [--resume]
"""

import argparse
import logging
import os
import sys
from pathlib import Path

from lib.db import execute_sql, execute_sql_safe
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
    run_id: str | None = None,
) -> list[str]:
    """ALTER columns with resume support — skip already converted."""
    logger = logging.getLogger("citext.alter-columns")
    sqls = []
    for col in columns:
        if manifest.is_column_converted(table, col):
            continue
        if verify_column_type(schema, table, col, db_config=db_config):
            logger.warning(f"Column {schema}.{table}.{col} already CITEXT — skipping")
            manifest.record_column_converted(table, col, "citext", None)
            continue
        sql = alter_column_sql(schema, table, col)
        success, _, error = execute_sql_safe(
            sql,
            config=db_config,
            run_id=run_id,
            phase="02-alter-columns",
            context={
                "schema_name": schema,
                "table_name": table,
                "column_name": col,
                "object_type": "column",
                "operation": "ALTER",
            },
        )
        if success:
            manifest.record_column_converted(table, col, "character varying", None)
            sqls.append(sql)
        else:
            logger.error(f"ALTER {schema}.{table}.{col} failed: {error}")
    return sqls


def alter_fk_group(
    schema: str,
    columns: list[dict],
    db_config: dict | None = None,
    run_id: str | None = None,
) -> str | None:
    """ALTER FK group columns in a single transaction. Returns SQL or None on error."""
    sql = fk_group_alter_sql(schema, columns)
    success, _, error = execute_sql_safe(
        sql,
        config=db_config,
        run_id=run_id,
        phase="02-alter-columns",
        context={
            "schema_name": schema,
            "object_type": "fk_group",
            "operation": "ALTER",
        },
    )
    if success:
        return sql
    logger = logging.getLogger("citext.alter-columns")
    col_names = ", ".join(f"{c['table']}.{c['column']}" for c in columns)
    logger.error(f"FK group ALTER failed ({col_names}): {error}")
    # Log each column in the group as failed
    if run_id:
        from lib.error_log import log_error

        for c in columns:
            log_error(
                run_id,
                "02-alter-columns",
                "ERROR",
                f"FK group ALTER failed — column part of failed transaction: {error}",
                schema_name=schema,
                table_name=c["table"],
                column_name=c["column"],
                object_type="fk_group_column",
                operation="ALTER",
                db_config=db_config,
            )
    return None


def verify_column_type(
    schema: str, table: str, column: str, db_config: dict | None = None
) -> bool:
    """Verify a column has been converted to CITEXT."""
    sql = verify_column_type_sql(schema, table, column)
    try:
        result = execute_sql(sql, config=db_config)
        return result.strip() == "citext"
    except RuntimeError:
        return False


def run_alter_columns(
    config: dict,
    manifest_path: str,
    log_dir: str = "./logs",
    schema: str = "perseus",
    db_config: dict | None = None,
    run_id: str | None = None,
) -> dict:
    """
    Orchestrate Phase 2a: ALTER regular table columns.

    Excludes cache tables (m_upstream, m_downstream).
    FK groups converted in single transaction.
    """
    manifest = Manifest(manifest_path)
    if Path(manifest_path).exists():
        manifest.load()
    else:
        manifest.create()
    manifest.start_phase("02-alter-columns")

    cache_tables = {c["table"] for c in get_cache_columns(config)}
    regular_columns = get_regular_columns(config)

    columns_converted = 0
    errors_count = 0
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
            schema, table, columns, manifest, db_config=db_config, run_id=run_id
        )
        columns_converted += len(sqls)
        errors_count += len(columns) - len(sqls)
        if sqls:
            tables_processed.append(table)

    # Process FK groups
    logger = logging.getLogger("citext.alter-columns")
    for group in config.get("fk_groups", []):
        fk_columns = group.get("columns", [])
        columns_to_alter = []
        for col in fk_columns:
            if verify_column_type(
                schema, col["table"], col["column"], db_config=db_config
            ):
                logger.warning(
                    f"FK column {schema}.{col['table']}.{col['column']} already CITEXT — skipping"
                )
                manifest.record_column_converted(
                    col["table"], col["column"], "citext", None
                )
            else:
                columns_to_alter.append(col)
        if columns_to_alter:
            sql = alter_fk_group(
                schema, columns_to_alter, db_config=db_config, run_id=run_id
            )
            if sql:
                for col in columns_to_alter:
                    manifest.record_column_converted(
                        col["table"], col["column"], "character varying", None
                    )
                    columns_converted += 1
                    if col["table"] not in tables_processed:
                        tables_processed.append(col["table"])
            else:
                errors_count += len(columns_to_alter)

    manifest.complete_phase("02-alter-columns")

    return {
        "columns_converted": columns_converted,
        "tables_processed": tables_processed,
        "errors_count": errors_count,
    }


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Phase 2a: ALTER COLUMN TYPE — Regular Tables"
    )
    parser.add_argument("--config", default="config/citext-conversion.yaml")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--log-dir", default=os.environ.get("LOG_DIR", "./logs"))
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
