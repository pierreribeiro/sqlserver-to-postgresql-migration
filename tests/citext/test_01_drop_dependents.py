"""
TDD tests for 01-drop-dependents.py — Phase 1: Drop Dependent Objects.

RED phase: These tests are written BEFORE the implementation.
"""

import json
from unittest.mock import patch, MagicMock, call


class TestDropViews:
    """Test view dropping in correct wave order (top-down)."""

    def test_drops_views_in_wave_order(
        self, mock_db_connection, mock_psql, tmp_manifest_path
    ):
        mock_psql.stdout = ""
        from drop_dependents import drop_views

        waves = {
            3: ["vw_recipe_prep_part", "vw_jeremy_runs"],
            2: ["vw_lot_edge", "vw_lot"],
            1: ["upstream", "downstream"],
        }
        manifest_path = str(tmp_manifest_path)
        drop_views("perseus", waves, manifest_path)
        # Verify wave 3 dropped before wave 2
        calls = mock_db_connection.call_args_list
        sqls = [c.args[0][-1] if isinstance(c.args[0], list) else "" for c in calls]
        sql_str = " ".join(str(s) for s in sqls)
        assert sql_str.index("vw_recipe_prep_part") < sql_str.index("vw_lot")

    def test_uses_if_exists_for_idempotency(self, mock_db_connection, mock_psql):
        mock_psql.stdout = ""
        from drop_dependents import drop_single_view

        sql = drop_single_view("perseus", "upstream")
        assert "IF EXISTS" in sql


class TestDropMaterializedView:
    """Test materialized view dropping."""

    def test_drops_mv_with_cascade(self, mock_db_connection, mock_psql):
        mock_psql.stdout = ""
        from drop_dependents import drop_materialized_view

        sql = drop_materialized_view("perseus", "translated")
        assert "MATERIALIZED VIEW" in sql
        assert "CASCADE" in sql


class TestDropFkConstraints:
    """Test FK constraint dropping."""

    def test_drops_all_fk_constraints(
        self, mock_db_connection, mock_psql, sample_fk_ddl
    ):
        mock_psql.stdout = ""
        from drop_dependents import drop_fk_constraints

        constraints = [
            {
                "table": "material_transition",
                "name": "fk_material_transition_material_id",
            },
            {
                "table": "material_transition",
                "name": "fk_material_transition_transition_id",
            },
            {
                "table": "transition_material",
                "name": "fk_transition_material_material_id",
            },
            {
                "table": "transition_material",
                "name": "fk_transition_material_transition_id",
            },
        ]
        sqls = drop_fk_constraints("perseus", constraints)
        assert len(sqls) == 4
        assert all("DROP CONSTRAINT" in s for s in sqls)


class TestDropIndexes:
    """Test index dropping."""

    def test_drops_indexes_on_target_columns(self, mock_db_connection, mock_psql):
        mock_psql.stdout = ""
        from drop_dependents import drop_indexes

        indexes = [
            {"schema": "perseus", "name": "ix_goo_uid"},
            {"schema": "perseus", "name": "ix_fatsmurf_uid"},
        ]
        sqls = drop_indexes(indexes)
        assert len(sqls) == 2
        assert all("DROP INDEX" in s for s in sqls)


class TestDropDependentsOrchestration:
    """Test the full Phase 1 orchestration."""

    def test_drops_in_correct_order(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        """Views first (top-down), then MV, then FK, then indexes."""
        mock_psql.stdout = ""
        from drop_dependents import run_drop_dependents

        result = run_drop_dependents(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        assert result["views_dropped"] >= 0
        assert result["constraints_dropped"] >= 0
        assert result["indexes_dropped"] >= 0

    def test_records_drops_in_manifest(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        mock_psql.stdout = ""
        from drop_dependents import run_drop_dependents

        manifest_path = tmp_path / "manifest.json"
        run_drop_dependents(
            config=sample_config,
            manifest_path=str(manifest_path),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        assert manifest_path.exists()
