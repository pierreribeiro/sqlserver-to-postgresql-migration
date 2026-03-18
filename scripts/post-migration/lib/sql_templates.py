"""
SQL templates for DROP/CREATE/ALTER operations in CITEXT conversion.

Generates parameterized SQL statements for each phase of the conversion.
"""


def alter_column_sql(schema: str, table: str, column: str) -> str:
    """Generate ALTER COLUMN TYPE citext SQL."""
    return f"ALTER TABLE {schema}.{table} ALTER COLUMN {column} TYPE citext;"


def drop_view_sql(schema: str, view: str) -> str:
    """Generate DROP VIEW IF EXISTS SQL."""
    return f"DROP VIEW IF EXISTS {schema}.{view} CASCADE;"


def drop_materialized_view_sql(schema: str, view: str) -> str:
    """Generate DROP MATERIALIZED VIEW IF EXISTS SQL."""
    return f"DROP MATERIALIZED VIEW IF EXISTS {schema}.{view} CASCADE;"


def drop_constraint_sql(schema: str, table: str, constraint: str) -> str:
    """Generate ALTER TABLE DROP CONSTRAINT SQL."""
    return f"ALTER TABLE {schema}.{table} DROP CONSTRAINT IF EXISTS {constraint};"


def drop_index_sql(schema: str, index: str) -> str:
    """Generate DROP INDEX IF EXISTS SQL."""
    return f"DROP INDEX IF EXISTS {schema}.{index};"


def verify_column_type_sql(schema: str, table: str, column: str) -> str:
    """Generate SQL to verify a column's current type via information_schema."""
    return (
        f"SELECT udt_name FROM information_schema.columns "
        f"WHERE table_schema = '{schema}' "
        f"AND table_name = '{table}' "
        f"AND column_name = '{column}';"
    )


def revert_column_sql(
    schema: str, table: str, column: str, original_type: str, length: int | None
) -> str:
    """Generate ALTER COLUMN to revert to original type (for rollback)."""
    type_spec = f"{original_type}({length})" if length else original_type
    return f"ALTER TABLE {schema}.{table} ALTER COLUMN {column} TYPE {type_spec};"


def set_lock_timeout_sql(timeout_ms: int) -> str:
    """Generate SET lock_timeout SQL."""
    return f"SET lock_timeout = '{timeout_ms}ms';"


def set_statement_timeout_sql(timeout_ms: int) -> str:
    """Generate SET statement_timeout SQL."""
    return f"SET statement_timeout = '{timeout_ms}';"


def fk_group_alter_sql(schema: str, columns: list[dict]) -> str:
    """Generate a transactional ALTER for FK-grouped columns."""
    stmts = [alter_column_sql(schema, c["table"], c["column"]) for c in columns]
    return "BEGIN;\n" + "\n".join(f"  {s}" for s in stmts) + "\nCOMMIT;"
