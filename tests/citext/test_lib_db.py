"""
TDD tests for lib/db.py — psql connection via subprocess.

RED phase: These tests are written BEFORE the implementation.
"""

from unittest.mock import patch, MagicMock


class TestLoadDbConfig:
    """Test loading database configuration from environment."""

    def test_loads_config_from_env_vars(self, sample_env_vars):
        with patch.dict("os.environ", sample_env_vars, clear=False):
            from lib.db import load_db_config

            config = load_db_config()
            assert config["host"] == "localhost"
            assert config["port"] == "5432"
            assert config["database"] == "perseus_test"
            assert config["user"] == "test_admin"
            assert config["schema"] == "perseus"

    def test_loads_config_from_env_file(self, env_file):
        from lib.db import load_db_config

        config = load_db_config(env_file=str(env_file))
        assert config["host"] == "localhost"
        assert config["database"] == "perseus_test"


class TestExecuteSql:
    """Test executing SQL via psql subprocess."""

    def test_execute_returns_stdout(
        self, mock_db_connection, mock_psql, sample_env_vars
    ):
        mock_psql.stdout = "citext\n"
        with patch.dict("os.environ", sample_env_vars, clear=False):
            from lib.db import execute_sql

            result = execute_sql("SELECT 'citext';")
            assert result.strip() == "citext"

    def test_execute_raises_on_psql_error(
        self, mock_db_connection, mock_psql, sample_env_vars
    ):
        mock_psql.returncode = 1
        mock_psql.stderr = "ERROR: relation does not exist"
        with patch.dict("os.environ", sample_env_vars, clear=False):
            from lib.db import execute_sql

            try:
                execute_sql("SELECT * FROM nonexistent;")
                assert False, "Should have raised"
            except RuntimeError as e:
                assert "relation does not exist" in str(e)

    def test_execute_with_timeout(self, mock_db_connection, mock_psql, sample_env_vars):
        mock_psql.stdout = "ok\n"
        with patch.dict("os.environ", sample_env_vars, clear=False):
            from lib.db import execute_sql

            execute_sql("SELECT 1;", timeout_ms=30000)
            # Verify psql was called (subprocess.run was called)
            mock_db_connection.assert_called_once()

    def test_dry_run_returns_sql_without_executing(self, sample_env_vars):
        with patch.dict("os.environ", sample_env_vars, clear=False):
            from lib.db import execute_sql

            result = execute_sql("ALTER TABLE foo;", dry_run=True)
            assert result == "ALTER TABLE foo;"


class TestExecuteSqlFile:
    """Test executing a SQL file via psql."""

    def test_execute_file(
        self, mock_db_connection, mock_psql, sample_env_vars, tmp_path
    ):
        sql_file = tmp_path / "test.sql"
        sql_file.write_text("SELECT 1;")
        mock_psql.stdout = "1\n"
        with patch.dict("os.environ", sample_env_vars, clear=False):
            from lib.db import execute_sql_file

            result = execute_sql_file(str(sql_file))
            assert result.strip() == "1"


class TestTestConnection:
    """Test connection testing."""

    def test_connection_ok(self, mock_db_connection, mock_psql, sample_env_vars):
        mock_psql.stdout = "1\n"
        with patch.dict("os.environ", sample_env_vars, clear=False):
            from lib.db import test_connection

            assert test_connection() is True

    def test_connection_fails(self, mock_db_connection, mock_psql, sample_env_vars):
        mock_psql.returncode = 2
        mock_psql.stderr = "could not connect"
        with patch.dict("os.environ", sample_env_vars, clear=False):
            from lib.db import test_connection

            assert test_connection() is False
