"""
Permanent error log table in PostgreSQL for CITEXT migration audit.

Stores all errors, warnings, and fatals in a persistent table that survives
script crashes. Double try/except ensures log_error() itself never crashes.
"""

import logging

from lib.db import execute_sql

logger = logging.getLogger("citext.error-log")

_ERROR_LOG_TABLE = "public.citext_migration_error_log"

_CREATE_TABLE_SQL = f"""
CREATE TABLE IF NOT EXISTS {_ERROR_LOG_TABLE} (
    id              SERIAL PRIMARY KEY,
    run_id          TEXT NOT NULL,
    phase           TEXT NOT NULL,
    severity        TEXT NOT NULL DEFAULT 'ERROR',
    schema_name     TEXT,
    table_name      TEXT,
    column_name     TEXT,
    object_type     TEXT,
    object_name     TEXT,
    operation       TEXT,
    sql_attempted   TEXT,
    error_message   TEXT NOT NULL,
    error_detail    TEXT,
    occurred_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    resolved        BOOLEAN DEFAULT FALSE,
    resolved_at     TIMESTAMPTZ,
    notes           TEXT
);
CREATE INDEX IF NOT EXISTS idx_error_log_run
    ON {_ERROR_LOG_TABLE}(run_id);
CREATE INDEX IF NOT EXISTS idx_error_log_phase
    ON {_ERROR_LOG_TABLE}(phase);
"""


def ensure_error_log_table(db_config: dict | None = None) -> None:
    """Create the error log table if it doesn't exist."""
    execute_sql(_CREATE_TABLE_SQL, config=db_config)


def log_error(
    run_id: str,
    phase: str,
    severity: str,
    error_message: str,
    *,
    schema_name: str | None = None,
    table_name: str | None = None,
    column_name: str | None = None,
    object_type: str | None = None,
    object_name: str | None = None,
    operation: str | None = None,
    sql_attempted: str | None = None,
    error_detail: str | None = None,
    db_config: dict | None = None,
) -> None:
    """
    Log an error to both Python logger and the permanent DB table.

    Double try/except: if DB insert fails, falls back to Python logger only.
    This function NEVER raises — it's the safety net.
    """
    logger.error(f"[{phase}] {severity}: {error_message}")

    try:

        def _esc(val: str | None) -> str:
            if val is None:
                return "NULL"
            return "'" + val.replace("'", "''") + "'"

        sql = (
            f"INSERT INTO {_ERROR_LOG_TABLE} "
            f"(run_id, phase, severity, error_message, schema_name, table_name, "
            f"column_name, object_type, object_name, operation, sql_attempted, error_detail) "
            f"VALUES ("
            f"{_esc(run_id)}, {_esc(phase)}, {_esc(severity)}, {_esc(error_message)}, "
            f"{_esc(schema_name)}, {_esc(table_name)}, {_esc(column_name)}, "
            f"{_esc(object_type)}, {_esc(object_name)}, {_esc(operation)}, "
            f"{_esc(sql_attempted)}, {_esc(error_detail)}"
            f");"
        )
        execute_sql(sql, config=db_config)
    except Exception:
        logger.warning("Could not write to error_log table — logged to file only")


def get_errors_for_run(
    run_id: str,
    db_config: dict | None = None,
) -> list[dict]:
    """Get all error log entries for a specific run."""
    sql = (
        f"SELECT phase, severity, table_name, column_name, object_type, "
        f"operation, error_message "
        f"FROM {_ERROR_LOG_TABLE} "
        f"WHERE run_id = '{run_id}' "
        f"ORDER BY occurred_at;"
    )
    result = execute_sql(sql, config=db_config).strip()
    errors = []
    for line in result.splitlines():
        if not line.strip():
            continue
        parts = line.split("|")
        if len(parts) >= 7:
            errors.append(
                {
                    "phase": parts[0].strip(),
                    "severity": parts[1].strip(),
                    "table_name": parts[2].strip(),
                    "column_name": parts[3].strip(),
                    "object_type": parts[4].strip(),
                    "operation": parts[5].strip(),
                    "error_message": parts[6].strip(),
                }
            )
    return errors


def get_error_summary(
    run_id: str,
    db_config: dict | None = None,
) -> dict:
    """Get error counts grouped by phase and severity."""
    sql = (
        f"SELECT phase, severity, COUNT(*) "
        f"FROM {_ERROR_LOG_TABLE} "
        f"WHERE run_id = '{run_id}' "
        f"GROUP BY phase, severity ORDER BY phase, severity;"
    )
    try:
        result = execute_sql(sql, config=db_config).strip()
    except Exception:
        return {"error": "Could not query error_log table"}

    summary = {}
    for line in result.splitlines():
        if not line.strip():
            continue
        parts = line.split("|")
        if len(parts) >= 3:
            phase = parts[0].strip()
            severity = parts[1].strip()
            count = int(parts[2].strip())
            summary.setdefault(phase, {})[severity] = count
    return summary
