"""
Phase 3: Recreate Dependent Objects — Bottom-Up.

Recreate order: Indexes -> FK Constraints -> MV (translated) -> Views (Wave 0 -> Wave 3).
Reverse of drop_dependents.py.

Usage:
    python 03-recreate-dependents.py [--config PATH] [--manifest PATH]
"""

import argparse
import os
import re
import sys

from lib.db import execute_sql
from lib.logger import setup_logger
from lib.manifest import Manifest


def _make_idempotent_index(ddl: str) -> str:
    """Ensure CREATE INDEX uses IF NOT EXISTS for idempotency."""
    if "IF NOT EXISTS" in ddl:
        return ddl
    # Handle CREATE INDEX and CREATE UNIQUE INDEX
    ddl = re.sub(
        r"CREATE\s+(UNIQUE\s+)?INDEX\s+",
        r"CREATE \1INDEX IF NOT EXISTS ",
        ddl,
        count=1,
        flags=re.IGNORECASE,
    )
    return ddl


def _make_idempotent_view(ddl: str) -> str:
    """Ensure CREATE VIEW uses CREATE OR REPLACE VIEW for idempotency."""
    if "CREATE OR REPLACE VIEW" in ddl.upper():
        return ddl
    ddl = re.sub(
        r"CREATE\s+VIEW\s+",
        "CREATE OR REPLACE VIEW ",
        ddl,
        count=1,
        flags=re.IGNORECASE,
    )
    return ddl


def recreate_indexes(
    indexes: list[dict],
    db_config: dict | None = None,
) -> list[str]:
    """
    Recreate indexes from saved DDL.

    Args:
        indexes: list of {schema, name, ddl} dicts
        db_config: optional DB config

    Returns:
        List of executed SQL statements
    """
    sqls = []
    for idx in indexes:
        sql = _make_idempotent_index(idx["ddl"])
        execute_sql(sql, config=db_config)
        sqls.append(sql)
    return sqls


def recreate_fk_constraints(
    schema: str,
    constraints: list[dict],
    db_config: dict | None = None,
) -> list[str]:
    """
    Recreate FK constraints from saved DDL.

    Args:
        schema: database schema
        constraints: list of {table, name, ddl} dicts
        db_config: optional DB config

    Returns:
        List of executed SQL statements
    """
    sqls = []
    for c in constraints:
        sql = c["ddl"]
        execute_sql(sql, config=db_config)
        sqls.append(sql)
    return sqls


def recreate_views(
    schema: str,
    waves: dict[int, list[dict]],
    db_config: dict | None = None,
) -> list[str]:
    """
    Recreate views in wave order (Wave 0 first, ascending — bottom-up).

    Args:
        schema: database schema
        waves: {wave_number: [{name, ddl}]} — lowest wave first
        db_config: optional DB config

    Returns:
        List of executed SQL statements
    """
    sqls = []
    for wave_num in sorted(waves.keys()):
        for view in waves[wave_num]:
            sql = _make_idempotent_view(view["ddl"])
            execute_sql(sql, config=db_config)
            sqls.append(sql)
    return sqls


def recreate_materialized_views(
    schema: str,
    mv_list: list[dict],
    db_config: dict | None = None,
) -> list[str]:
    """
    Recreate materialized views from saved DDL.

    Args:
        schema: database schema
        mv_list: list of {name, ddl} dicts
        db_config: optional DB config

    Returns:
        List of executed SQL statements
    """
    sqls = []
    for mv in mv_list:
        sql = mv["ddl"]
        execute_sql(sql, config=db_config)
        sqls.append(sql)
    return sqls


def run_recreate_dependents(
    dependents: dict,
    manifest_path: str,
    log_dir: str = "./logs",
    schema: str = "perseus",
    db_config: dict | None = None,
) -> dict:
    """
    Orchestrate Phase 3: recreate all dependent objects.

    Order: Indexes -> FK Constraints -> MV -> Views (Wave 0 -> Wave N).

    Args:
        dependents: dict with keys: indexes, constraints, materialized_views, views
        manifest_path: path to manifest for checkpointing
        log_dir: log directory
        schema: database schema
        db_config: optional DB config

    Returns:
        Report dict with counts of recreated objects.
    """
    manifest = Manifest(manifest_path)
    manifest.create()
    manifest.start_phase("03-recreate-dependents")

    report = {
        "indexes_created": 0,
        "constraints_created": 0,
        "mv_created": 0,
        "views_created": 0,
    }

    # 1. Indexes first
    indexes = dependents.get("indexes", [])
    if indexes:
        sqls = recreate_indexes(indexes, db_config=db_config)
        report["indexes_created"] = len(sqls)

    # 2. FK Constraints
    constraints = dependents.get("constraints", [])
    if constraints:
        sqls = recreate_fk_constraints(schema, constraints, db_config=db_config)
        report["constraints_created"] = len(sqls)

    # 3. Materialized Views
    mv_list = dependents.get("materialized_views", [])
    if mv_list:
        sqls = recreate_materialized_views(schema, mv_list, db_config=db_config)
        report["mv_created"] = len(sqls)

    # 4. Views (Wave 0 -> Wave N, bottom-up)
    views = dependents.get("views", {})
    if views:
        sqls = recreate_views(schema, views, db_config=db_config)
        report["views_created"] = len(sqls)

    manifest.complete_phase("03-recreate-dependents")

    return report


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Phase 3: Recreate Dependent Objects")
    parser.add_argument("--config", default="config/citext-conversion.yaml")
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--log-dir", default=os.environ.get("LOG_DIR", "./logs"))

    args = parser.parse_args()

    logger = setup_logger("03-recreate-dependents", log_dir=args.log_dir)
    logger.info("Phase 3: Recreate Dependent Objects — Starting")

    # In production, dependents would be loaded from the manifest
    # (objects recorded during Phase 1 drop)
    manifest = Manifest(args.manifest)
    manifest.load()
    drop_phase = manifest.data.get("phases", {}).get("01-drop-dependents", {})
    dropped = drop_phase.get("dropped", [])

    # Reconstruct dependents from manifest
    dependents = {
        "indexes": [d for d in dropped if d["type"] == "index"],
        "constraints": [d for d in dropped if d["type"] == "constraint"],
        "materialized_views": [d for d in dropped if d["type"] == "materialized_view"],
        "views": {},  # Would need wave info from config
    }

    report = run_recreate_dependents(
        dependents=dependents,
        manifest_path=args.manifest,
        log_dir=args.log_dir,
    )

    logger.ok(f"Phase 3 complete: {report}")


if __name__ == "__main__":
    main()
