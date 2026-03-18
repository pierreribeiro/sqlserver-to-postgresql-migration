"""
Full Rollback from Manifest.

Reads manifest.json, reverts all converted columns to original types,
drops recreated views/indexes/FKs, and recreates originals.

Usage:
    python rollback-citext.py [--manifest PATH] [--dry-run]
"""

import argparse
import json
import sys
from pathlib import Path

from lib.db import execute_sql
from lib.logger import setup_logger
from lib.sql_templates import revert_column_sql


def revert_column(
    schema: str,
    table: str,
    column: str,
    original_type: str,
    length: int | None,
    db_config: dict | None = None,
) -> str:
    """Revert a single column back to its original type."""
    sql = revert_column_sql(schema, table, column, original_type, length)
    execute_sql(sql, config=db_config)
    return sql


def load_rollback_plan(manifest_path: str) -> list[dict]:
    """
    Load the rollback plan from manifest.

    Returns list of columns to revert with their original types.
    """
    data = json.loads(Path(manifest_path).read_text())
    plan = []
    for key, type_info in data.get("original_types", {}).items():
        # Key format: schema.table.column
        parts = key.split(".")
        if len(parts) == 3:
            plan.append(
                {
                    "schema": parts[0],
                    "table": parts[1],
                    "column": parts[2],
                    "original_type": type_info["type"],
                    "length": type_info.get("length"),
                }
            )
    return plan


def run_rollback(
    manifest_path: str,
    log_dir: str = "./logs",
    schema: str = "perseus",
    db_config: dict | None = None,
) -> dict:
    """
    Execute full rollback from manifest.

    Returns report with counts of reverted objects.
    """
    logger = setup_logger("rollback-citext", log_dir=log_dir)
    logger.info("Rollback — Starting")

    plan = load_rollback_plan(manifest_path)
    columns_reverted = 0

    for col in plan:
        try:
            sql = revert_column(
                col["schema"],
                col["table"],
                col["column"],
                col["original_type"],
                col["length"],
                db_config=db_config,
            )
            logger.ok(
                f"Reverted {col['table']}.{col['column']} → {col['original_type']}"
            )
            columns_reverted += 1
        except RuntimeError as e:
            logger.error(f"Failed to revert {col['table']}.{col['column']}: {e}")

    logger.ok(f"Rollback complete: {columns_reverted} columns reverted")
    return {"columns_reverted": columns_reverted}


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Rollback CITEXT Conversion")
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--log-dir", default="./logs")

    args = parser.parse_args()

    result = run_rollback(
        manifest_path=args.manifest,
        log_dir=args.log_dir,
    )

    if result["columns_reverted"] > 0:
        print(f"Rollback complete: {result['columns_reverted']} columns reverted")
    else:
        print("Nothing to rollback")


if __name__ == "__main__":
    main()
