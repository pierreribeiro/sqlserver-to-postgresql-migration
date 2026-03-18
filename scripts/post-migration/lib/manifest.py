"""
JSON checkpoint manifest for resume and rollback support.

Tracks the state of each phase, dropped objects, converted columns,
and original types for rollback.
"""

import json
from datetime import datetime, timezone
from pathlib import Path


class Manifest:
    """Manages a JSON manifest file for checkpoint/resume/rollback."""

    def __init__(self, path: str):
        self.path = Path(path)
        self.data: dict = {}

    def create(self):
        """Create a new empty manifest."""
        self.data = {
            "version": 1,
            "started_at": datetime.now(timezone.utc).isoformat(),
            "last_updated": datetime.now(timezone.utc).isoformat(),
            "current_phase": None,
            "phases": {},
            "original_types": {},
        }
        self._save()

    def load(self):
        """Load manifest from disk. Raises FileNotFoundError if missing."""
        if not self.path.exists():
            raise FileNotFoundError(f"Manifest not found: {self.path}")
        self.data = json.loads(self.path.read_text())

    def _save(self):
        """Persist manifest to disk."""
        self.data["last_updated"] = datetime.now(timezone.utc).isoformat()
        self.path.write_text(json.dumps(self.data, indent=2))

    def start_phase(self, phase_name: str):
        """Mark a phase as in_progress."""
        self.data["current_phase"] = phase_name
        self.data["phases"][phase_name] = {"status": "in_progress"}
        self._save()

    def complete_phase(self, phase_name: str):
        """Mark a phase as complete."""
        self.data["phases"][phase_name]["status"] = "complete"
        self.data["phases"][phase_name]["completed_at"] = datetime.now(
            timezone.utc
        ).isoformat()
        self._save()

    def get_phase_status(self, phase_name: str) -> str | None:
        """Get the status of a phase, or None if not started."""
        phase = self.data.get("phases", {}).get(phase_name)
        if phase is None:
            return None
        return phase["status"]

    def record_dropped(self, obj_type: str, name: str, ddl: str):
        """Record a dropped object in the current phase."""
        phase = self.data["current_phase"]
        if "dropped" not in self.data["phases"][phase]:
            self.data["phases"][phase]["dropped"] = []
        self.data["phases"][phase]["dropped"].append(
            {"type": obj_type, "name": name, "ddl": ddl}
        )
        self._save()

    def is_object_dropped(self, name: str) -> bool:
        """Check if an object has already been dropped."""
        phase = self.data["current_phase"]
        dropped = self.data["phases"].get(phase, {}).get("dropped", [])
        return any(d["name"] == name for d in dropped)

    def record_column_converted(
        self, table: str, column: str, original_type: str, length: int | None
    ):
        """Record a successfully converted column."""
        phase = self.data["current_phase"]
        if "completed" not in self.data["phases"][phase]:
            self.data["phases"][phase]["completed"] = []
        key = f"{table}.{column}"
        self.data["phases"][phase]["completed"].append(key)
        schema = self.data.get("schema", "perseus")
        self.data["original_types"][f"{schema}.{table}.{column}"] = {
            "type": original_type,
            "length": length,
        }
        self._save()

    def is_column_converted(self, table: str, column: str) -> bool:
        """Check if a column has already been converted."""
        phase = self.data["current_phase"]
        completed = self.data["phases"].get(phase, {}).get("completed", [])
        return f"{table}.{column}" in completed
