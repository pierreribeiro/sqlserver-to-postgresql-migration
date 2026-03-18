"""
TDD tests for 00-preflight-check.py — Phase 0: Pre-flight Analysis.

RED phase: These tests are written BEFORE the implementation.
"""

import json
from pathlib import Path
from unittest.mock import MagicMock, patch, call


class TestCheckCitextExtension:
    """Test citext extension verification."""

    def test_returns_true_when_extension_exists(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "citext\n"
        from preflight_check import check_citext_extension

        assert check_citext_extension() is True

    def test_returns_false_when_extension_missing(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "\n"
        from preflight_check import check_citext_extension

        assert check_citext_extension() is False


class TestCheckPermissions:
    """Test database permissions verification."""

    def test_returns_true_for_superuser(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "t\n"
        from preflight_check import check_permissions

        assert check_permissions() is True

    def test_returns_false_for_no_permissions(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "f\n"
        from preflight_check import check_permissions

        assert check_permissions() is False


class TestCheckCaseVariantDuplicates:
    """Test case-variant duplicate detection on UNIQUE columns."""

    def test_returns_empty_when_no_duplicates(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "\n"
        from preflight_check import check_case_variant_duplicates

        dupes = check_case_variant_duplicates("perseus", "goo", "uid")
        assert dupes == []

    def test_returns_duplicates_when_found(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "abc|2\ndef|3\n"
        from preflight_check import check_case_variant_duplicates

        dupes = check_case_variant_duplicates("perseus", "goo", "uid")
        assert len(dupes) == 2
        assert dupes[0]["value"] == "abc"
        assert dupes[0]["count"] == 2


class TestDiscoverDependencies:
    """Test dynamic dependency discovery via pg_catalog."""

    def test_discovers_fk_constraints(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "fk_material_transition_material_id|material_transition|material_id|goo|uid\n"
        from preflight_check import discover_fk_constraints

        fks = discover_fk_constraints("perseus", "goo")
        assert len(fks) >= 1
        assert fks[0]["constraint_name"] == "fk_material_transition_material_id"

    def test_discovers_indexes(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "ix_goo_uid|goo|CREATE UNIQUE INDEX ix_goo_uid ON ...\n"
        from preflight_check import discover_indexes

        indexes = discover_indexes("perseus", "goo", "uid")
        assert len(indexes) >= 1
        assert indexes[0]["index_name"] == "ix_goo_uid"

    def test_discovers_dependent_views(self, mock_db_connection, mock_psql):
        mock_psql.stdout = "upstream|v\ndownstream|v\ntranslated|m\n"
        from preflight_check import discover_dependent_views

        views = discover_dependent_views("perseus", "goo")
        assert len(views) >= 1


class TestGenerateManifest:
    """Test manifest generation from pre-flight analysis."""

    def test_generates_manifest_file(self, tmp_manifest_path, sample_config):
        from preflight_check import generate_manifest

        generate_manifest(
            config=sample_config,
            manifest_path=str(tmp_manifest_path),
            schema="perseus",
        )
        assert tmp_manifest_path.exists()
        data = json.loads(tmp_manifest_path.read_text())
        assert data["version"] == 1
        assert "phases" in data

    def test_manifest_records_original_column_types(
        self, tmp_manifest_path, sample_config, mock_db_connection, mock_psql
    ):
        # Simulate column type query results
        mock_psql.stdout = "character varying\n"
        from preflight_check import generate_manifest

        generate_manifest(
            config=sample_config,
            manifest_path=str(tmp_manifest_path),
            schema="perseus",
        )
        data = json.loads(tmp_manifest_path.read_text())
        assert "original_types" in data


class TestPreflightMain:
    """Test the main preflight orchestration."""

    def test_test_connection_mode(self, mock_db_connection, mock_psql, sample_env_vars):
        mock_psql.stdout = "1\n"
        with patch.dict("os.environ", sample_env_vars, clear=False):
            from preflight_check import run_preflight

            result = run_preflight(test_connection_only=True)
            assert result["connection"] is True

    def test_full_preflight_returns_report(
        self, mock_db_connection, mock_psql, sample_config, tmp_path, sample_env_vars
    ):
        mock_psql.stdout = "citext\n"
        with patch.dict("os.environ", sample_env_vars, clear=False):
            from preflight_check import run_preflight

            result = run_preflight(
                config=sample_config,
                manifest_path=str(tmp_path / "manifest.json"),
                log_dir=str(tmp_path / "logs"),
                test_connection_only=False,
            )
            assert "connection" in result
            assert "citext_extension" in result
