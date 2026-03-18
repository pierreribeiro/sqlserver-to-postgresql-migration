"""
TDD tests for run-all.py — Orchestrator for all phases.

RED phase: These tests are written BEFORE the implementation.
"""

import json
from unittest.mock import patch, MagicMock


class TestRunAllOrchestrator:
    """Test the orchestrator that runs all phases sequentially."""

    def test_runs_all_phases_in_order(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        mock_psql.stdout = "citext\n"
        from run_all import RunAll

        runner = RunAll(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        # Patch individual phase runners
        with patch(
            "run_all.run_preflight",
            return_value={"connection": True, "citext_extension": True},
        ), patch(
            "run_all.run_drop_dependents",
            return_value={
                "views_dropped": 0,
                "constraints_dropped": 0,
                "indexes_dropped": 0,
            },
        ), patch(
            "run_all.run_alter_columns", return_value={"columns_converted": 10}
        ), patch(
            "run_all.run_alter_cache_tables", return_value={"columns_converted": 7}
        ), patch(
            "run_all.run_recreate_dependents", return_value={"views_created": 0}
        ), patch(
            "run_all.run_validation", return_value={"passed": True}
        ), patch(
            "run_all.run_generate_report", return_value={"report_path": "report.md"}
        ):
            result = runner.run()
            assert result["success"] is True

    def test_dry_run_does_not_execute(self, sample_config, tmp_path):
        from run_all import RunAll

        runner = RunAll(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
            dry_run=True,
        )
        result = runner.run()
        assert result["dry_run"] is True

    def test_resume_skips_completed_phases(self, sample_config, tmp_path):
        # Create manifest with Phase 0 complete
        manifest_path = tmp_path / "manifest.json"
        manifest_path.write_text(
            json.dumps(
                {
                    "version": 1,
                    "started_at": "2026-03-17T14:30:00Z",
                    "last_updated": "2026-03-17T14:31:00Z",
                    "current_phase": "01-drop-dependents",
                    "phases": {
                        "00-preflight": {
                            "status": "complete",
                            "completed_at": "2026-03-17T14:31:00Z",
                        },
                    },
                    "original_types": {},
                }
            )
        )

        from run_all import RunAll

        runner = RunAll(
            config=sample_config,
            manifest_path=str(manifest_path),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
            resume=True,
        )
        # Phase 0 should be skipped
        assert runner.should_skip_phase("00-preflight") is True
        assert runner.should_skip_phase("01-drop-dependents") is False


class TestRunAllAbortOnFailure:
    """Test orchestrator aborts when a phase fails."""

    def test_aborts_when_preflight_fails(
        self, mock_db_connection, mock_psql, sample_config, tmp_path
    ):
        mock_psql.stdout = ""
        from run_all import RunAll

        runner = RunAll(
            config=sample_config,
            manifest_path=str(tmp_path / "manifest.json"),
            log_dir=str(tmp_path / "logs"),
            schema="perseus",
        )
        with patch("run_all.run_preflight", return_value={"connection": False}):
            result = runner.run()
            assert result["success"] is False
            assert "connection" in result.get("abort_reason", "")
