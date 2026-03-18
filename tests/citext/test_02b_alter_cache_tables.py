"""
TDD tests for 02b-alter-cache-tables.py — Phase 2b: ALTER Cache Tables.

RED phase: These tests are written BEFORE the implementation.
"""

from unittest.mock import patch, call


class TestAlterCacheTablesOrder:
    """Test cache tables are altered in the correct order."""

    def test_alters_dirty_leaves_first(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        """m_upstream_dirty_leaves (0 rows) goes first."""
        mock_psql.stdout = ""
        from alter_cache_tables import run_alter_cache_tables

        result = run_alter_cache_tables(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        tables = result["tables_processed"]
        assert "m_upstream_dirty_leaves" in tables
        assert tables.index("m_upstream_dirty_leaves") == 0

    def test_alters_downstream_second(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        """m_downstream after dirty_leaves."""
        mock_psql.stdout = ""
        from alter_cache_tables import run_alter_cache_tables

        result = run_alter_cache_tables(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        tables = result["tables_processed"]
        assert "m_downstream" in tables
        assert tables.index("m_downstream") == 1

    def test_alters_upstream_last(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        """m_upstream is the absolute last."""
        mock_psql.stdout = ""
        from alter_cache_tables import run_alter_cache_tables

        result = run_alter_cache_tables(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        tables = result["tables_processed"]
        assert "m_upstream" in tables
        assert tables.index("m_upstream") == len(tables) - 1


class TestAlterCacheTablesMethod:
    """Test that Direct ALTER is used (no TRUNCATE)."""

    def test_uses_direct_alter_no_truncate(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        """Verify no TRUNCATE in SQL — only ALTER TABLE ... TYPE citext."""
        mock_psql.stdout = ""
        from alter_cache_tables import run_alter_cache_tables

        result = run_alter_cache_tables(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        # Check all executed SQL statements
        executed_sqls = result.get("executed_sqls", [])
        for sql in executed_sqls:
            assert "TRUNCATE" not in sql.upper()
            assert "ALTER TABLE" in sql


class TestAlterCacheTablesOrchestration:
    """Test the full Phase 2b orchestration."""

    def test_run_alter_cache_tables_orchestration(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        """Full orchestration returns report."""
        mock_psql.stdout = ""
        from alter_cache_tables import run_alter_cache_tables

        result = run_alter_cache_tables(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        assert "columns_converted" in result
        assert "tables_processed" in result
        assert result["columns_converted"] == 7  # 1 + 3 + 3
        assert len(result["tables_processed"]) == 3
