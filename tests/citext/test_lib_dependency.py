"""
TDD tests for lib/dependency.py — pg_catalog dependency graph builder.

RED phase: These tests are written BEFORE the implementation.
"""

import yaml


class TestLoadConfig:
    """Test loading and parsing citext-conversion.yaml."""

    def test_loads_yaml_config(self, config_file):
        from lib.dependency import load_config

        config = load_config(str(config_file))
        assert config["version"] == 1
        assert config["schema"] == "perseus"

    def test_extracts_fk_groups(self, config_file):
        from lib.dependency import load_config

        config = load_config(str(config_file))
        fk_groups = config["fk_groups"]
        assert len(fk_groups) == 1
        assert fk_groups[0]["name"] == "material_lineage"
        assert len(fk_groups[0]["columns"]) == 6

    def test_extracts_cache_tables(self, config_file):
        from lib.dependency import load_config

        config = load_config(str(config_file))
        cache = config["cache_tables"]["tables"]
        assert len(cache) == 3  # dirty_leaves, downstream, upstream

    def test_extracts_independent_columns(self, config_file):
        from lib.dependency import load_config

        config = load_config(str(config_file))
        indep = config["independent_columns"]
        assert any(t["table"] == "color" for t in indep)


class TestGetAllTargetColumns:
    """Test extracting all target columns from config."""

    def test_returns_all_columns_from_all_groups(self, sample_config):
        from lib.dependency import get_all_target_columns

        columns = get_all_target_columns(sample_config)
        # FK group: 6 columns + cache: 7 columns + independent: 6 columns = 19
        table_col_pairs = [(c["table"], c["column"]) for c in columns]
        assert ("goo", "uid") in table_col_pairs
        assert ("m_upstream", "start_point") in table_col_pairs
        assert ("color", "name") in table_col_pairs

    def test_no_duplicates(self, sample_config):
        from lib.dependency import get_all_target_columns

        columns = get_all_target_columns(sample_config)
        pairs = [(c["table"], c["column"]) for c in columns]
        assert len(pairs) == len(set(pairs))


class TestGetFkGroupColumns:
    """Test extracting FK group columns."""

    def test_returns_material_lineage_columns(self, sample_config):
        from lib.dependency import get_fk_group_columns

        columns = get_fk_group_columns(sample_config, "material_lineage")
        assert len(columns) == 6
        tables = {c["table"] for c in columns}
        assert tables == {
            "goo",
            "fatsmurf",
            "material_transition",
            "transition_material",
        }

    def test_unknown_group_returns_empty(self, sample_config):
        from lib.dependency import get_fk_group_columns

        columns = get_fk_group_columns(sample_config, "nonexistent")
        assert columns == []


class TestGetCacheColumns:
    """Test extracting cache table columns."""

    def test_returns_all_cache_columns(self, sample_config):
        from lib.dependency import get_cache_columns

        columns = get_cache_columns(sample_config)
        tables = {c["table"] for c in columns}
        assert "m_upstream" in tables
        assert "m_downstream" in tables
        assert "m_upstream_dirty_leaves" in tables

    def test_cache_columns_count(self, sample_config):
        from lib.dependency import get_cache_columns

        columns = get_cache_columns(sample_config)
        assert len(columns) == 7  # 1 + 3 + 3


class TestGetRegularColumns:
    """Test extracting regular (non-FK, non-cache) columns."""

    def test_excludes_fk_and_cache_columns(self, sample_config):
        from lib.dependency import get_regular_columns

        columns = get_regular_columns(sample_config)
        tables = {c["table"] for c in columns}
        assert "m_upstream" not in tables
        assert "m_downstream" not in tables
        # goo has independent columns (catalog_label, description, name)
        # but uid is in FK group — should NOT appear here
        goo_cols = [c["column"] for c in columns if c["table"] == "goo"]
        assert "uid" not in goo_cols
        assert "catalog_label" in goo_cols


class TestClassifyTableSize:
    """Test table size classification."""

    def test_classifies_large_table(self, sample_config):
        from lib.dependency import classify_table_size

        size = classify_table_size(sample_config, "goo")
        assert size == "large"

    def test_classifies_small_table(self, sample_config):
        from lib.dependency import classify_table_size

        size = classify_table_size(sample_config, "color")
        assert size == "small"

    def test_classifies_unknown_table_as_small(self, sample_config):
        from lib.dependency import classify_table_size

        size = classify_table_size(sample_config, "unknown_table")
        assert size == "small"
