"""
TDD tests for rollback-citext.py — Full rollback from manifest.

RED phase: These tests are written BEFORE the implementation.
"""

import json
from unittest.mock import patch


class TestRollbackColumns:
    """Test reverting column types back to original."""

    def test_reverts_single_column(self, mock_db_connection, mock_psql):
        mock_psql.stdout = ""
        from rollback_citext import revert_column

        sql = revert_column("perseus", "goo", "uid", "character varying", 50)
        assert "ALTER TABLE perseus.goo" in sql
        assert "character varying(50)" in sql

    def test_reverts_column_without_length(self, mock_db_connection, mock_psql):
        mock_psql.stdout = ""
        from rollback_citext import revert_column

        sql = revert_column("perseus", "goo", "uid", "text", None)
        assert "TYPE text" in sql


class TestRollbackFromManifest:
    """Test reading manifest and executing rollback."""

    def test_loads_original_types_from_manifest(self, tmp_path):
        manifest = {
            "version": 1,
            "started_at": "2026-03-17T14:30:00Z",
            "last_updated": "2026-03-17T14:38:15Z",
            "current_phase": "02-alter-columns",
            "phases": {
                "02-alter-columns": {
                    "status": "in_progress",
                    "completed": ["goo.uid"],
                },
            },
            "original_types": {
                "perseus.goo.uid": {"type": "character varying", "length": 50},
            },
        }
        manifest_path = tmp_path / "manifest.json"
        manifest_path.write_text(json.dumps(manifest))

        from rollback_citext import load_rollback_plan

        plan = load_rollback_plan(str(manifest_path))
        assert len(plan) >= 1
        assert plan[0]["table"] == "goo"
        assert plan[0]["column"] == "uid"
        assert plan[0]["original_type"] == "character varying"
        assert plan[0]["length"] == 50

    def test_run_rollback_returns_report(self, mock_db_connection, mock_psql, tmp_path):
        mock_psql.stdout = ""
        manifest = {
            "version": 1,
            "started_at": "2026-03-17T14:30:00Z",
            "last_updated": "2026-03-17T14:38:15Z",
            "current_phase": "02-alter-columns",
            "phases": {
                "02-alter-columns": {
                    "status": "in_progress",
                    "completed": ["color.name"],
                },
            },
            "original_types": {
                "perseus.color.name": {"type": "character varying", "length": 50},
            },
        }
        manifest_path = tmp_path / "manifest.json"
        manifest_path.write_text(json.dumps(manifest))

        from rollback_citext import run_rollback

        result = run_rollback(
            manifest_path=str(manifest_path),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        assert result["columns_reverted"] >= 1
