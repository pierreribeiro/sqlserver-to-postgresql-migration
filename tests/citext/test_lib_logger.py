"""
TDD tests for lib/logger.py — Structured dual logging (console + file).

RED phase: These tests are written BEFORE the implementation.
"""

import re
from pathlib import Path


class TestSetupLogger:
    """Test setup_logger() creates a properly configured logger."""

    def test_creates_log_file_with_correct_name_pattern(self, tmp_log_dir):
        from lib.logger import setup_logger

        logger = setup_logger("00-preflight-check", log_dir=str(tmp_log_dir))
        log_files = list(tmp_log_dir.glob("00-preflight-check-*.log"))
        assert len(log_files) == 1
        # Pattern: {step}-{YYYYMMDD-HHMMSS}.log
        assert re.match(r"00-preflight-check-\d{8}-\d{6}\.log", log_files[0].name)

    def test_logger_writes_to_file(self, tmp_log_dir):
        from lib.logger import setup_logger

        logger = setup_logger("01-test", log_dir=str(tmp_log_dir))
        logger.info("Test message")
        log_files = list(tmp_log_dir.glob("01-test-*.log"))
        content = log_files[0].read_text()
        assert "Test message" in content

    def test_log_entry_has_timestamp_and_level(self, tmp_log_dir):
        from lib.logger import setup_logger

        logger = setup_logger("02-test", log_dir=str(tmp_log_dir))
        logger.info("Check format")
        log_files = list(tmp_log_dir.glob("02-test-*.log"))
        content = log_files[0].read_text()
        # Expect: [YYYY-MM-DD HH:MM:SS.mmm] [INFO] Check format
        assert re.search(r"\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\]", content)
        assert "[INFO]" in content

    def test_creates_log_dir_if_not_exists(self, tmp_path):
        from lib.logger import setup_logger

        new_log_dir = tmp_path / "new_logs"
        logger = setup_logger("03-test", log_dir=str(new_log_dir))
        assert new_log_dir.exists()


class TestLogLevels:
    """Test different log levels are properly recorded."""

    def test_sql_level(self, tmp_log_dir):
        from lib.logger import setup_logger

        logger = setup_logger("sql-test", log_dir=str(tmp_log_dir))
        logger.sql("ALTER TABLE foo ALTER COLUMN bar TYPE citext;")
        log_files = list(tmp_log_dir.glob("sql-test-*.log"))
        content = log_files[0].read_text()
        assert "[SQL]" in content

    def test_ok_level(self, tmp_log_dir):
        from lib.logger import setup_logger

        logger = setup_logger("ok-test", log_dir=str(tmp_log_dir))
        logger.ok("Column converted successfully")
        log_files = list(tmp_log_dir.glob("ok-test-*.log"))
        content = log_files[0].read_text()
        assert "[OK]" in content

    def test_checkpoint_level(self, tmp_log_dir):
        from lib.logger import setup_logger

        logger = setup_logger("cp-test", log_dir=str(tmp_log_dir))
        logger.checkpoint("Manifest updated: goo.uid COMPLETE")
        log_files = list(tmp_log_dir.glob("cp-test-*.log"))
        content = log_files[0].read_text()
        assert "[CHECKPOINT]" in content

    def test_error_level(self, tmp_log_dir):
        from lib.logger import setup_logger

        logger = setup_logger("err-test", log_dir=str(tmp_log_dir))
        logger.error("Something failed")
        log_files = list(tmp_log_dir.glob("err-test-*.log"))
        content = log_files[0].read_text()
        assert "[ERROR]" in content

    def test_abort_level(self, tmp_log_dir):
        from lib.logger import setup_logger

        logger = setup_logger("abort-test", log_dir=str(tmp_log_dir))
        logger.abort("Phase failed — run rollback")
        log_files = list(tmp_log_dir.glob("abort-test-*.log"))
        content = log_files[0].read_text()
        assert "[ABORT]" in content
