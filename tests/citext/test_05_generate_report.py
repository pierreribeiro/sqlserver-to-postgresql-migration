"""
TDD tests for 05-generate-report.py — Phase 5: Report Generation.

RED phase: These tests are written BEFORE the implementation.
"""

import json
from pathlib import Path


class TestGenerateReport:
    """Test markdown report generation."""

    def test_generates_markdown_report(self, tmp_path):
        """Creates .md file."""
        from generate_report import generate_report

        manifest_data = {
            "version": 1,
            "started_at": "2026-03-17T14:00:00+00:00",
            "last_updated": "2026-03-17T15:00:00+00:00",
            "current_phase": "04-validate",
            "phases": {
                "00-preflight": {
                    "status": "complete",
                    "completed_at": "2026-03-17T14:05:00+00:00",
                },
                "02-alter-columns": {
                    "status": "complete",
                    "completed_at": "2026-03-17T14:30:00+00:00",
                    "completed": ["color.name", "unit.description"],
                },
            },
            "original_types": {
                "perseus.color.name": {"type": "character varying", "length": 50},
                "perseus.unit.description": {
                    "type": "character varying",
                    "length": 255,
                },
            },
        }
        manifest_path = tmp_path / "manifest.json"
        manifest_path.write_text(json.dumps(manifest_data, indent=2))

        report_dir = tmp_path / "logs"
        report_dir.mkdir()

        report_path = generate_report(
            manifest_path=str(manifest_path),
            report_dir=str(report_dir),
        )
        assert Path(report_path).exists()
        assert report_path.endswith(".md")

    def test_report_includes_summary_table(self, tmp_path):
        """Report includes tables converted, columns changed."""
        from generate_report import generate_report

        manifest_data = {
            "version": 1,
            "started_at": "2026-03-17T14:00:00+00:00",
            "last_updated": "2026-03-17T15:00:00+00:00",
            "current_phase": "04-validate",
            "phases": {
                "02-alter-columns": {
                    "status": "complete",
                    "completed_at": "2026-03-17T14:30:00+00:00",
                    "completed": ["color.name", "unit.description", "unit.name"],
                },
            },
            "original_types": {
                "perseus.color.name": {"type": "character varying", "length": 50},
                "perseus.unit.description": {
                    "type": "character varying",
                    "length": 255,
                },
                "perseus.unit.name": {"type": "character varying", "length": 100},
            },
        }
        manifest_path = tmp_path / "manifest.json"
        manifest_path.write_text(json.dumps(manifest_data, indent=2))

        report_dir = tmp_path / "logs"
        report_dir.mkdir()

        report_path = generate_report(
            manifest_path=str(manifest_path),
            report_dir=str(report_dir),
        )
        content = Path(report_path).read_text()
        assert "Columns Converted" in content or "columns" in content.lower()
        assert "3" in content  # 3 columns converted

    def test_report_includes_duration(self, tmp_path):
        """Report includes timing info."""
        from generate_report import generate_report

        manifest_data = {
            "version": 1,
            "started_at": "2026-03-17T14:00:00+00:00",
            "last_updated": "2026-03-17T15:00:00+00:00",
            "current_phase": "04-validate",
            "phases": {},
            "original_types": {},
        }
        manifest_path = tmp_path / "manifest.json"
        manifest_path.write_text(json.dumps(manifest_data, indent=2))

        report_dir = tmp_path / "logs"
        report_dir.mkdir()

        report_path = generate_report(
            manifest_path=str(manifest_path),
            report_dir=str(report_dir),
        )
        content = Path(report_path).read_text()
        assert "Duration" in content or "duration" in content.lower()

    def test_report_includes_warnings(self, tmp_path):
        """Report includes any warnings section."""
        from generate_report import generate_report

        manifest_data = {
            "version": 1,
            "started_at": "2026-03-17T14:00:00+00:00",
            "last_updated": "2026-03-17T15:00:00+00:00",
            "current_phase": "04-validate",
            "phases": {
                "02-alter-columns": {
                    "status": "complete",
                    "completed_at": "2026-03-17T14:30:00+00:00",
                    "completed": [],
                    "warnings": ["Table goo took 45 minutes"],
                },
            },
            "original_types": {},
        }
        manifest_path = tmp_path / "manifest.json"
        manifest_path.write_text(json.dumps(manifest_data, indent=2))

        report_dir = tmp_path / "logs"
        report_dir.mkdir()

        report_path = generate_report(
            manifest_path=str(manifest_path),
            report_dir=str(report_dir),
        )
        content = Path(report_path).read_text()
        assert "Warning" in content or "warning" in content.lower()

    def test_run_generate_report(self, tmp_path):
        """Full orchestration."""
        from generate_report import run_generate_report

        manifest_data = {
            "version": 1,
            "started_at": "2026-03-17T14:00:00+00:00",
            "last_updated": "2026-03-17T15:00:00+00:00",
            "current_phase": "04-validate",
            "phases": {
                "02-alter-columns": {
                    "status": "complete",
                    "completed_at": "2026-03-17T14:30:00+00:00",
                    "completed": ["color.name"],
                },
            },
            "original_types": {
                "perseus.color.name": {"type": "character varying", "length": 50}
            },
        }
        manifest_path = tmp_path / "manifest.json"
        manifest_path.write_text(json.dumps(manifest_data, indent=2))

        report_dir = tmp_path / "logs"
        report_dir.mkdir()

        result = run_generate_report(
            manifest_path=str(manifest_path),
            report_dir=str(report_dir),
        )
        assert "report_path" in result
        assert Path(result["report_path"]).exists()
