"""
TDD tests for lib/sql_templates.py — SQL templates for DROP/CREATE/ALTER.

RED phase: These tests are written BEFORE the implementation.
"""


class TestAlterColumnSql:
    """Test ALTER COLUMN TYPE SQL generation."""

    def test_generates_alter_column_sql(self):
        from lib.sql_templates import alter_column_sql

        sql = alter_column_sql("perseus", "goo", "uid")
        assert sql == "ALTER TABLE perseus.goo ALTER COLUMN uid TYPE citext;"

    def test_generates_alter_for_different_schema(self):
        from lib.sql_templates import alter_column_sql

        sql = alter_column_sql("public", "users", "email")
        assert sql == "ALTER TABLE public.users ALTER COLUMN email TYPE citext;"


class TestDropViewSql:
    """Test DROP VIEW SQL generation."""

    def test_generates_drop_view(self):
        from lib.sql_templates import drop_view_sql

        sql = drop_view_sql("perseus", "upstream")
        assert sql == "DROP VIEW IF EXISTS perseus.upstream CASCADE;"

    def test_generates_drop_materialized_view(self):
        from lib.sql_templates import drop_materialized_view_sql

        sql = drop_materialized_view_sql("perseus", "translated")
        assert sql == "DROP MATERIALIZED VIEW IF EXISTS perseus.translated CASCADE;"


class TestDropConstraintSql:
    """Test DROP CONSTRAINT SQL generation."""

    def test_generates_drop_fk(self):
        from lib.sql_templates import drop_constraint_sql

        sql = drop_constraint_sql(
            "perseus", "material_transition", "fk_material_transition_material_id"
        )
        assert sql == (
            "ALTER TABLE perseus.material_transition "
            "DROP CONSTRAINT IF EXISTS fk_material_transition_material_id;"
        )


class TestDropIndexSql:
    """Test DROP INDEX SQL generation."""

    def test_generates_drop_index(self):
        from lib.sql_templates import drop_index_sql

        sql = drop_index_sql("perseus", "ix_goo_uid")
        assert sql == "DROP INDEX IF EXISTS perseus.ix_goo_uid;"


class TestVerifyColumnTypeSql:
    """Test column type verification SQL generation."""

    def test_generates_verify_sql(self):
        from lib.sql_templates import verify_column_type_sql

        sql = verify_column_type_sql("perseus", "goo", "uid")
        assert "information_schema.columns" in sql
        assert "udt_name" in sql
        assert "goo" in sql
        assert "uid" in sql


class TestRevertColumnSql:
    """Test revert column type SQL generation (for rollback)."""

    def test_generates_revert_sql(self):
        from lib.sql_templates import revert_column_sql

        sql = revert_column_sql("perseus", "goo", "uid", "character varying", 50)
        assert (
            sql
            == "ALTER TABLE perseus.goo ALTER COLUMN uid TYPE character varying(50);"
        )

    def test_generates_revert_without_length(self):
        from lib.sql_templates import revert_column_sql

        sql = revert_column_sql("perseus", "goo", "uid", "text", None)
        assert sql == "ALTER TABLE perseus.goo ALTER COLUMN uid TYPE text;"


class TestSetTimeoutSql:
    """Test SET timeout SQL generation."""

    def test_generates_lock_timeout(self):
        from lib.sql_templates import set_lock_timeout_sql

        sql = set_lock_timeout_sql(30000)
        assert sql == "SET lock_timeout = '30000ms';"

    def test_generates_statement_timeout(self):
        from lib.sql_templates import set_statement_timeout_sql

        sql = set_statement_timeout_sql(0)
        assert sql == "SET statement_timeout = '0';"


class TestFkGroupTransactionSql:
    """Test FK group transaction SQL generation."""

    def test_generates_fk_group_alter_transaction(self):
        from lib.sql_templates import fk_group_alter_sql

        columns = [
            {"table": "goo", "column": "uid"},
            {"table": "fatsmurf", "column": "uid"},
            {"table": "material_transition", "column": "material_id"},
        ]
        sql = fk_group_alter_sql("perseus", columns)
        assert sql.startswith("BEGIN;")
        assert sql.endswith("COMMIT;")
        assert "ALTER TABLE perseus.goo ALTER COLUMN uid TYPE citext;" in sql
        assert "ALTER TABLE perseus.fatsmurf ALTER COLUMN uid TYPE citext;" in sql
        assert (
            "ALTER TABLE perseus.material_transition ALTER COLUMN material_id TYPE citext;"
            in sql
        )
