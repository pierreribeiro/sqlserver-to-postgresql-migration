"""
Phase 3: Recreate Dependent Objects — Bottom-Up (depth-ordered).

Reads DDL from backup table (primary) or manifest (fallback).
Recreate order: Indexes -> FK Constraints -> Views/MVs (depth ASC, root first).

Usage:
    python 03-recreate-dependents.py [--config PATH] [--manifest PATH]
"""

import argparse
import logging
import os
import re
from pathlib import Path

from lib.backup import get_snapshot, mark_recreated
from lib.db import execute_sql, execute_sql_safe
from lib.logger import setup_logger
from lib.manifest import Manifest

logger = logging.getLogger("citext.recreate-dependents")


def _make_idempotent_index(ddl: str) -> str:
    """Ensure CREATE INDEX uses IF NOT EXISTS for idempotency."""
    if "IF NOT EXISTS" in ddl:
        return ddl
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
    run_id: str | None = None,
) -> list[str]:
    """Recreate indexes from saved DDL."""
    sqls = []
    for idx in indexes:
        sql = _make_idempotent_index(idx["ddl"])
        success, _, error = execute_sql_safe(
            sql,
            config=db_config,
            run_id=run_id,
            phase="03-recreate-dependents",
            context={
                "object_type": "index",
                "object_name": idx.get("object_name", idx.get("index_name", "")),
                "operation": "CREATE",
            },
        )
        if success:
            sqls.append(sql)
        else:
            logger.error(
                f"Index recreate failed for "
                f"{idx.get('object_name', idx.get('index_name', ''))}: {error}"
            )
    return sqls


def recreate_fk_constraints(
    schema: str,
    constraints: list[dict],
    db_config: dict | None = None,
    run_id: str | None = None,
) -> list[str]:
    """Recreate FK constraints from saved CREATE DDL."""
    sqls = []
    for c in constraints:
        sql = c["ddl"]
        try:
            execute_sql(sql, config=db_config)
            sqls.append(sql)
        except RuntimeError as e:
            if "already exists" in str(e).lower():
                logger.warning(f"Constraint already exists — skipping: {e}")
            else:
                logger.error(
                    f"Constraint recreate failed for "
                    f"{c.get('object_name', '')}: {e}"
                )
                if run_id:
                    from lib.error_log import log_error

                    log_error(
                        run_id,
                        "03-recreate-dependents",
                        "ERROR",
                        str(e),
                        schema_name=schema,
                        object_type="constraint",
                        object_name=c.get("object_name", ""),
                        operation="CREATE",
                        sql_attempted=sql,
                        db_config=db_config,
                    )
    return sqls


def recreate_views(
    schema: str,
    waves: dict[int, list[dict]],
    db_config: dict | None = None,
    run_id: str | None = None,
) -> list[str]:
    """Recreate views in wave/depth order (lowest first — bottom-up)."""
    sqls = []
    for wave_num in sorted(waves.keys()):
        for view in waves[wave_num]:
            sql = _make_idempotent_view(view["ddl"])
            success, _, error = execute_sql_safe(
                sql,
                config=db_config,
                run_id=run_id,
                phase="03-recreate-dependents",
                context={
                    "schema_name": schema,
                    "object_type": "view",
                    "object_name": view.get("object_name", view.get("name", "")),
                    "operation": "CREATE",
                },
            )
            if success:
                sqls.append(sql)
            else:
                logger.error(
                    f"View recreate failed for "
                    f"{view.get('object_name', view.get('name', ''))}: {error}"
                )
    return sqls


def recreate_materialized_views(
    schema: str,
    mv_list: list[dict],
    db_config: dict | None = None,
    run_id: str | None = None,
) -> list[str]:
    """Recreate materialized views from saved DDL."""
    sqls = []
    for mv in mv_list:
        sql = mv["ddl"]
        success, _, error = execute_sql_safe(
            sql,
            config=db_config,
            run_id=run_id,
            phase="03-recreate-dependents",
            context={
                "schema_name": schema,
                "object_type": "materialized_view",
                "object_name": mv.get("object_name", mv.get("name", "")),
                "operation": "CREATE",
            },
        )
        if success:
            sqls.append(sql)
        else:
            logger.error(
                f"MV recreate failed for "
                f"{mv.get('object_name', mv.get('name', ''))}: {error}"
            )
    return sqls


def _load_dependents_from_backup(
    run_id: str,
    db_config: dict | None = None,
) -> dict:
    """Load dependents from backup table, organized by type and depth."""
    phase = "01-drop-dependents"
    objects = get_snapshot(run_id, phase, db_config)

    dependents = {
        "indexes": [],
        "constraints": [],
        "materialized_views": [],
        "views": {},  # depth -> [objects]
    }

    for obj in objects:
        otype = obj["object_type"]
        if otype == "index":
            dependents["indexes"].append(obj)
        elif otype == "constraint":
            dependents["constraints"].append(obj)
        elif otype == "materialized_view":
            dependents["materialized_views"].append(obj)
        elif otype == "view":
            depth = obj.get("depth", 0)
            dependents["views"].setdefault(depth, []).append(obj)

    return dependents


def _load_dependents_from_manifest(manifest: Manifest) -> dict:
    """Fallback: load dependents from manifest (Phase 1 saved them)."""
    drop_phase = manifest.data.get("phases", {}).get("01-drop-dependents", {})
    dropped = drop_phase.get("dropped", [])
    return {
        "indexes": [d for d in dropped if d["type"] == "index"],
        "constraints": [d for d in dropped if d["type"] == "constraint"],
        "materialized_views": [d for d in dropped if d["type"] == "materialized_view"],
        "views": {0: [d for d in dropped if d["type"] == "view"]},
    }


def run_recreate_dependents(
    config: dict | None = None,
    manifest_path: str = "./manifest.json",
    log_dir: str = "./logs",
    schema: str = "perseus",
    db_config: dict | None = None,
    run_id: str | None = None,
) -> dict:
    """
    Orchestrate Phase 3: recreate all dependent objects.

    Primary source: backup table (depth-ordered).
    Fallback: manifest (if backup table unavailable).

    Order: Indexes -> FK Constraints -> MVs -> Views (depth ASC).
    """
    manifest = Manifest(manifest_path)
    if Path(manifest_path).exists():
        manifest.load()
    else:
        manifest.create()
    manifest.start_phase("03-recreate-dependents")

    # Try to load run_id from manifest for backup table lookup
    backup_run_id = run_id or (
        manifest.data.get("snapshots", {}).get("01-drop-dependents", {}).get("run_id")
    )

    dependents = None
    if backup_run_id:
        try:
            dependents = _load_dependents_from_backup(backup_run_id, db_config)
            has_objects = any(
                dependents[k]
                for k in ("indexes", "constraints", "materialized_views", "views")
            )
            if has_objects:
                logger.info(
                    f"Loaded dependents from backup table (run_id={backup_run_id})"
                )
            else:
                dependents = None
        except RuntimeError:
            logger.warning("Backup table unavailable — falling back to manifest")
            dependents = None

    if dependents is None:
        dependents = _load_dependents_from_manifest(manifest)
        logger.info("Loaded dependents from manifest (fallback)")

    report = {
        "indexes_created": 0,
        "constraints_created": 0,
        "mv_created": 0,
        "views_created": 0,
        "errors_count": 0,
    }

    # 1. Indexes first
    indexes = dependents.get("indexes", [])
    if indexes:
        sqls = recreate_indexes(indexes, db_config=db_config, run_id=run_id)
        report["indexes_created"] = len(sqls)
        report["errors_count"] += len(indexes) - len(sqls)
        if backup_run_id:
            for idx in indexes:
                mark_recreated(
                    backup_run_id,
                    schema,
                    idx.get("object_name", idx.get("name", "")),
                    db_config,
                )

    # 2. FK Constraints (now using CREATE DDL from Bug 9 fix)
    constraints = dependents.get("constraints", [])
    if constraints:
        sqls = recreate_fk_constraints(
            schema, constraints, db_config=db_config, run_id=run_id
        )
        report["constraints_created"] = len(sqls)
        if backup_run_id:
            for c in constraints:
                mark_recreated(
                    backup_run_id,
                    schema,
                    c.get("object_name", c.get("name", "")),
                    db_config,
                )

    # 3. Materialized Views (before regular views since views may depend on MVs)
    mv_list = dependents.get("materialized_views", [])
    if mv_list:
        sqls = recreate_materialized_views(
            schema, mv_list, db_config=db_config, run_id=run_id
        )
        report["mv_created"] = len(sqls)
        report["errors_count"] += len(mv_list) - len(sqls)
        if backup_run_id:
            for mv in mv_list:
                mark_recreated(
                    backup_run_id,
                    schema,
                    mv.get("object_name", mv.get("name", "")),
                    db_config,
                )

    # 4. Views (depth ASC — root/base views first, then dependents)
    views = dependents.get("views", {})
    if views:
        total_views = sum(len(v) for v in views.values())
        sqls = recreate_views(schema, views, db_config=db_config, run_id=run_id)
        report["views_created"] = len(sqls)
        report["errors_count"] += total_views - len(sqls)
        if backup_run_id:
            for depth_views in views.values():
                for v in depth_views:
                    mark_recreated(
                        backup_run_id,
                        schema,
                        v.get("object_name", v.get("name", "")),
                        db_config,
                    )

    manifest.complete_phase("03-recreate-dependents")

    return report


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Phase 3: Recreate Dependent Objects")
    parser.add_argument("--config", default="config/citext-conversion.yaml")
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--log-dir", default=os.environ.get("LOG_DIR", "./logs"))

    args = parser.parse_args()

    setup_logger("03-recreate-dependents", log_dir=args.log_dir)

    report = run_recreate_dependents(
        manifest_path=args.manifest,
        log_dir=args.log_dir,
    )

    logger.info(f"Phase 3 complete: {report}")


if __name__ == "__main__":
    main()
