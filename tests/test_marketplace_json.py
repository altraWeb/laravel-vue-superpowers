"""Schema validation for plugin.json and marketplace.json.

The in-repo plugin.json must always be valid + match v3+ shape.
The external marketplace.json (in altraWeb/laravel-marketplace) is
validated in CI on that repo; this test only asserts the local
plugin.json conforms.
"""

import json
import pathlib

import pytest

PLUGIN_DIR = pathlib.Path(__file__).parent.parent / ".claude-plugin"


def test_plugin_json_is_valid_json():
    """plugin.json parses as JSON."""
    data = json.loads((PLUGIN_DIR / "plugin.json").read_text())
    assert isinstance(data, dict)


def test_plugin_json_has_required_fields():
    """plugin.json has name + version + description + author + keywords."""
    data = json.loads((PLUGIN_DIR / "plugin.json").read_text())
    for field in ("name", "version", "description", "author", "keywords"):
        assert field in data, f"missing field: {field}"


def test_plugin_json_name_is_livewire_stack():
    """V3 plugin name explicitly identifies Livewire stack."""
    data = json.loads((PLUGIN_DIR / "plugin.json").read_text())
    assert data["name"] == "laravel-livewire-superpowers"


def test_plugin_json_version_is_semver():
    """version field is semver (X.Y.Z or X.Y.Z-prerelease)."""
    import re
    data = json.loads((PLUGIN_DIR / "plugin.json").read_text())
    pattern = r"^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$"
    assert re.match(pattern, data["version"]), f"not semver: {data['version']}"


def test_in_repo_marketplace_json_removed():
    """In V3 the marketplace lives in altraWeb/laravel-marketplace, not in-repo."""
    assert not (PLUGIN_DIR / "marketplace.json").exists(), \
        ".claude-plugin/marketplace.json should be removed in V3 — marketplace moved to altraWeb/laravel-marketplace"
