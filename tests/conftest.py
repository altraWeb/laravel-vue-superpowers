"""Pytest fixtures for the config helper test suite.

Each test gets isolated tmp paths for plugin / user / project config locations,
plus a helper function to invoke the config CLI as a subprocess.
"""
import os
import subprocess
import sys
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parent.parent


@pytest.fixture
def plugin_dir(tmp_path):
    """A temp directory pretending to be the installed plugin root.

    Copies config.defaults.yaml and config.schema.json from the real repo
    so the helper can find them in their expected location.
    """
    pd = tmp_path / "plugin"
    pd.mkdir()
    (pd / "config.defaults.yaml").write_bytes(
        (REPO_ROOT / "config.defaults.yaml").read_bytes()
    )
    (pd / "config.schema.json").write_bytes(
        (REPO_ROOT / "config.schema.json").read_bytes()
    )
    return pd


@pytest.fixture
def user_config_dir(tmp_path, monkeypatch):
    """A temp ~/.claude/plugins/altraweb-laravel/laravel-superpowers/ dir.

    Monkeypatches HOME so the helper sees this as the user-global location.
    """
    fake_home = tmp_path / "home"
    user_cfg = fake_home / ".claude" / "plugins" / "altraweb-laravel" / "laravel-superpowers"
    user_cfg.mkdir(parents=True)
    monkeypatch.setenv("HOME", str(fake_home))
    return user_cfg


@pytest.fixture
def project_cwd(tmp_path, monkeypatch):
    """A temp dir set as cwd so .laravel-superpowers.yaml is discoverable."""
    pcwd = tmp_path / "project"
    pcwd.mkdir()
    monkeypatch.chdir(pcwd)
    return pcwd


def run_cli(plugin_dir, *args, env_extra=None):
    """Invoke lib/config.py as a subprocess and return CompletedProcess."""
    env = os.environ.copy()
    env["CLAUDE_PLUGIN_ROOT"] = str(plugin_dir)
    if env_extra:
        env.update(env_extra)
    return subprocess.run(
        [sys.executable, str(REPO_ROOT / "lib" / "config.py"), *args],
        capture_output=True,
        text=True,
        env=env,
    )


@pytest.fixture
def cli(plugin_dir):
    """Returns a callable: cli('get', 'pilot_version') -> CompletedProcess."""
    def _cli(*args, env_extra=None):
        return run_cli(plugin_dir, *args, env_extra=env_extra)
    return _cli
