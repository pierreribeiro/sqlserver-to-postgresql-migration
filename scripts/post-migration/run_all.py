"""
Orchestrator: Run all CITEXT conversion phases sequentially.

Supports --resume (skip completed phases) and --dry-run (show SQL only).
Threads run_id across all phases for error log correlation.

Usage:
    python run-all.py [--config PATH] [--dry-run] [--resume]
"""

import argparse
import json
import logging
import os
import sys
from pathlib import Path

from lib.backup import ensure_backup_table, generate_run_id
from lib.dependency import load_config, purge_phantom_columns
from lib.error_log import ensure_error_log_table, get_error_summary, log_error
from lib.logger import setup_logger
from lib.manifest import Manifest

# Phase runner imports (lazy to avoid circular deps in tests)
from preflight_check import run_preflight, validate_columns_exist
from drop_dependents import run_drop_dependents
from alter_columns import run_alter_columns

# These may not exist yet during TDD; handle gracefully
try:
    from alter_cache_tables import run_alter_cache_tables
except ImportError:
    run_alter_cache_tables = None

try:
    from recreate_dependents import run_recreate_dependents
except ImportError:
    run_recreate_dependents = None

try:
    from validate_conversion import run_validation
except ImportError:
    run_validation = None

try:
    from generate_report import run_generate_report
except ImportError:
    run_generate_report = None

logger = logging.getLogger("citext.run-all")


class RunAll:
    """Orchestrates all conversion phases with resume and dry-run support."""

    def __init__(
        self,
        config: dict,
        manifest_path: str = "./manifest.json",
        log_dir: str = "./logs",
        schema: str = "perseus",
        dry_run: bool = False,
        resume: bool = False,
        config_path: str = "config/citext-conversion.yaml",
    ):
        self.config = config
        self.config_path = config_path
        self.manifest_path = manifest_path
        self.log_dir = log_dir
        self.schema = schema
        self.dry_run = dry_run
        self.resume = resume
        self.manifest = None
        self.run_id = generate_run_id()

        if resume and Path(manifest_path).exists():
            self.manifest = Manifest(manifest_path)
            self.manifest.load()
            # Reuse run_id from prior run if available
            self.run_id = self.manifest.data.get("run_id", self.run_id)

    def should_skip_phase(self, phase_name: str) -> bool:
        """Check if a phase should be skipped (already complete in manifest)."""
        if not self.resume or not self.manifest:
            return False
        return self.manifest.get_phase_status(phase_name) == "complete"

    def run(self) -> dict:
        """Run all phases sequentially."""
        if self.dry_run:
            return {"success": True, "dry_run": True}

        result = {"success": True, "run_id": self.run_id}

        # Ensure infrastructure tables exist
        try:
            ensure_error_log_table()
            ensure_backup_table()
        except Exception as e:
            logger.error(f"Could not create infrastructure tables: {e}")
            return {
                "success": False,
                "abort_reason": f"infrastructure setup failed: {e}",
                "phase": "infrastructure",
            }

        # Phase 0: Pre-flight (connection, extension, permissions, manifest)
        if not self.should_skip_phase("00-preflight"):
            try:
                preflight = run_preflight(
                    config=self.config,
                    manifest_path=self.manifest_path,
                    log_dir=self.log_dir,
                )
            except Exception as e:
                log_error(
                    self.run_id,
                    "00-preflight",
                    "FATAL",
                    str(e),
                    operation="PREFLIGHT",
                )
                return {
                    "success": False,
                    "abort_reason": str(e),
                    "phase": "00-preflight",
                    "run_id": self.run_id,
                }

            if not preflight.get("connection"):
                log_error(
                    self.run_id,
                    "00-preflight",
                    "FATAL",
                    "Database connection failed",
                    operation="PREFLIGHT",
                )
                return {
                    "success": False,
                    "abort_reason": "connection failed",
                    "phase": "00-preflight",
                    "run_id": self.run_id,
                }
            result["preflight"] = preflight

            # Column existence validation (runs AFTER preflight confirms DB is up)
            try:
                valid, phantoms = validate_columns_exist(self.config, self.schema)
                if phantoms:
                    for p in phantoms:
                        log_error(
                            self.run_id,
                            "00-preflight",
                            "WARNING",
                            f"Phantom column: {p['table']}.{p['column']}",
                            table_name=p["table"],
                            column_name=p["column"],
                            operation="PREFLIGHT",
                            object_type="config",
                        )
                    removed = purge_phantom_columns(
                        self.config_path,
                        phantoms,
                        self.run_id,
                    )
                    # Reload cleaned config (D1)
                    self.config = load_config(self.config_path)
                    result["phantom_columns_purged"] = removed
                    logger.info(f"Purged {removed} phantom columns, config reloaded")
            except RuntimeError as e:
                log_error(
                    self.run_id,
                    "00-preflight",
                    "FATAL",
                    str(e),
                    operation="VALIDATE_COLUMNS",
                    object_type="config",
                )
                return {
                    "success": False,
                    "abort_reason": str(e),
                    "phase": "00-preflight",
                    "run_id": self.run_id,
                }

        # Phase 1: Drop dependents
        if not self.should_skip_phase("01-drop-dependents"):
            try:
                drop_result = run_drop_dependents(
                    config=self.config,
                    manifest_path=self.manifest_path,
                    log_dir=self.log_dir,
                    schema=self.schema,
                    run_id=self.run_id,
                )
                result["drop_dependents"] = drop_result
            except Exception as e:
                log_error(
                    self.run_id,
                    "01-drop-dependents",
                    "FATAL",
                    str(e),
                    operation="DROP",
                )
                result["drop_dependents"] = {"error": str(e)}
                result["success"] = False

        # Phase 2a: ALTER regular columns
        if not self.should_skip_phase("02-alter-columns"):
            try:
                alter_result = run_alter_columns(
                    config=self.config,
                    manifest_path=self.manifest_path,
                    log_dir=self.log_dir,
                    schema=self.schema,
                    run_id=self.run_id,
                )
                result["alter_columns"] = alter_result
            except Exception as e:
                log_error(
                    self.run_id,
                    "02-alter-columns",
                    "FATAL",
                    str(e),
                    operation="ALTER",
                )
                result["alter_columns"] = {"error": str(e)}
                result["success"] = False

        # Phase 2b: ALTER cache tables
        if (
            not self.should_skip_phase("02b-alter-cache-tables")
            and run_alter_cache_tables
        ):
            try:
                cache_result = run_alter_cache_tables(
                    config=self.config,
                    manifest_path=self.manifest_path,
                    log_dir=self.log_dir,
                    schema=self.schema,
                    run_id=self.run_id,
                )
                result["alter_cache_tables"] = cache_result
            except Exception as e:
                log_error(
                    self.run_id,
                    "02b-alter-cache-tables",
                    "FATAL",
                    str(e),
                    operation="ALTER",
                )
                result["alter_cache_tables"] = {"error": str(e)}
                result["success"] = False

        # Phase 3: Recreate dependents
        if (
            not self.should_skip_phase("03-recreate-dependents")
            and run_recreate_dependents
        ):
            try:
                recreate_result = run_recreate_dependents(
                    config=self.config,
                    manifest_path=self.manifest_path,
                    log_dir=self.log_dir,
                    schema=self.schema,
                    run_id=self.run_id,
                )
                result["recreate_dependents"] = recreate_result
            except Exception as e:
                log_error(
                    self.run_id,
                    "03-recreate-dependents",
                    "FATAL",
                    str(e),
                    operation="RECREATE",
                )
                result["recreate_dependents"] = {"error": str(e)}
                result["success"] = False

        # Phase 4: Validation
        if not self.should_skip_phase("04-validate-conversion") and run_validation:
            try:
                validate_result = run_validation(
                    config=self.config,
                    manifest_path=self.manifest_path,
                    log_dir=self.log_dir,
                    schema=self.schema,
                    run_id=self.run_id,
                )
                result["validation"] = validate_result
            except Exception as e:
                log_error(
                    self.run_id,
                    "04-validate-conversion",
                    "FATAL",
                    str(e),
                    operation="VALIDATE",
                )
                result["validation"] = {"error": str(e)}
                result["success"] = False

        # Phase 5: Report
        if run_generate_report:
            try:
                report_result = run_generate_report(
                    manifest_path=self.manifest_path,
                    report_dir=self.log_dir,
                )
                result["report"] = report_result
            except Exception as e:
                logger.warning(f"Report generation failed: {e}")
                result["report"] = {"error": str(e)}

        # Error summary at end — also determines final success status
        try:
            summary = get_error_summary(self.run_id)
            result["error_summary"] = summary
            # Bug 14: per-object errors must fail the pipeline
            for phase_data in summary.values():
                if isinstance(phase_data, dict):
                    if phase_data.get("ERROR", 0) > 0 or phase_data.get("FATAL", 0) > 0:
                        result["success"] = False
                        break
        except Exception:
            pass

        return result


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="CITEXT Conversion — Run All Phases")
    parser.add_argument("--config", default="config/citext-conversion.yaml")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--manifest", default="./manifest.json")
    parser.add_argument("--log-dir", default=os.environ.get("LOG_DIR", "./logs"))

    args = parser.parse_args()

    log = setup_logger("run-all", log_dir=args.log_dir)
    log.info("CITEXT Conversion — Starting all phases")

    config = load_config(args.config)
    runner = RunAll(
        config=config,
        manifest_path=args.manifest,
        log_dir=args.log_dir,
        dry_run=args.dry_run,
        resume=args.resume,
        config_path=args.config,
    )
    result = runner.run()

    if result.get("run_id"):
        log.info(f"Run ID: {result['run_id']}")

    if result.get("error_summary"):
        log.info(f"Error summary: {json.dumps(result['error_summary'], indent=2)}")

    if result["success"]:
        log.ok("All phases completed successfully")
    else:
        log.abort(
            f"Conversion failed: {result.get('abort_reason', 'see error_summary')}"
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
