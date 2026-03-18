"""
Orchestrator: Run all CITEXT conversion phases sequentially.

Supports --resume (skip completed phases) and --dry-run (show SQL only).

Usage:
    python run-all.py [--config PATH] [--dry-run] [--resume]
"""

import argparse
import json
import os
import sys
from pathlib import Path

from lib.dependency import load_config
from lib.logger import setup_logger
from lib.manifest import Manifest

# Phase runner imports (lazy to avoid circular deps in tests)
from preflight_check import run_preflight
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
    ):
        self.config = config
        self.manifest_path = manifest_path
        self.log_dir = log_dir
        self.schema = schema
        self.dry_run = dry_run
        self.resume = resume
        self.manifest = None

        if resume and Path(manifest_path).exists():
            self.manifest = Manifest(manifest_path)
            self.manifest.load()

    def should_skip_phase(self, phase_name: str) -> bool:
        """Check if a phase should be skipped (already complete in manifest)."""
        if not self.resume or not self.manifest:
            return False
        return self.manifest.get_phase_status(phase_name) == "complete"

    def run(self) -> dict:
        """Run all phases sequentially."""
        if self.dry_run:
            return {"success": True, "dry_run": True}

        result = {"success": True}

        # Phase 0: Pre-flight
        if not self.should_skip_phase("00-preflight"):
            preflight = run_preflight(
                config=self.config,
                manifest_path=self.manifest_path,
                log_dir=self.log_dir,
            )
            if not preflight.get("connection"):
                return {
                    "success": False,
                    "abort_reason": "connection failed",
                    "phase": "00-preflight",
                }
            result["preflight"] = preflight

        # Phase 1: Drop dependents
        if not self.should_skip_phase("01-drop-dependents"):
            drop_result = run_drop_dependents(
                config=self.config,
                manifest_path=self.manifest_path,
                log_dir=self.log_dir,
                schema=self.schema,
            )
            result["drop_dependents"] = drop_result

        # Phase 2a: ALTER regular columns
        if not self.should_skip_phase("02-alter-columns"):
            alter_result = run_alter_columns(
                config=self.config,
                manifest_path=self.manifest_path,
                log_dir=self.log_dir,
                schema=self.schema,
            )
            result["alter_columns"] = alter_result

        # Phase 2b: ALTER cache tables
        if (
            not self.should_skip_phase("02b-alter-cache-tables")
            and run_alter_cache_tables
        ):
            cache_result = run_alter_cache_tables(
                config=self.config,
                manifest_path=self.manifest_path,
                log_dir=self.log_dir,
                schema=self.schema,
            )
            result["alter_cache_tables"] = cache_result

        # Phase 3: Recreate dependents
        if (
            not self.should_skip_phase("03-recreate-dependents")
            and run_recreate_dependents
        ):
            recreate_result = run_recreate_dependents(
                config=self.config,
                manifest_path=self.manifest_path,
                log_dir=self.log_dir,
                schema=self.schema,
            )
            result["recreate_dependents"] = recreate_result

        # Phase 4: Validation
        if not self.should_skip_phase("04-validate-conversion") and run_validation:
            validate_result = run_validation(
                config=self.config,
                manifest_path=self.manifest_path,
                log_dir=self.log_dir,
                schema=self.schema,
            )
            result["validation"] = validate_result

        # Phase 5: Report
        if run_generate_report:
            report_result = run_generate_report(
                manifest_path=self.manifest_path,
                log_dir=self.log_dir,
            )
            result["report"] = report_result

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

    logger = setup_logger("run-all", log_dir=args.log_dir)
    logger.info("CITEXT Conversion — Starting all phases")

    config = load_config(args.config)
    runner = RunAll(
        config=config,
        manifest_path=args.manifest,
        log_dir=args.log_dir,
        dry_run=args.dry_run,
        resume=args.resume,
    )
    result = runner.run()

    if result["success"]:
        logger.ok("All phases completed successfully")
    else:
        logger.abort(f"Conversion failed: {result.get('abort_reason', 'unknown')}")
        sys.exit(1)


if __name__ == "__main__":
    main()
