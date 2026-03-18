"""
TDD tests for 04-validate-conversion.py — Phase 4: Validation.

RED phase: These tests are written BEFORE the implementation.
"""

from unittest.mock import patch, MagicMock


class TestValidateColumnTypes:
    """Test column type validation."""

    def test_validates_column_types(self, mock_db_connection, mock_psql):
        """Checks all columns are citext."""
        # Simulate psql returning 'citext' for all queried columns
        mock_psql.stdout = "citext\n"
        from validate_conversion import validate_column_types

        columns = [
            {"table": "color", "column": "name"},
            {"table": "unit", "column": "description"},
        ]
        result = validate_column_types("perseus", columns, db_config=None)
        assert result["passed"] is True
        assert result["total"] == 2
        assert result["failures"] == []

    def test_validates_column_types_detects_failure(
        self, mock_db_connection, mock_psql
    ):
        """Detects columns NOT converted to citext."""
        mock_psql.stdout = "character varying\n"
        from validate_conversion import validate_column_types

        columns = [{"table": "color", "column": "name"}]
        result = validate_column_types("perseus", columns, db_config=None)
        assert result["passed"] is False
        assert len(result["failures"]) == 1


class TestValidateFkConstraints:
    """Test FK constraint validation."""

    def test_validates_fk_constraints_exist(self, mock_db_connection, mock_psql):
        """Checks FK constraints exist in pg_constraint."""
        # Return constraint names as psql output
        mock_psql.stdout = "fk_material_transition_material_id\nfk_material_transition_transition_id\nfk_transition_material_material_id\nfk_transition_material_transition_id\n"
        from validate_conversion import validate_fk_constraints

        expected = [
            "fk_material_transition_material_id",
            "fk_material_transition_transition_id",
            "fk_transition_material_material_id",
            "fk_transition_material_transition_id",
        ]
        result = validate_fk_constraints("perseus", expected, db_config=None)
        assert result["passed"] is True
        assert result["found"] == 4


class TestValidateViews:
    """Test view queryability validation."""

    def test_validates_views_queryable(self, mock_db_connection, mock_psql):
        """Checks views are queryable with SELECT 1 FROM view LIMIT 0."""
        mock_psql.stdout = ""
        mock_psql.returncode = 0
        from validate_conversion import validate_views_queryable

        views = ["upstream", "downstream", "vw_recipe_prep_part"]
        result = validate_views_queryable("perseus", views, db_config=None)
        assert result["passed"] is True
        assert result["queryable"] == 3


class TestValidateCaseInsensitive:
    """Test case-insensitive behavior validation."""

    def test_validates_case_insensitive_behavior(self, mock_db_connection, mock_psql):
        """WHERE col = 'ABC' matches 'abc' with citext."""
        # Simulate psql returning a count > 0 (match found)
        mock_psql.stdout = "1\n"
        from validate_conversion import validate_case_insensitive

        result = validate_case_insensitive("perseus", "color", "name", db_config=None)
        assert result["passed"] is True


class TestValidationOrchestration:
    """Test the full Phase 4 orchestration."""

    def test_run_validation_returns_report(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        """Full validation returns pass/fail report."""
        mock_psql.stdout = "citext\n"
        from validate_conversion import run_validation

        result = run_validation(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        assert "column_types" in result
        assert "overall_passed" in result
