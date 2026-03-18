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


def classify_table_size(config: dict, table_name: str) -> str:
    """Classify a table as 'large' or 'small' based on large_tables_order."""
    large_tables = {t["table"] for t in config.get("large_tables_order", [])}
    return "large" if table_name in large_tables else "small"
