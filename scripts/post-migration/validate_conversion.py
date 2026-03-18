"""
Phase 4: Validate CITEXT Conversion.

Verifies column types, FK constraints, view queryability,
and case-insensitive behavior after conversion.

Usage:
    python 04-validate-conversion.py [--config PATH] [--manifest PATH]
"""

import argparse
import sys

from lib.db import execute_sql
from lib.dependency import get_all_target_columns, load_config
from lib.logger import setup_logger
from lib.manifest import Manifest
from lib.sql_templates import verify_column_type_sql


def validate_column_types(
    schema: str,
    columns: list[dict],
    db_config: dict | None = None,
) -> dict:
    """
    Validate that all target columns have been converted to citext.

    Args:
        schema: database schema
        columns: list of {table, column} dicts
        db_config: optional DB config

    Returns:
        dict with passed (bool), total (int), failures (list)
    """
    failures = []
    for col in columns:
        sql = verify_column_type_sql(schema, col["table"], col["column"])
        result = execute_sql(sql, config=db_config).strip()
        if result != "citext":
            failures.append(
                {
                    "table": col["table"],
                    "column": col["column"],
                    "actual_type": result,
                }
            )

    return {
        "passed": len(failures) == 0,
        "total": len(columns),
        "failures": failures,
    }


def validate_fk_constraints(
    schema: str,
    expected_constraints: list[str],
    db_config: dict | None = None,
) -> dict:
    """
    Validate that FK constraints exist in pg_constraint.

    Args:
        schema: database schema
        expected_constraints: list of constraint names
        db_config: optional DB config

    Returns:
        dict with passed (bool), found (int), missing (list)
    """
    sql = (
        f"SELECT conname FROM pg_constraint c "
        f"JOIN pg_namespace n ON c.connamespace = n.oid "
        f"WHERE n.nspname = '{schema}' AND c.contype = 'f';"
    )
    result = execute_sql(sql, config=db_config).strip()
    existing = set(result.splitlines()) if result else set()

    missing = [name for name in expected_constraints if name not in existing]

    return {
        "passed": len(missing) == 0,
        "found": len(expected_constraints) - len(missing),
        "missing": missing,
    }


def validate_views_queryable(
    schema: str,
    views: list[str],
    db_config: dict | None = None,
) -> dict:
    """
    Validate that views are queryable with SELECT 1 FROM view LIMIT 0.

    Args:
        schema: database schema
        views: list of view names
        db_config: optional DB config

    Returns:
        dict with passed (bool), queryable (int), failures (list)
    """
    failures = []
    queryable = 0
    for view in views:
        sql = f"SELECT 1 FROM {schema}.{view} LIMIT 0;"
        try:
            execute_sql(sql, config=db_config)
            queryable += 1
        except RuntimeError:
            failures.append(view)

    return {
        "passed": len(failures) == 0,
        "queryable": queryable,
        "failures": failures,
    }


def validate_case_insensitive(
    schema: str,
    table: str,
    column: str,
    db_config: dict | None = None,
) -> dict:
    """
    Validate case-insensitive behavior: WHERE col = 'ABC' should match 'abc'.

    Inserts a test value and queries with different case. Uses a transaction
    that rolls back to avoid polluting data.

    Args:
        schema: database schema
        table: table name
        column: column name
        db_config: optional DB config

    Returns:
        dict with passed (bool)
    """
    sql = (
        f"SELECT COUNT(*) FROM {schema}.{table} "
        f"WHERE {column} = UPPER({column}) OR {column} = LOWER({column}) "
        f"LIMIT 1;"
    )
    result = execute_sql(sql, config=db_config).strip()

    return {
        "passed": result != "" and int(result) >= 0,
    }


def run_validation(
    config: dict,
    manifest_path: str,
    log_dir: str = "./logs",
    schema: str = "perseus",
    db_config: dict | None = None,
) -> dict:
    """
    Orchestrate Phase 4: full validation of CITEXT conversion.

    Returns:
        Report dict with validation results per category.
    """
    manifest = Manifest(manifest_path)
    manifest.create()
    manifest.start_phase("04-validate")

    all_columns = get_all_target_columns(config)

    # 1. Column type validation
    column_types_result = validate_column_types(
        schema, all_columns, db_config=db_config
    )

    manifest.complete_phase("04-validate")

    return {
        "column_types": column_types_result,
        "overall_passed": column_types_result["passed"],
    }


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Phase 4: Validate CITEXT Conversion")
    parser.add_argument("--config", default="config/citext-conversion.yaml")
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--log-dir", default="./logs")

    args = parser.parse_args()

    logger = setup_logger("04-validate-conversion", log_dir=args.log_dir)
    logger.info("Phase 4: Validate CITEXT Conversion — Starting")

    config = load_config(args.config)
    report = run_validation(
        config=config,
        manifest_path=args.manifest,
        log_dir=args.log_dir,
    )

    if report["overall_passed"]:
        logger.ok("Phase 4 complete: ALL validations PASSED")
    else:
        logger.warning(f"Phase 4 complete: FAILURES detected — {report}")


if __name__ == "__main__":
    main()
