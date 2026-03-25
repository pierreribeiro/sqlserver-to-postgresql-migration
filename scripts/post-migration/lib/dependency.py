"""
Configuration loader and dependency graph builder for CITEXT conversion.

Parses citext-conversion.yaml and provides functions to extract
column groups (FK, cache, regular, independent).
"""

from pathlib import Path

import yaml


def load_config(config_path: str) -> dict:
    """Load and return the citext-conversion.yaml config."""
    return yaml.safe_load(Path(config_path).read_text())


def get_all_target_columns(config: dict) -> list[dict]:
    """
    Extract all target columns from all groups (FK, cache, independent).
    Returns deduplicated list of {table, column} dicts.
    """
    seen = set()
    columns = []

    # FK groups
    for group in config.get("fk_groups", []):
        for col in group.get("columns", []):
            key = (col["table"], col["column"])
            if key not in seen:
                seen.add(key)
                columns.append(col)

    # Cache tables
    for table_group in config.get("cache_tables", {}).get("tables", []):
        for col in table_group.get("columns", []):
            key = (col["table"], col["column"])
            if key not in seen:
                seen.add(key)
                columns.append(col)

    # Independent columns
    for table_entry in config.get("independent_columns", []):
        table = table_entry["table"]
        for col_name in table_entry.get("columns", []):
            key = (table, col_name)
            if key not in seen:
                seen.add(key)
                columns.append({"table": table, "column": col_name})

    return columns


def get_fk_group_columns(config: dict, group_name: str) -> list[dict]:
    """Get columns for a specific FK group by name."""
    for group in config.get("fk_groups", []):
        if group["name"] == group_name:
            return group["columns"]
    return []


def get_cache_columns(config: dict) -> list[dict]:
    """Get all cache table columns."""
    columns = []
    for table_group in config.get("cache_tables", {}).get("tables", []):
        columns.extend(table_group.get("columns", []))
    return columns


def get_regular_columns(config: dict) -> list[dict]:
    """
    Get independent columns that are NOT in FK groups or cache tables.
    Filters out empty column lists.
    """
    columns = []
    for table_entry in config.get("independent_columns", []):
        table = table_entry["table"]
        col_names = table_entry.get("columns", [])
        for col_name in col_names:
            columns.append({"table": table, "column": col_name})
    return columns


def purge_phantom_columns(
    config_path: str,
    phantom_columns: list[dict],
    run_id: str | None = None,
    db_config: dict | None = None,
) -> int:
    """
    Remove phantom columns from YAML config, rewrite file.

    Handles both formats:
    - FK groups / cache tables: filter {table, column} dicts from lists
    - Independent columns: remove string entries from columns: [...] list

    If ANY column in an FK group is phantom, the ENTIRE group is removed (D3).

    Args:
        config_path: path to citext-conversion.yaml
        phantom_columns: list of {table, column} dicts to remove
        run_id: optional run_id for error logging
        db_config: optional DB config for error logging

    Returns:
        Count of removed column entries.
    """
    import logging
    import shutil
    from datetime import datetime

    log = logging.getLogger("citext.purge-phantoms")
    phantom_set = {(p["table"], p["column"]) for p in phantom_columns}
    if not phantom_set:
        return 0

    # Backup original file
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = f"{config_path}.bak.{timestamp}"
    try:
        shutil.copy2(config_path, backup_path)
        log.info(f"YAML backup: {backup_path}")
    except OSError as e:
        log.error(f"Could not backup YAML: {e} — skipping rewrite")
        return 0

    # Load YAML — try ruamel for comment-preserving, fallback to pyyaml
    try:
        from ruamel.yaml import YAML as RuamelYAML

        ryaml = RuamelYAML(typ="rt")
        with open(config_path) as f:
            data = ryaml.load(f)
        use_ruamel = True
    except ImportError:
        log.warning("ruamel.yaml not installed — using pyyaml (comments will be lost)")
        data = yaml.safe_load(Path(config_path).read_text())
        use_ruamel = False

    removed = 0

    # --- FK groups (D3): if ANY column in a group is phantom → remove ENTIRE group ---
    fk_groups = data.get("fk_groups", [])
    groups_to_remove = []
    for i, group in enumerate(fk_groups):
        cols = group.get("columns", [])
        group_phantoms = [c for c in cols if (c["table"], c["column"]) in phantom_set]
        if group_phantoms:
            group_name = group.get("name", f"group_{i}")
            log.critical(
                f"FATAL: FK group '{group_name}' has phantom columns "
                f"{[(c['table'], c['column']) for c in group_phantoms]} — "
                f"removing ENTIRE group ({len(cols)} columns)"
            )
            if run_id and db_config:
                from lib.error_log import log_error

                log_error(
                    run_id,
                    "00-preflight",
                    "FATAL",
                    f"FK group '{group_name}' removed: phantom columns in FK chain",
                    object_type="config",
                    object_name=group_name,
                    operation="PURGE_PHANTOM",
                    db_config=db_config,
                )
            removed += len(cols)
            groups_to_remove.append(i)

    for i in reversed(groups_to_remove):
        del fk_groups[i]

    # --- Cache tables: filter {table, column} dicts ---
    cache_tables = data.get("cache_tables", {}).get("tables", [])
    for table_group in cache_tables:
        cols = table_group.get("columns", [])
        original_len = len(cols)
        filtered = [c for c in cols if (c["table"], c["column"]) not in phantom_set]
        removed_count = original_len - len(filtered)
        if removed_count > 0:
            table_group["columns"] = filtered
            removed += removed_count

    # Remove empty cache table groups
    if cache_tables:
        data["cache_tables"]["tables"] = [g for g in cache_tables if g.get("columns")]

    # --- Independent columns (D4): columns: [str] format ---
    independent = data.get("independent_columns", [])
    entries_to_remove = []
    for i, entry in enumerate(independent):
        table = entry["table"]
        cols = entry.get("columns", [])
        original_len = len(cols)
        filtered = [c for c in cols if (table, c) not in phantom_set]
        removed_count = original_len - len(filtered)
        if removed_count > 0:
            entry["columns"] = filtered
            removed += removed_count
        # Mark empty entries for removal
        if not entry.get("columns"):
            entries_to_remove.append(i)

    for i in reversed(entries_to_remove):
        del independent[i]

    # Write back
    if use_ruamel:
        with open(config_path, "w") as f:
            ryaml.dump(data, f)
    else:
        with open(config_path, "w") as f:
            yaml.safe_dump(data, f, default_flow_style=False, sort_keys=False)

    log.info(f"Purged {removed} phantom column entries from YAML")
    return removed


def classify_table_size(config: dict, table_name: str) -> str:
    """Classify a table as 'large' or 'small' based on large_tables_order."""
    large_tables = {t["table"] for t in config.get("large_tables_order", [])}
    return "large" if table_name in large_tables else "small"
