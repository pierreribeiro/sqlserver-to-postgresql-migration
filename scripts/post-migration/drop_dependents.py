"""
Phase 1: Drop Dependent Objects — Two-Pass Architecture.

Pass 1 (Snapshot): Capture ALL DDL into backup table + manifest (zero mutations).
Pass 2 (Drop): Drop from snapshot, depth-ordered (deepest first, no CASCADE chains).

Usage:
    python 01-drop-dependents.py [--config PATH] [--dry-run]
"""

import argparse
import logging
import os
from pathlib import Path

from lib.backup import (
    ensure_backup_table,
    generate_run_id,
    get_latest_backup_for_object,
    get_snapshot,
    has_snapshot,
    mark_dropped,
    snapshot_object,
)
from lib.db import execute_sql, execute_sql_safe
from lib.dependency import get_all_target_columns
from lib.logger import setup_logger
from lib.manifest import Manifest
from lib.sql_templates import (
    drop_constraint_sql,
    drop_index_sql,
    drop_materialized_view_sql,
    drop_view_sql,
)
from preflight_check import (
    discover_all_dependent_views,
    discover_fk_constraints,
    discover_indexes,
)

logger = logging.getLogger("citext.drop-dependents")


def _get_view_ddl(
    schema: str, view_name: str, view_type: str, db_config: dict | None = None
) -> str:
    """Capture the CREATE DDL for a view/MV before dropping it."""
    result = execute_sql(
        f"SELECT pg_get_viewdef('{schema}.{view_name}'::regclass, true);",
        config=db_config,
    )
    body = result.strip()
    if view_type == "materialized_view":
        return f"CREATE MATERIALIZED VIEW {schema}.{view_name} AS\n{body}"
    return f"CREATE OR REPLACE VIEW {schema}.{view_name} AS\n{body}"


def _get_fk_create_ddl(
    schema: str, constraint_name: str, db_config: dict | None = None
) -> str | None:
    """Capture the CREATE DDL for an FK constraint via pg_get_constraintdef()."""
    sql = (
        f"SELECT format('ALTER TABLE %I.%I ADD CONSTRAINT %I %s;', "
        f"n.nspname, t.relname, c.conname, pg_get_constraintdef(c.oid)) "
        f"FROM pg_constraint c "
        f"JOIN pg_class t ON c.conrelid = t.oid "
        f"JOIN pg_namespace n ON t.relnamespace = n.oid "
        f"WHERE n.nspname = '{schema}' AND c.conname = '{constraint_name}';"
    )
    result = execute_sql(sql, config=db_config).strip()
    return result if result else None


def _snapshot_all_dependents(
    run_id: str,
    config: dict,
    manifest: Manifest,
    schema: str,
    db_config: dict | None = None,
) -> dict:
    """
    Pass 1: Snapshot all dependent DDL into backup table + manifest.

    Zero mutations — only reads from DB and writes to backup table.
    Returns counts of snapshotted objects.
    """
    phase = "01-drop-dependents"
    counts = {"views": 0, "mvs": 0, "indexes": 0, "constraints": 0}

    ensure_backup_table(db_config)

    # If snapshot already exists for this run_id, skip (resume support)
    if has_snapshot(run_id, phase, db_config):
        logger.info(f"Snapshot already exists for run_id={run_id} — skipping Pass 1")
        return counts

    # 1. Discover ALL dependent views/MVs recursively (with depth)
    all_columns = get_all_target_columns(config)
    target_tables = {col["table"] for col in all_columns}

    seen_views = {}  # name -> {name, type, depth}
    for table in sorted(target_tables):
        views = discover_all_dependent_views(schema, table, config=db_config)
        for v in views:
            # Keep the maximum depth for each view
            if (
                v["name"] not in seen_views
                or v["depth"] > seen_views[v["name"]]["depth"]
            ):
                seen_views[v["name"]] = v

    # 2. Capture DDL for each view/MV
    for name, v in seen_views.items():
        try:
            ddl = _get_view_ddl(schema, name, v["type"], db_config=db_config)
        except RuntimeError:
            # View already gone (prior failed run) — try fallback
            logger.warning(f"View {schema}.{name} already gone — trying prior backup")
            fallback = get_latest_backup_for_object(schema, name, db_config)
            if fallback:
                ddl = fallback["ddl"]
                logger.info(f"Using fallback DDL from run_id={fallback['run_id']}")
            else:
                logger.error(f"No DDL available for {schema}.{name} — skipping")
                continue

        obj_type = "materialized_view" if v["type"] == "materialized_view" else "view"
        snapshot_object(
            run_id, phase, obj_type, schema, name, v["depth"], ddl, db_config
        )
        # Also record in manifest as secondary backup
        manifest.record_dropped(obj_type, f"{schema}.{name}", ddl)
        if obj_type == "materialized_view":
            counts["mvs"] += 1
        else:
            counts["views"] += 1

    # 3. Discover and snapshot indexes on target columns
    seen_indexes = {}  # index_name -> {ddl}
    for col in all_columns:
        indexes = discover_indexes(
            schema, col["table"], col["column"], config=db_config
        )
        for idx in indexes:
            idx_name = idx["index_name"]
            if idx_name not in seen_indexes:
                seen_indexes[idx_name] = idx
                snapshot_object(
                    run_id, phase, "index", schema, idx_name, 0, idx["ddl"], db_config
                )
                manifest.record_dropped("index", f"{schema}.{idx_name}", idx["ddl"])
                counts["indexes"] += 1

    # 4. Capture FK constraint CREATE DDL (Bug 9 fix: real names + CREATE DDL)
    seen_constraints = set()
    for group in config.get("fk_groups", []):
        for col in group.get("columns", []):
            # Discover ACTUAL constraints on this column (not guessed names)
            fk_info = discover_fk_constraints(schema, col["table"], config=db_config)
            for fk in fk_info:
                cname = fk["constraint_name"]
                if cname in seen_constraints:
                    continue
                seen_constraints.add(cname)

                try:
                    create_ddl = _get_fk_create_ddl(schema, cname, db_config)
                except RuntimeError as e:
                    logger.warning(f"Could not capture DDL for constraint {cname}: {e}")
                    if run_id:
                        from lib.error_log import log_error

                        log_error(
                            run_id,
                            phase,
                            "WARNING",
                            f"FK DDL capture failed for {cname}: {e}",
                            schema_name=schema,
                            object_type="constraint",
                            object_name=cname,
                            operation="SNAPSHOT",
                            db_config=db_config,
                        )
                    continue

                if not create_ddl:
                    logger.warning(
                        f"Could not capture DDL for constraint {cname} — skipping"
                    )
                    continue

                snapshot_object(
                    run_id, phase, "constraint", schema, cname, 0, create_ddl, db_config
                )
                manifest.record_dropped(
                    "constraint",
                    f"{schema}.{col['table']}.{cname}",
                    create_ddl,
                )
                counts["constraints"] += 1

    # Save snapshot info to manifest for cross-run access
    if "snapshots" not in manifest.data:
        manifest.data["snapshots"] = {}
    manifest.data["snapshots"]["01-drop-dependents"] = {
        "run_id": run_id,
        "counts": counts,
    }
    manifest._save()

    return counts


def _drop_from_snapshot(
    run_id: str,
    schema: str,
    db_config: dict | None = None,
) -> dict:
    """
    Pass 2: Drop objects using snapshot data, depth-ordered (deepest first).

    Reads from backup table, NOT live DB queries. This avoids CASCADE chains.
    """
    phase = "01-drop-dependents"
    report = {
        "views_dropped": 0,
        "mv_dropped": 0,
        "constraints_dropped": 0,
        "indexes_dropped": 0,
    }

    objects = get_snapshot(run_id, phase, db_config)
    if not objects:
        logger.warning("No snapshot objects found — nothing to drop")
        return report

    # Sort by depth DESC for views/MVs (deepest first avoids CASCADE chains)
    views_mvs = [
        o for o in objects if o["object_type"] in ("view", "materialized_view")
    ]
    views_mvs.sort(key=lambda x: x["depth"], reverse=True)

    indexes = [o for o in objects if o["object_type"] == "index"]
    constraints = [o for o in objects if o["object_type"] == "constraint"]

    # Drop views/MVs in depth order (deepest first)
    for obj in views_mvs:
        if obj["status"] == "dropped":
            continue
        name = obj["object_name"]
        try:
            if obj["object_type"] == "materialized_view":
                sql = drop_materialized_view_sql(schema, name)
            else:
                sql = drop_view_sql(schema, name)
            execute_sql(sql, config=db_config)
            mark_dropped(run_id, schema, name, db_config)
            if obj["object_type"] == "materialized_view":
                report["mv_dropped"] += 1
            else:
                report["views_dropped"] += 1
        except RuntimeError as e:
            # Already gone from prior run or CASCADE
            logger.warning(f"View {schema}.{name} already absent: {e}")
            mark_dropped(run_id, schema, name, db_config, note="already absent")

    # Drop indexes
    for obj in indexes:
        if obj["status"] == "dropped":
            continue
        name = obj["object_name"]
        try:
            sql = drop_index_sql(schema, name)
            execute_sql(sql, config=db_config)
            mark_dropped(run_id, schema, name, db_config)
            report["indexes_dropped"] += 1
        except RuntimeError as e:
            logger.warning(f"Index {schema}.{name} already absent: {e}")
            mark_dropped(run_id, schema, name, db_config, note="already absent")

    # Drop FK constraints
    for obj in constraints:
        if obj["status"] == "dropped":
            continue
        cname = obj["object_name"]
        # Extract table name from constraint for DROP statement
        table_sql = (
            f"SELECT t.relname FROM pg_constraint c "
            f"JOIN pg_class t ON c.conrelid = t.oid "
            f"JOIN pg_namespace n ON t.relnamespace = n.oid "
            f"WHERE n.nspname = '{schema}' AND c.conname = '{cname}';"
        )
        try:
            table_name = execute_sql(table_sql, config=db_config).strip()
            if table_name:
                sql = drop_constraint_sql(schema, table_name, cname)
                execute_sql(sql, config=db_config)
            mark_dropped(run_id, schema, cname, db_config)
            report["constraints_dropped"] += 1
        except RuntimeError:
            mark_dropped(run_id, schema, cname, db_config, note="already absent")
            report["constraints_dropped"] += 1

    return report


def run_drop_dependents(
    config: dict,
    manifest_path: str,
    log_dir: str = "./logs",
    schema: str = "perseus",
    db_config: dict | None = None,
    run_id: str | None = None,
) -> dict:
    """
    Orchestrate Phase 1: Two-pass drop of all dependent objects.

    Pass 1: Snapshot all DDL (zero mutations).
    Pass 2: Drop from snapshot (depth-ordered, no CASCADE chains).

    Returns report dict with counts of dropped objects.
    """
    manifest = Manifest(manifest_path)
    if Path(manifest_path).exists():
        manifest.load()
    else:
        manifest.create()
    manifest.start_phase("01-drop-dependents")

    # Load or generate run_id (persistent across restarts)
    if not run_id:
        run_id = (
            manifest.data.get("snapshots", {})
            .get("01-drop-dependents", {})
            .get("run_id")
        )
    if not run_id:
        run_id = generate_run_id()

    logger.info(f"Phase 1: run_id={run_id}")

    # Pass 1: Snapshot (zero mutations)
    snap_counts = _snapshot_all_dependents(run_id, config, manifest, schema, db_config)
    logger.info(f"Pass 1 (snapshot): {snap_counts}")

    # Pass 2: Drop from snapshot
    report = _drop_from_snapshot(run_id, schema, db_config)
    logger.info(f"Pass 2 (drop): {report}")

    manifest.complete_phase("01-drop-dependents")
    return report


# --- Legacy helpers kept for backward compatibility ---


def drop_single_view(schema: str, view_name: str) -> str:
    """Generate and return DROP VIEW SQL. Does NOT execute."""
    return drop_view_sql(schema, view_name)


def drop_materialized_view(schema: str, view_name: str) -> str:
    """Generate and return DROP MATERIALIZED VIEW SQL. Does NOT execute."""
    return drop_materialized_view_sql(schema, view_name)


def drop_views(
    schema: str,
    waves: dict[int, list[str]],
    manifest_path: str,
    db_config: dict | None = None,
) -> int:
    """Drop views in wave order (highest wave first)."""
    count = 0
    for wave_num in sorted(waves.keys(), reverse=True):
        for view_name in waves[wave_num]:
            sql = drop_view_sql(schema, view_name)
            execute_sql(sql, config=db_config)
            count += 1
    return count


def drop_fk_constraints(
    schema: str,
    constraints: list[dict],
    db_config: dict | None = None,
) -> list[str]:
    """Drop FK constraints."""
    sqls = []
    for c in constraints:
        sql = drop_constraint_sql(schema, c["table"], c["name"])
        execute_sql(sql, config=db_config)
        sqls.append(sql)
    return sqls


def drop_indexes(
    indexes: list[dict],
    db_config: dict | None = None,
) -> list[str]:
    """Drop indexes."""
    sqls = []
    for idx in indexes:
        sql = drop_index_sql(idx["schema"], idx["name"])
        execute_sql(sql, config=db_config)
        sqls.append(sql)
    return sqls


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Phase 1: Drop Dependent Objects")
    parser.add_argument(
        "--config",
        default="config/citext-conversion.yaml",
        help="Path to citext-conversion.yaml",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--log-dir", default=os.environ.get("LOG_DIR", "./logs"))

    args = parser.parse_args()

    from lib.dependency import load_config

    setup_logger("01-drop-dependents", log_dir=args.log_dir)

    config = load_config(args.config)
    report = run_drop_dependents(
        config=config,
        manifest_path=args.manifest,
        log_dir=args.log_dir,
    )

    logger.info(f"Phase 1 complete: {report}")


if __name__ == "__main__":
    main()
