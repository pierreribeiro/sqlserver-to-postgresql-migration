"""
TDD tests for lib/manifest.py — JSON checkpoint manifest (resume + rollback).

RED phase: These tests are written BEFORE the implementation.
"""

import json
from pathlib import Path


class TestManifestCreate:
    """Test creating a new manifest."""

    def test_create_new_manifest(self, tmp_manifest_path):
        from lib.manifest import Manifest

        m = Manifest(str(tmp_manifest_path))
        m.create()
        assert tmp_manifest_path.exists()
        data = json.loads(tmp_manifest_path.read_text())
        assert data["version"] == 1
        assert data["started_at"] is not None
        assert data["current_phase"] is None
        assert data["phases"] == {}
        assert data["original_types"] == {}

    def test_create_sets_started_at_timestamp(self, tmp_manifest_path):
        from lib.manifest import Manifest

        m = Manifest(str(tmp_manifest_path))
        m.create()
        data = json.loads(tmp_manifest_path.read_text())
        # ISO format timestamp
        assert "T" in data["started_at"]


class TestManifestLoad:
    """Test loading an existing manifest."""

    def test_load_existing_manifest(self, tmp_manifest_path, partial_manifest):
        tmp_manifest_path.write_text(json.dumps(partial_manifest))
        from lib.manifest import Manifest

        m = Manifest(str(tmp_manifest_path))
        m.load()
        assert m.data["current_phase"] == "01-drop-dependents"
        assert m.data["phases"]["00-preflight"]["status"] == "complete"

    def test_load_nonexistent_raises_error(self, tmp_path):
        from lib.manifest import Manifest

        m = Manifest(str(tmp_path / "nonexistent.json"))
        try:
            m.load()
            assert False, "Should have raised FileNotFoundError"
        except FileNotFoundError:
            pass


class TestManifestPhases:
    """Test phase management operations."""

    def test_start_phase(self, tmp_manifest_path):
        from lib.manifest import Manifest

        m = Manifest(str(tmp_manifest_path))
        m.create()
        m.start_phase("00-preflight")
        data = json.loads(tmp_manifest_path.read_text())
        assert data["current_phase"] == "00-preflight"
        assert data["phases"]["00-preflight"]["status"] == "in_progress"

    def test_complete_phase(self, tmp_manifest_path):
        from lib.manifest import Manifest

        m = Manifest(str(tmp_manifest_path))
        m.create()
        m.start_phase("00-preflight")
        m.complete_phase("00-preflight")
        data = json.loads(tmp_manifest_path.read_text())
        assert data["phases"]["00-preflight"]["status"] == "complete"
        assert "completed_at" in data["phases"]["00-preflight"]


class TestManifestCheckpoints:
    """Test checkpoint operations for resume support."""

    def test_record_dropped_object(self, tmp_manifest_path):
        from lib.manifest import Manifest

        m = Manifest(str(tmp_manifest_path))
        m.create()
        m.start_phase("01-drop-dependents")
        m.record_dropped(
            "view", "perseus.upstream", "CREATE VIEW perseus.upstream AS ..."
        )
        data = json.loads(tmp_manifest_path.read_text())
        dropped = data["phases"]["01-drop-dependents"]["dropped"]
        assert len(dropped) == 1
        assert dropped[0]["type"] == "view"
        assert dropped[0]["name"] == "perseus.upstream"
        assert dropped[0]["ddl"] == "CREATE VIEW perseus.upstream AS ..."

    def test_record_column_converted(self, tmp_manifest_path):
        from lib.manifest import Manifest

        m = Manifest(str(tmp_manifest_path))
        m.create()
        m.start_phase("02-alter-columns")
        m.record_column_converted("goo", "uid", "character varying", 50)
        data = json.loads(tmp_manifest_path.read_text())
        completed = data["phases"]["02-alter-columns"]["completed"]
        assert "goo.uid" in completed
        orig = data["original_types"]["perseus.goo.uid"]
        assert orig["type"] == "character varying"
        assert orig["length"] == 50

    def test_is_column_converted(self, tmp_manifest_path):
        from lib.manifest import Manifest

        m = Manifest(str(tmp_manifest_path))
        m.create()
        m.start_phase("02-alter-columns")
        assert not m.is_column_converted("goo", "uid")
        m.record_column_converted("goo", "uid", "character varying", 50)
        assert m.is_column_converted("goo", "uid")

    def test_is_object_dropped(self, tmp_manifest_path):
        from lib.manifest import Manifest

        m = Manifest(str(tmp_manifest_path))
        m.create()
        m.start_phase("01-drop-dependents")
        assert not m.is_object_dropped("perseus.upstream")
        m.record_dropped("view", "perseus.upstream", "CREATE VIEW ...")
        assert m.is_object_dropped("perseus.upstream")

    def test_get_phase_status(self, tmp_manifest_path):
        from lib.manifest import Manifest

        m = Manifest(str(tmp_manifest_path))
        m.create()
        assert m.get_phase_status("00-preflight") is None
        m.start_phase("00-preflight")
        assert m.get_phase_status("00-preflight") == "in_progress"
        m.complete_phase("00-preflight")
        assert m.get_phase_status("00-preflight") == "complete"
