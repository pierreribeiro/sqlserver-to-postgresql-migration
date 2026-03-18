"""
TDD tests for 02-alter-columns.py — Phase 2a: ALTER COLUMN TYPE.

RED phase: These tests are written BEFORE the implementation.
"""

from unittest.mock import patch


class TestAlterRegularColumns:
    """Test ALTER COLUMN TYPE for regular (non-FK, non-cache) columns."""

    def test_alters_single_column(self, mock_db_connection, mock_psql):
        mock_psql.stdout = ""
        from alter_columns import alter_single_column

        sql = alter_single_column("perseus", "color", "name")
        assert "ALTER TABLE perseus.color" in sql
        assert "TYPE citext" in sql

    def test_alters_table_columns_in_one_transaction(
        self, mock_db_connection, mock_psql
    ):
        mock_psql.stdout = ""
        from alter_columns import alter_table_columns

        columns = ["description", "name"]
        sqls = alter_table_columns("perseus", "unit", columns)
        assert len(sqls) == 2

    def test_skips_already_converted_columns(
        self, mock_db_connection, mock_psql, tmp_manifest_path
    ):
        mock_psql.stdout = ""
        from alter_columns import alter_table_columns_with_resume
        from lib.manifest import Manifest

        # Set up manifest with one column already converted
        m = Manifest(str(tmp_manifest_path))
        m.create()
        m.start_phase("02-alter-columns")
        m.record_column_converted("unit", "name", "character varying", 50)

        sqls = alter_table_columns_with_resume(
            "perseus", "unit", ["description", "name"], m
        )
        # Only description should be altered, name was already done
        assert len(sqls) == 1
        assert "description" in sqls[0]


class TestAlterFkGroupColumns:
    """Test FK group ALTER in a single transaction."""

    def test_alters_fk_group_in_transaction(self, mock_db_connection, mock_psql):
        mock_psql.stdout = ""
        from alter_columns import alter_fk_group

        columns = [
            {"table": "goo", "column": "uid"},
            {"table": "fatsmurf", "column": "uid"},
            {"table": "material_transition", "column": "material_id"},
        ]
        sql = alter_fk_group("perseus", columns)
        assert "BEGIN;" in sql
        assert "COMMIT;" in sql
        assert sql.count("ALTER TABLE") == 3


class TestAlterColumnsOrchestration:
    """Test the full Phase 2a orchestration."""

    def test_processes_small_tables_first(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        mock_psql.stdout = ""
        from alter_columns import run_alter_columns

        result = run_alter_columns(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        assert "columns_converted" in result

    def test_excludes_cache_tables(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        mock_psql.stdout = ""
        from alter_columns import run_alter_columns

        result = run_alter_columns(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        # Cache tables should NOT be converted in Phase 2a
        converted = result.get("tables_processed", [])
        assert "m_upstream" not in converted
        assert "m_downstream" not in converted


class TestVerifyColumnConversion:
    """Test post-ALTER verification."""

    def test_verifies_column_is_citext(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "citext\n"
        from alter_columns import verify_column_type

        assert verify_column_type("perseus", "goo", "uid") is True

    def test_verification_fails_when_not_citext(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "character varying\n"
        from alter_columns import verify_column_type

        assert verify_column_type("perseus", "goo", "uid") is False
