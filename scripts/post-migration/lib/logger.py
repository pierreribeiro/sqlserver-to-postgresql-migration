"""
Structured dual logging — console (rich formatted) + file.

Log file naming: {step_name}-{YYYYMMDD-HHMMSS}.log
Custom levels: SQL, OK, CHECKPOINT, ABORT
"""

import logging
from datetime import datetime
from pathlib import Path

# Custom log levels
SQL_LEVEL = 25
OK_LEVEL = 26
CHECKPOINT_LEVEL = 27
ABORT_LEVEL = 45

logging.addLevelName(SQL_LEVEL, "SQL")
logging.addLevelName(OK_LEVEL, "OK")
logging.addLevelName(CHECKPOINT_LEVEL, "CHECKPOINT")
logging.addLevelName(ABORT_LEVEL, "ABORT")


class CITextLogger(logging.Logger):
    """Logger with custom level methods for CITEXT conversion."""

    def sql(self, message: str, *args, **kwargs):
        if self.isEnabledFor(SQL_LEVEL):
            self._log(SQL_LEVEL, message, args, **kwargs)

    def ok(self, message: str, *args, **kwargs):
        if self.isEnabledFor(OK_LEVEL):
            self._log(OK_LEVEL, message, args, **kwargs)

    def checkpoint(self, message: str, *args, **kwargs):
        if self.isEnabledFor(CHECKPOINT_LEVEL):
            self._log(CHECKPOINT_LEVEL, message, args, **kwargs)

    def abort(self, message: str, *args, **kwargs):
        if self.isEnabledFor(ABORT_LEVEL):
            self._log(ABORT_LEVEL, message, args, **kwargs)


# Register our custom logger class
logging.setLoggerClass(CITextLogger)


class MillisecondFormatter(logging.Formatter):
    """Formatter that outputs timestamps with millisecond precision."""

    def formatTime(self, record, datefmt=None):
        ct = datetime.fromtimestamp(record.created)
        return ct.strftime("%Y-%m-%d %H:%M:%S") + f".{int(record.msecs):03d}"


def setup_logger(step_name: str, log_dir: str = "./logs") -> CITextLogger:
    """
    Create a dual-output logger for a deployment step.

    Args:
        step_name: e.g. "00-preflight-check"
        log_dir: directory for log files

    Returns:
        Configured CITextLogger instance
    """
    log_path = Path(log_dir)
    log_path.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_file = log_path / f"{step_name}-{timestamp}.log"

    # Create unique logger name to avoid conflicts between tests
    logger_name = f"citext.{step_name}.{timestamp}"
    logger = logging.getLogger(logger_name)
    logger.__class__ = CITextLogger
    logger.setLevel(logging.DEBUG)

    # File handler
    file_handler = logging.FileHandler(str(log_file), encoding="utf-8")
    file_handler.setLevel(logging.DEBUG)
    formatter = MillisecondFormatter(fmt="[%(asctime)s] [%(levelname)s] %(message)s")
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    # Console handler (simple for now — rich can be added later)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    return logger
