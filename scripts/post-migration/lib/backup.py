"""
Permanent backup table in PostgreSQL for CITEXT migration DDL.

Stores captured DDL in a database table that survives script crashes,
manifest deletion, and partial runs. Each run gets a unique run_id
for audit trail.
"""

import uuid

from lib.db import execute_sql

_BACKUP_TABLE = "public.citext_migration_backup"

_CREATE_TABLE_SQL = f"""
CREATE TABLE IF NOT EXISTS {_BACKUP_TABLE} (
    id              SERIAL PRIMARY KEY,
    run_id          TEXT NOT NULL,
    phase           TEXT NOT NULL,
    object_type     TEXT NOT NULL,
    schema_name     TEXT NOT NULL,
    object_name     TEXT NOT NULL,
    depth           INTEGER DEFAULT 0,
    ddl             TEXT NOT NULL,
    status          TEXT DEFAULT 'backed_up',
    captured_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    dropped_at      TIMESTAMPTZ,
    recreated_at    TIMESTAMPTZ,
    error_message   TEXT,
    UNIQUE(run_id, object_type, schema_name, object_name)
);
"""


def generate_run_id() -> str:
    """Generate a short unique run ID."""
    return uuid.uuid4().hex[:12]


def ensure_backup_table(db_config: dict | None = None) -> None:
    """Create the backup table if it doesn't exist."""
    execute_sql(_CREATE_TABLE_SQL, config=db_config)


def snapshot_object(
    run_id: str,
    phase: str,
    object_type: str,
    schema_name: str,
    object_name: str,
    depth: int,
    ddl: str,
    db_config: dict | None = None,
) -> None:
    """Insert a DDL snapshot into the backup table (idempotent via ON CONFLICT)."""
    # Normalize DDL to single line (pg_get_viewdef returns multi-line)
    # and escape single quotes
    safe_ddl = " ".join(ddl.split()).replace("'", "''")
    sql = (
        f"INSERT INTO {_BACKUP_TABLE} "
        f"(run_id, phase, object_type, schema_name, object_name, depth, ddl) "
        f"VALUES ('{run_id}', '{phase}', '{object_type}', '{schema_name}', "
        f"'{object_name}', {depth}, '{safe_ddl}') "
        f"ON CONFLICT (run_id, object_type, schema_name, object_name) DO NOTHING;"
    )
    execute_sql(sql, config=db_config)


def get_snapshot(
    run_id: str,
    phase: str,
    db_config: dict | None = None,
) -> list[dict]:
    """Get all snapshot objects for a run+phase, ordered by depth."""
    sql = (
        f"SELECT object_type, schema_name, object_name, depth, ddl, status "
        f"FROM {_BACKUP_TABLE} "
        f"WHERE run_id = '{run_id}' AND phase = '{phase}' "
        f"ORDER BY depth, object_type, object_name;"
    )
    result = execute_sql(sql, config=db_config).strip()
    objects = []
    for line in result.splitlines():
        if not line.strip():
            continue
        # Use rpartition to split status (last field) from the rest,
        # then limited split for first 4 fields — DDL may contain "|"
        rest, sep, status = line.rpartition("|")
        if not sep:
            continue
        parts = rest.split("|", 4)
        if len(parts) >= 5:
            objects.append(
                {
                    "object_type": parts[0].strip(),
                    "schema_name": parts[1].strip(),
                    "object_name": parts[2].strip(),
                    "depth": int(parts[3].strip()),
                    "ddl": parts[4].strip(),
                    "status": status.strip(),
                }
            )
    return objects


def has_snapshot(
    run_id: str,
    phase: str,
    db_config: dict | None = None,
) -> bool:
    """Check if a snapshot already exists for this run+phase."""
    sql = (
        f"SELECT COUNT(*) FROM {_BACKUP_TABLE} "
        f"WHERE run_id = '{run_id}' AND phase = '{phase}';"
    )
    result = execute_sql(sql, config=db_config).strip()
    return result != "" and int(result) > 0


def mark_dropped(
    run_id: str,
    schema_name: str,
    object_name: str,
    db_config: dict | None = None,
    note: str | None = None,
) -> None:
    """Mark an object as dropped in the backup table."""
    error_clause = f", error_message = '{note}'" if note else ""
    sql = (
        f"UPDATE {_BACKUP_TABLE} SET status = 'dropped', "
        f"dropped_at = CURRENT_TIMESTAMP{error_clause} "
        f"WHERE run_id = '{run_id}' AND schema_name = '{schema_name}' "
        f"AND object_name = '{object_name}';"
    )
    execute_sql(sql, config=db_config)


def mark_recreated(
    run_id: str,
    schema_name: str,
    object_name: str,
    db_config: dict | None = None,
) -> None:
    """Mark an object as recreated in the backup table."""
    sql = (
        f"UPDATE {_BACKUP_TABLE} SET status = 'recreated', "
        f"recreated_at = CURRENT_TIMESTAMP "
        f"WHERE run_id = '{run_id}' AND schema_name = '{schema_name}' "
        f"AND object_name = '{object_name}';"
    )
    execute_sql(sql, config=db_config)


def get_latest_backup_for_object(
    schema_name: str,
    object_name: str,
    db_config: dict | None = None,
) -> dict | None:
    """Get the most recent backup for an object from any prior run (fallback)."""
    sql = (
        f"SELECT run_id, object_type, depth, ddl, status "
        f"FROM {_BACKUP_TABLE} "
        f"WHERE schema_name = '{schema_name}' AND object_name = '{object_name}' "
        f"ORDER BY captured_at DESC LIMIT 1;"
    )
    result = execute_sql(sql, config=db_config).strip()
    if not result:
        return None
    parts = result.split("|")
    if len(parts) >= 5:
        return {
            "run_id": parts[0].strip(),
            "object_type": parts[1].strip(),
            "depth": int(parts[2].strip()),
            "ddl": parts[3].strip(),
            "status": parts[4].strip(),
        }
    return None
