"""
Database connection via psql subprocess.

Reads connection parameters from environment variables or .env file.
All DB interaction goes through psql for simplicity and portability.
"""

import os
import subprocess
from pathlib import Path

from dotenv import load_dotenv

# Auto-discover .env in CWD or parent dirs so all env vars are available
load_dotenv()


def load_db_config(env_file: str | None = None) -> dict:
    """
    Load database configuration from environment variables or .env file.

    Returns dict with keys: host, port, database, user, password, schema
    """
    if env_file:
        load_dotenv(env_file, override=True)

    return {
        "host": os.environ.get("PGHOST", "localhost"),
        "port": os.environ.get("PGPORT", "5432"),
        "database": os.environ.get("PGDATABASE", "perseus_dev"),
        "user": os.environ.get("PGUSER", "perseus_admin"),
        "password": os.environ.get("PGPASSWORD", ""),
        "schema": os.environ.get("PGSCHEMA", "perseus"),
    }


def _build_psql_cmd(config: dict) -> list[str]:
    """Build the psql command with connection parameters."""
    cmd = [
        "psql",
        "-h",
        config["host"],
        "-p",
        config["port"],
        "-U",
        config["user"],
        "-d",
        config["database"],
        "--no-psqlrc",
        "-t",  # tuples only
        "-A",  # unaligned output
    ]
    return cmd


def execute_sql(
    sql: str,
    config: dict | None = None,
    timeout_ms: int | None = None,
    dry_run: bool = False,
) -> str:
    """
    Execute SQL via psql and return stdout.

    Args:
        sql: SQL statement to execute
        config: DB config dict (loads from env if None)
        timeout_ms: optional statement timeout
        dry_run: if True, return the SQL without executing

    Returns:
        psql stdout output

    Raises:
        RuntimeError: if psql returns non-zero exit code
    """
    if dry_run:
        return sql

    if config is None:
        config = load_db_config()

    cmd = _build_psql_cmd(config)
    cmd.extend(["-c", sql])

    env = os.environ.copy()
    if config.get("password"):
        env["PGPASSWORD"] = config["password"]

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        env=env,
        timeout=300,
    )

    if result.returncode != 0:
        raise RuntimeError(
            f"psql error (exit {result.returncode}): {result.stderr.strip()}"
        )

    return result.stdout


def execute_sql_file(
    file_path: str,
    config: dict | None = None,
) -> str:
    """
    Execute a SQL file via psql -f.

    Args:
        file_path: path to SQL file
        config: DB config dict

    Returns:
        psql stdout output
    """
    if config is None:
        config = load_db_config()

    cmd = _build_psql_cmd(config)
    cmd.extend(["-f", file_path])

    env = os.environ.copy()
    if config.get("password"):
        env["PGPASSWORD"] = config["password"]

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        env=env,
        timeout=300,
    )

    if result.returncode != 0:
        raise RuntimeError(
            f"psql error (exit {result.returncode}): {result.stderr.strip()}"
        )

    return result.stdout


def test_connection(config: dict | None = None) -> bool:
    """Test database connectivity. Returns True if connection succeeds."""
    try:
        execute_sql("SELECT 1;", config=config)
        return True
    except (RuntimeError, subprocess.TimeoutExpired, FileNotFoundError):
        return False
