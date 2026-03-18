"""
Shared pytest fixtures for US7 CITEXT conversion tests.

Provides mock DB connections, temporary manifests, sample configs,
and other shared test infrastructure.
"""

import json
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
import yaml

# Add scripts/post-migration to path so we can import lib modules
SCRIPTS_DIR = (
    Path(__file__).resolve().parent.parent.parent / "scripts" / "post-migration"
)
sys.path.insert(0, str(SCRIPTS_DIR))


# ---------------------------------------------------------------------------
# Path Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def project_root():
    """Return the project root directory."""
    return Path(__file__).resolve().parent.parent.parent


@pytest.fixture
def scripts_dir(project_root):
    """Return the scripts/post-migration directory."""
    return project_root / "scripts" / "post-migration"


@pytest.fixture
def config_dir(scripts_dir):
    """Return the scripts/post-migration/config directory."""
    return scripts_dir / "config"


# ---------------------------------------------------------------------------
# Temporary Directory Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def tmp_dir(tmp_path):
    """Provide a temporary directory for test artifacts."""
    return tmp_path


@pytest.fixture
def tmp_log_dir(tmp_path):
    """Provide a temporary log directory."""
    log_dir = tmp_path / "logs"
    log_dir.mkdir()
    return log_dir


@pytest.fixture
def tmp_manifest_path(tmp_path):
    """Provide a temporary manifest file path."""
    return tmp_path / "manifest.json"


# ---------------------------------------------------------------------------
# Configuration Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def sample_env_vars():
    """Return a dict of sample environment variables matching .env.example."""
    return {
        "PGHOST": "localhost",
        "PGPORT": "5432",
        "PGDATABASE": "perseus_test",
        "PGUSER": "test_admin",
        "PGPASSWORD": "test_pass",
        "PGSCHEMA": "perseus",
        "LOG_DIR": "./logs",
        "DRY_RUN": "false",
        "LOCK_TIMEOUT_MS": "30000",
        "STATEMENT_TIMEOUT_MS": "0",
        "MANIFEST_PATH": "./manifest.json",
    }


@pytest.fixture
def env_file(tmp_path, sample_env_vars):
    """Create a temporary .env file with sample values."""
    env_path = tmp_path / ".env"
    lines = [f"{k}={v}" for k, v in sample_env_vars.items()]
    env_path.write_text("\n".join(lines) + "\n")
    return env_path


@pytest.fixture
def sample_config():
    """Return a sample citext-conversion.yaml config as a dict."""
    return {
        "version": 1,
        "schema": "perseus",
        "source_file": "prompts/columns_citext_candidates.txt",
        "fk_groups": [
            {
                "name": "material_lineage",
                "description": "UID columns in FK relationships",
                "columns": [
                    {"table": "goo", "column": "uid"},
                    {"table": "fatsmurf", "column": "uid"},
                    {"table": "material_transition", "column": "material_id"},
                    {"table": "material_transition", "column": "transition_id"},
                    {"table": "transition_material", "column": "material_id"},
                    {"table": "transition_material", "column": "transition_id"},
                ],
            }
        ],
        "cache_tables": {
            "description": "LAST group",
            "tables": [
                {
                    "name": "cache_dirty_leaves",
                    "columns": [
                        {"table": "m_upstream_dirty_leaves", "column": "material_uid"},
                    ],
                },
                {
                    "name": "cache_downstream",
                    "columns": [
                        {"table": "m_downstream", "column": "start_point"},
                        {"table": "m_downstream", "column": "end_point"},
                        {"table": "m_downstream", "column": "path"},
                    ],
                },
                {
                    "name": "cache_upstream",
                    "columns": [
                        {"table": "m_upstream", "column": "start_point"},
                        {"table": "m_upstream", "column": "end_point"},
                        {"table": "m_upstream", "column": "path"},
                    ],
                },
            ],
        },
        "independent_columns": [
            {"table": "color", "columns": ["name"]},
            {"table": "unit", "columns": ["description", "name"]},
            {"table": "goo", "columns": ["catalog_label", "description", "name"]},
            {"table": "container", "columns": ["name", "uid"]},
        ],
        "large_tables_order": [
            {"table": "container", "rows": 4250550, "size_mb": 724},
            {"table": "goo", "rows": 5942387, "size_mb": 880},
        ],
    }


@pytest.fixture
def config_file(tmp_path, sample_config):
    """Create a temporary citext-conversion.yaml file."""
    config_path = tmp_path / "citext-conversion.yaml"
    config_path.write_text(yaml.dump(sample_config, default_flow_style=False))
    return config_path


# ---------------------------------------------------------------------------
# Manifest Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def empty_manifest():
    """Return an empty manifest structure."""
    return {
        "version": 1,
        "started_at": None,
        "last_updated": None,
        "current_phase": None,
        "phases": {},
        "original_types": {},
    }


@pytest.fixture
def partial_manifest():
    """Return a manifest with Phase 0 complete and Phase 1 in progress."""
    return {
        "version": 1,
        "started_at": "2026-03-17T14:30:00Z",
        "last_updated": "2026-03-17T14:35:00Z",
        "current_phase": "01-drop-dependents",
        "phases": {
            "00-preflight": {
                "status": "complete",
                "completed_at": "2026-03-17T14:31:00Z",
            },
            "01-drop-dependents": {
                "status": "in_progress",
                "dropped": [
                    {
                        "type": "view",
                        "name": "perseus.vw_recipe_prep_part",
                        "ddl": "CREATE OR REPLACE VIEW perseus.vw_recipe_prep_part AS SELECT 1;",
                    },
                ],
            },
        },
        "original_types": {
            "perseus.color.name": {"type": "character varying", "length": 50},
        },
    }


@pytest.fixture
def manifest_file(tmp_path, empty_manifest):
    """Create a temporary manifest.json file."""
    manifest_path = tmp_path / "manifest.json"
    manifest_path.write_text(json.dumps(empty_manifest, indent=2))
    return manifest_path


# ---------------------------------------------------------------------------
# Mock DB Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def mock_psql():
    """
    Mock for subprocess-based psql execution.
    Returns a configurable mock that simulates psql output.
    """
    mock = MagicMock()
    mock.returncode = 0
    mock.stdout = ""
    mock.stderr = ""
    return mock


@pytest.fixture
def mock_db_connection(mock_psql):
    """
    Patch subprocess.run to simulate psql calls.
    Usage: configure mock_psql.stdout before calling DB functions.
    """
    with patch("subprocess.run", return_value=mock_psql) as patched:
        yield patched


@pytest.fixture
def mock_db_query_results():
    """
    Factory fixture to create mock psql query results.
    Returns a function that generates formatted psql output.
    """

    def _make_result(columns, rows):
        """
        Generate mock psql tabular output.

        Args:
            columns: list of column names
            rows: list of tuples with values
        """
        header = "|".join(columns)
        separator = "+".join(["-" * len(c) for c in columns])
        data_lines = ["|".join(str(v) for v in row) for row in rows]
        lines = [header, separator] + data_lines
        return "\n".join(lines) + "\n"

    return _make_result


# ---------------------------------------------------------------------------
# Sample SQL Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def sample_view_ddl():
    """Return sample view DDL for testing drop/recreate."""
    return {
        "upstream": (
            "CREATE OR REPLACE VIEW perseus.upstream AS\n"
            "SELECT mt.material_id, mt.transition_id\n"
            "FROM perseus.material_transition mt;"
        ),
        "downstream": (
            "CREATE OR REPLACE VIEW perseus.downstream AS\n"
            "SELECT tm.transition_id, tm.material_id\n"
            "FROM perseus.transition_material tm;"
        ),
    }


@pytest.fixture
def sample_index_ddl():
    """Return sample index DDL for testing drop/recreate."""
    return {
        "ix_goo_uid": "CREATE UNIQUE INDEX ix_goo_uid ON perseus.goo USING btree (uid);",
        "ix_fatsmurf_uid": "CREATE UNIQUE INDEX ix_fatsmurf_uid ON perseus.fatsmurf USING btree (uid);",
        "ix_container_uid": "CREATE UNIQUE INDEX ix_container_uid ON perseus.container USING btree (uid);",
    }


@pytest.fixture
def sample_fk_ddl():
    """Return sample FK constraint DDL for testing drop/recreate."""
    return {
        "fk_material_transition_material_id": (
            "ALTER TABLE perseus.material_transition\n"
            "ADD CONSTRAINT fk_material_transition_material_id\n"
            "FOREIGN KEY (material_id) REFERENCES perseus.goo(uid)\n"
            "ON DELETE CASCADE;"
        ),
        "fk_material_transition_transition_id": (
            "ALTER TABLE perseus.material_transition\n"
            "ADD CONSTRAINT fk_material_transition_transition_id\n"
            "FOREIGN KEY (transition_id) REFERENCES perseus.fatsmurf(uid)\n"
            "ON DELETE CASCADE ON UPDATE CASCADE;"
        ),
        "fk_transition_material_material_id": (
            "ALTER TABLE perseus.transition_material\n"
            "ADD CONSTRAINT fk_transition_material_material_id\n"
            "FOREIGN KEY (material_id) REFERENCES perseus.goo(uid)\n"
            "ON DELETE CASCADE;"
        ),
        "fk_transition_material_transition_id": (
            "ALTER TABLE perseus.transition_material\n"
            "ADD CONSTRAINT fk_transition_material_transition_id\n"
            "FOREIGN KEY (transition_id) REFERENCES perseus.fatsmurf(uid)\n"
            "ON DELETE CASCADE ON UPDATE CASCADE;"
        ),
    }


# ---------------------------------------------------------------------------
# Target Column Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def sample_target_columns():
    """Return a small subset of target columns for testing."""
    return [
        {"table": "color", "column": "name"},
        {"table": "unit", "column": "description"},
        {"table": "unit", "column": "name"},
        {"table": "goo", "column": "uid"},
        {"table": "goo", "column": "name"},
        {"table": "goo", "column": "description"},
        {"table": "goo", "column": "catalog_label"},
        {"table": "fatsmurf", "column": "uid"},
        {"table": "fatsmurf", "column": "name"},
        {"table": "fatsmurf", "column": "description"},
    ]


@pytest.fixture
def all_target_columns(project_root):
    """Parse and return ALL 172 target columns from the candidates file."""
    candidates_file = project_root / "prompts" / "columns_citext_candidates.txt"
    columns = []
    for line in candidates_file.read_text().strip().splitlines():
        # Parse: ALTER TABLE {table} ALTER COLUMN {column} TYPE citext;
        parts = line.strip().rstrip(";").split()
        if len(parts) >= 7 and parts[0] == "ALTER":
            columns.append({"table": parts[2], "column": parts[5]})
    return columns
