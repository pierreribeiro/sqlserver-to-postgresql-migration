"""
TDD tests for 03-recreate-dependents.py — Phase 3: Recreate Dependent Objects.

RED phase: These tests are written BEFORE the implementation.
"""

from unittest.mock import patch, call


class TestRecreateIndexes:
    """Test index recreation."""

    def test_recreates_indexes(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        """Indexes recreated first."""
        mock_psql.stdout = ""
        from recreate_dependents import recreate_indexes

        indexes = [
            {
                "schema": "perseus",
                "name": "ix_goo_uid",
                "ddl": "CREATE UNIQUE INDEX ix_goo_uid ON perseus.goo USING btree (uid);",
            },
            {
                "schema": "perseus",
                "name": "ix_fatsmurf_uid",
                "ddl": "CREATE UNIQUE INDEX ix_fatsmurf_uid ON perseus.fatsmurf USING btree (uid);",
            },
        ]
        sqls = recreate_indexes(indexes, db_config=None)
        assert len(sqls) == 2
        for sql in sqls:
            assert "CREATE" in sql
            assert "INDEX" in sql

    def test_uses_create_index_if_not_exists(self, mock_db_connection, mock_psql):
        """Idempotent index creation."""
        mock_psql.stdout = ""
        from recreate_dependents import recreate_indexes

        indexes = [
            {
                "schema": "perseus",
                "name": "ix_goo_uid",
                "ddl": "CREATE UNIQUE INDEX ix_goo_uid ON perseus.goo USING btree (uid);",
            },
        ]
        sqls = recreate_indexes(indexes, db_config=None)
        assert len(sqls) == 1
        assert "IF NOT EXISTS" in sqls[0]


class TestRecreateFkConstraints:
    """Test FK constraint recreation."""

    def test_recreates_fk_constraints(
        self, mock_db_connection, mock_psql, sample_fk_ddl
    ):
        """FK constraints recreated after indexes."""
        mock_psql.stdout = ""
        from recreate_dependents import recreate_fk_constraints

        constraints = [
            {
                "table": "material_transition",
                "name": "fk_material_transition_material_id",
                "ddl": sample_fk_ddl["fk_material_transition_material_id"],
            },
            {
                "table": "material_transition",
                "name": "fk_material_transition_transition_id",
                "ddl": sample_fk_ddl["fk_material_transition_transition_id"],
            },
        ]
        sqls = recreate_fk_constraints("perseus", constraints, db_config=None)
        assert len(sqls) == 2
        for sql in sqls:
            assert "FOREIGN KEY" in sql or "ADD CONSTRAINT" in sql


class TestRecreateViews:
    """Test view recreation in wave order."""

    def test_recreates_views_in_wave_order(self, mock_db_connection, mock_psql):
        """Wave 0 first, Wave 3 last (bottom-up)."""
        mock_psql.stdout = ""
        from recreate_dependents import recreate_views

        waves = {
            0: [
                {
                    "name": "upstream",
                    "ddl": "CREATE OR REPLACE VIEW perseus.upstream AS SELECT 1;",
                }
            ],
            1: [
                {
                    "name": "downstream",
                    "ddl": "CREATE OR REPLACE VIEW perseus.downstream AS SELECT 1;",
                }
            ],
            3: [
                {
                    "name": "vw_recipe_prep_part",
                    "ddl": "CREATE OR REPLACE VIEW perseus.vw_recipe_prep_part AS SELECT 1;",
                }
            ],
        }
        sqls = recreate_views("perseus", waves, db_config=None)
        assert len(sqls) == 3
        # Wave 0 before Wave 3
        sql_str = " ".join(sqls)
        assert sql_str.index("upstream") < sql_str.index("vw_recipe_prep_part")

    def test_uses_create_or_replace_for_views(self, mock_db_connection, mock_psql):
        """Views use CREATE OR REPLACE for idempotency."""
        mock_psql.stdout = ""
        from recreate_dependents import recreate_views

        waves = {
            0: [
                {
                    "name": "upstream",
                    "ddl": "CREATE OR REPLACE VIEW perseus.upstream AS SELECT 1;",
                }
            ],
        }
        sqls = recreate_views("perseus", waves, db_config=None)
        assert len(sqls) == 1
        assert "CREATE OR REPLACE VIEW" in sqls[0]


class TestRecreateDependentsOrchestration:
    """Test the full Phase 3 orchestration."""

    def test_run_recreate_dependents_orchestration(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        """Full orchestration returns report."""
        mock_psql.stdout = ""
        from recreate_dependents import run_recreate_dependents

        # Provide a manifest that has dropped objects recorded
        manifest_data = {
            "indexes": [
                {
                    "schema": "perseus",
                    "name": "ix_goo_uid",
                    "ddl": "CREATE UNIQUE INDEX ix_goo_uid ON perseus.goo USING btree (uid);",
                },
            ],
            "constraints": [
                {
                    "table": "material_transition",
                    "name": "fk_mt_mid",
                    "ddl": "ALTER TABLE perseus.material_transition ADD CONSTRAINT fk_mt_mid FOREIGN KEY (material_id) REFERENCES perseus.goo(uid);",
                },
            ],
            "views": {
                0: [
                    {
                        "name": "upstream",
                        "ddl": "CREATE OR REPLACE VIEW perseus.upstream AS SELECT 1;",
                    }
                ],
            },
            "materialized_views": [],
        }

        result = run_recreate_dependents(
            dependents=manifest_data,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        assert "indexes_created" in result
        assert "constraints_created" in result
        assert "views_created" in result
