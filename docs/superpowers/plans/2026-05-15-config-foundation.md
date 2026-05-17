# Config Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the plugin config foundation (#22) — a Python helper that exposes merged YAML config (defaults < user < project) to bash hooks, with JSON Schema validation and zero surprise file creation.

**Architecture:** Single-file Python module (`lib/config.py`) shelled out to from bash. YAML files for human-edited config, JSON Schema for IDE autocomplete and structural validation. Defensive fail-open so a broken helper never blocks user operations.

**Tech Stack:** Python 3.10+, PyYAML, jsonschema, pytest. Bash for hook integration tests.

**Spec reference:** `docs/superpowers/specs/2026-05-15-config-foundation-design.md`

---

## File Structure

Files this plan creates or modifies:

| File | Purpose |
|---|---|
| `lib/config.py` | The helper module — load/merge/get/show/validate/init/doctor |
| `lib/__init__.py` | Empty marker so Python treats `lib/` as a package |
| `config.defaults.yaml` | Canonical plugin defaults, self-documenting via inline comments |
| `config.schema.json` | JSON Schema for IDE autocomplete + helper validation |
| `tests/conftest.py` | Pytest fixtures: tmp dirs for plugin/user/project configs |
| `tests/test_config.py` | Unit tests for the helper |
| `tests/test_hook_integration.sh` | End-to-end shell test of the hook integration pattern |
| `tests/requirements-dev.txt` | Pinned versions of pytest for the test suite |
| `requirements.txt` | Runtime requirements (PyYAML, jsonschema) — informational |
| `docs/config.md` | User-facing reference: every key explained, override hierarchy, examples |
| `README.md` | Add "Configuration" section linking to docs/config.md, prerequisites note |

---

## Prerequisites

The dev machine needs Python 3.10+, PyYAML, jsonschema, and pytest. On Homebrew Python (PEP 668), install via:

```bash
pip3 install --user --break-system-packages pyyaml jsonschema pytest
```

This applies once per machine. Hooks call `python3` from the user's PATH.

---

## Task 1: Repository setup — create dirs and dep manifests

**Files:**
- Create: `lib/__init__.py` (empty)
- Create: `tests/__init__.py` (empty)
- Create: `requirements.txt`
- Create: `tests/requirements-dev.txt`
- Create: `.gitignore` additions (`__pycache__/`, `.pytest_cache/`)

- [ ] **Step 1: Create directories and empty package markers**

```bash
mkdir -p lib tests
touch lib/__init__.py tests/__init__.py
```

- [ ] **Step 2: Write `requirements.txt`**

```
# Runtime dependencies for laravel-superpowers config helper.
# Install on the dev machine before using hooks that depend on config:
#   pip3 install --user --break-system-packages -r requirements.txt
PyYAML>=6.0
jsonschema>=4.0
```

- [ ] **Step 3: Write `tests/requirements-dev.txt`**

```
pytest>=8.0
```

- [ ] **Step 4: Update `.gitignore`**

If a `.gitignore` exists, append. If not, create it with:

```
__pycache__/
.pytest_cache/
*.pyc
```

- [ ] **Step 5: Install dev deps locally**

```bash
pip3 install --user --break-system-packages -r requirements.txt -r tests/requirements-dev.txt
```

Expected: success or "already satisfied".

- [ ] **Step 6: Commit**

```bash
git add lib tests requirements.txt .gitignore
git commit -m "chore(#22): scaffold lib/tests dirs + Python requirements"
```

---

## Task 2: Write canonical `config.defaults.yaml`

**Files:**
- Create: `config.defaults.yaml`

- [ ] **Step 1: Write the defaults file**

```yaml
# laravel-superpowers — plugin default config.
# This file is the canonical schema source. Every key here is recognized;
# unknown top-level keys in user/project configs will be rejected.
#
# To override these defaults, create one of:
#   ~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml   (user-global)
#   ./.laravel-superpowers.yaml                                          (per-project, takes precedence)
# Run: python3 lib/config.py init [--project]   to scaffold either file.

# Pilot contract version. 1 = audits optional, 2 = binding hard-gates.
pilot_version: 2

# Per-hook enable/disable flags. Set to false to no-op a specific hook
# without affecting others. Unknown sub-keys here are allowed (future hooks
# can opt in without a schema bump).
hook_enabled:
  banned_token_leak_guard: true
  no_claude_attribution: true
  teamcity_always: true
  anti_silent_deferral: true
  brainstorm_t1_audit: true
  visual_companion_default_on: true

# When does Tier-1 audit auto-dispatch fire?
#   every-phase     — at every Pilot phase boundary
#   every-commit    — on every git commit
#   brainstorm-only — only when superpowers:brainstorming is invoked
audit_aggressiveness: every-phase

# Banned-token leak guard configuration.
banned_tokens:
  # Project-specific tokens to ban in addition to the built-in list.
  # Example: ["AcmeCorp", "INT-1234"]
  project_extras: []

  # Path globs where banned tokens are tolerated (docs that legitimately
  # reference Phase/Sprint/etc).
  exception_paths:
    - "docs/plans/**"
    - "docs/superpowers/**"
    - "CHANGELOG.md"

# Visual companion default for brainstorming Step 2.
#   on  — auto-open browser companion
#   off — text-only
#   ask — prompt operator each time
visual_companion_default: "on"

# Which roadmap tiers to surface in auto-suggestions.
#   T1-only — V2-MVP only
#   T1+T2   — V2-MVP + V2.1
#   all     — everything including V2.2 and V3
tier_preference: "T1+T2"

# Always pass --teamcity to `php artisan test` for parsable output.
teamcity_always: true
```

- [ ] **Step 2: Commit**

```bash
git add config.defaults.yaml
git commit -m "feat(#22): add canonical config.defaults.yaml"
```

---

## Task 3: Write `config.schema.json` and validate defaults against it

**Files:**
- Create: `config.schema.json`

- [ ] **Step 1: Write the schema**

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://raw.githubusercontent.com/altraWeb/laravel-superpowers/main/config.schema.json",
  "title": "laravel-superpowers config",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "pilot_version": {
      "type": "integer",
      "enum": [1, 2],
      "description": "Pilot contract version. 1 = audits optional, 2 = binding hard-gates."
    },
    "hook_enabled": {
      "type": "object",
      "additionalProperties": { "type": "boolean" },
      "description": "Per-hook enable/disable flags. Unknown sub-keys allowed for forward-compat."
    },
    "audit_aggressiveness": {
      "type": "string",
      "enum": ["every-phase", "every-commit", "brainstorm-only"]
    },
    "banned_tokens": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "project_extras": {
          "type": "array",
          "items": { "type": "string" }
        },
        "exception_paths": {
          "type": "array",
          "items": { "type": "string" }
        }
      }
    },
    "visual_companion_default": {
      "type": "string",
      "enum": ["on", "off", "ask"]
    },
    "tier_preference": {
      "type": "string",
      "enum": ["T1-only", "T1+T2", "all"]
    },
    "teamcity_always": { "type": "boolean" }
  }
}
```

- [ ] **Step 2: Sanity-check that defaults validate against schema**

Run:
```bash
python3 -c "
import yaml, json
from jsonschema import validate
defaults = yaml.safe_load(open('config.defaults.yaml'))
schema = json.load(open('config.schema.json'))
validate(defaults, schema)
print('defaults pass schema')
"
```

Expected: `defaults pass schema`. If it fails, fix whichever file is wrong.

- [ ] **Step 3: Commit**

```bash
git add config.schema.json
git commit -m "feat(#22): add config.schema.json + verify defaults validate"
```

---

## Task 4: Write pytest fixtures in `tests/conftest.py`

**Files:**
- Create: `tests/conftest.py`

- [ ] **Step 1: Write fixtures**

```python
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
```

- [ ] **Step 2: Commit**

```bash
git add tests/conftest.py
git commit -m "test(#22): add pytest fixtures for config helper"
```

---

## Task 5: Test + implement `_load_yaml()` (defaults-only path)

**Files:**
- Modify: `lib/config.py` (create)
- Test: `tests/test_config.py` (create)

- [ ] **Step 1: Write the failing test**

```python
"""Tests for lib/config.py."""


def test_get_returns_default_value(cli):
    """With no user/project overlay, `get` returns the default."""
    result = cli("get", "pilot_version")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "2"
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd ~/dev/laravel-superpowers
python3 -m pytest tests/test_config.py::test_get_returns_default_value -v
```

Expected: FAIL with `FileNotFoundError` or `ModuleNotFoundError: lib.config`

- [ ] **Step 3: Write minimal `lib/config.py`**

```python
#!/usr/bin/env python3
"""laravel-superpowers config helper.

Reads merged YAML config from defaults + user-global + per-project layers
and exposes simple CLI verbs for hooks to query.
"""
import os
import sys
from pathlib import Path

import yaml


def _plugin_dir() -> Path:
    """Resolve the plugin root from $CLAUDE_PLUGIN_ROOT (set by Claude Code)."""
    root = os.environ.get("CLAUDE_PLUGIN_ROOT")
    if not root:
        # Fallback: assume this file lives at <plugin>/lib/config.py
        return Path(__file__).resolve().parent.parent
    return Path(root)


def _load_yaml(path: Path) -> dict:
    """Load a YAML file. Returns empty dict if missing."""
    if not path.exists():
        return {}
    with open(path) as f:
        return yaml.safe_load(f) or {}


def _get(data: dict, dotted_key: str):
    """Look up a value via dot-notation. Returns None if missing."""
    cur = data
    for part in dotted_key.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return None
        cur = cur[part]
    return cur


def _format(value) -> str:
    """Format a value for stdout: bool->lowercase, list->JSON, else str."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, list):
        import json
        return json.dumps(value)
    return str(value)


def cmd_get(args: list[str]) -> int:
    if not args:
        print("usage: config.py get <dotted.key>", file=sys.stderr)
        return 2
    key = args[0]
    defaults = _load_yaml(_plugin_dir() / "config.defaults.yaml")
    value = _get(defaults, key)
    if value is None:
        print(f"key not defined: {key}", file=sys.stderr)
        return 1
    print(_format(value))
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: config.py <get|show|validate|init|doctor> [args]", file=sys.stderr)
        return 2
    verb, *rest = sys.argv[1:]
    if verb == "get":
        return cmd_get(rest)
    print(f"unknown verb: {verb}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run test to verify it passes**

```bash
python3 -m pytest tests/test_config.py::test_get_returns_default_value -v
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/config.py tests/test_config.py
git commit -m "feat(#22): lib/config.py get reads defaults, returns dotted-key values"
```

---

## Task 6: Test + implement nested dotted-key lookup

**Files:**
- Test: `tests/test_config.py` (append)

- [ ] **Step 1: Write the failing test**

Append to `tests/test_config.py`:

```python
def test_get_nested_key_via_dot_notation(cli):
    result = cli("get", "hook_enabled.banned_token_leak_guard")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "true"


def test_get_unknown_key_exits_1(cli):
    result = cli("get", "nonexistent")
    assert result.returncode == 1
    assert "key not defined" in result.stderr


def test_get_list_returns_json_array(cli):
    result = cli("get", "banned_tokens.exception_paths")
    assert result.returncode == 0, result.stderr
    import json
    parsed = json.loads(result.stdout)
    assert "CHANGELOG.md" in parsed
```

- [ ] **Step 2: Run tests to verify they pass (already implemented in Task 5)**

```bash
python3 -m pytest tests/test_config.py -v
```

Expected: all four tests PASS. (Implementation from Task 5 already handles these cases.)

- [ ] **Step 3: Commit**

```bash
git add tests/test_config.py
git commit -m "test(#22): cover nested keys, unknown keys, list output"
```

---

## Task 7: Test + implement user-global overlay

**Files:**
- Modify: `lib/config.py`
- Test: `tests/test_config.py` (append)

- [ ] **Step 1: Write the failing test**

```python
def test_user_overlay_overrides_default(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text("pilot_version: 1\n")
    result = cli("get", "pilot_version")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "1"
```

- [ ] **Step 2: Run test to verify it fails**

```bash
python3 -m pytest tests/test_config.py::test_user_overlay_overrides_default -v
```

Expected: FAIL (returns `2`, the default).

- [ ] **Step 3: Implement deep merge + user overlay**

Add to `lib/config.py` (above `cmd_get`):

```python
def _user_config_path() -> Path:
    return Path(os.environ["HOME"]) / ".claude" / "plugins" / "altraweb-laravel" / "laravel-superpowers" / "config.yaml"


def _deep_merge(base: dict, overlay: dict) -> dict:
    """Recursively merge overlay into a copy of base. Overlay wins on conflicts."""
    result = dict(base)
    for key, val in overlay.items():
        if isinstance(val, dict) and isinstance(result.get(key), dict):
            result[key] = _deep_merge(result[key], val)
        else:
            result[key] = val
    return result


def _merged_config() -> dict:
    """Return defaults merged with user overlay (project overlay added later)."""
    defaults = _load_yaml(_plugin_dir() / "config.defaults.yaml")
    user = _load_yaml(_user_config_path())
    return _deep_merge(defaults, user)
```

Then change `cmd_get` to use `_merged_config()`:

```python
def cmd_get(args: list[str]) -> int:
    if not args:
        print("usage: config.py get <dotted.key>", file=sys.stderr)
        return 2
    key = args[0]
    value = _get(_merged_config(), key)
    if value is None:
        print(f"key not defined: {key}", file=sys.stderr)
        return 1
    print(_format(value))
    return 0
```

- [ ] **Step 4: Run all tests to verify pass + no regression**

```bash
python3 -m pytest tests/test_config.py -v
```

Expected: all five tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/config.py tests/test_config.py
git commit -m "feat(#22): user-global overlay with deep merge"
```

---

## Task 8: Test + implement project overlay (highest precedence)

**Files:**
- Modify: `lib/config.py`
- Test: `tests/test_config.py` (append)

- [ ] **Step 1: Write the failing tests**

```python
def test_project_overlay_overrides_user(cli, user_config_dir, project_cwd):
    (user_config_dir / "config.yaml").write_text("pilot_version: 1\n")
    (project_cwd / ".laravel-superpowers.yaml").write_text("pilot_version: 2\n")
    result = cli("get", "pilot_version")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "2"


def test_deep_merge_preserves_uninherited_sibling_keys(cli, project_cwd):
    """Overriding one hook_enabled key must leave the others intact."""
    (project_cwd / ".laravel-superpowers.yaml").write_text(
        "hook_enabled:\n  banned_token_leak_guard: false\n"
    )
    a = cli("get", "hook_enabled.banned_token_leak_guard")
    assert a.stdout.strip() == "false"
    b = cli("get", "hook_enabled.no_claude_attribution")
    assert b.stdout.strip() == "true"   # inherited from defaults
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
python3 -m pytest tests/test_config.py::test_project_overlay_overrides_user tests/test_config.py::test_deep_merge_preserves_uninherited_sibling_keys -v
```

Expected: both FAIL.

- [ ] **Step 3: Add project-overlay to `_merged_config`**

In `lib/config.py`:

```python
def _project_config_path() -> Path:
    return Path.cwd() / ".laravel-superpowers.yaml"


def _merged_config() -> dict:
    """Return defaults merged with user overlay, then project overlay."""
    defaults = _load_yaml(_plugin_dir() / "config.defaults.yaml")
    user = _load_yaml(_user_config_path())
    project = _load_yaml(_project_config_path())
    return _deep_merge(_deep_merge(defaults, user), project)
```

- [ ] **Step 4: Run all tests**

```bash
python3 -m pytest tests/test_config.py -v
```

Expected: all seven tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/config.py tests/test_config.py
git commit -m "feat(#22): project overlay with deep-merge precedence"
```

---

## Task 9: Test + implement `validate` subcommand

**Files:**
- Modify: `lib/config.py`
- Test: `tests/test_config.py` (append)

- [ ] **Step 1: Write the failing tests**

```python
def test_validate_defaults_passes(cli):
    result = cli("validate")
    assert result.returncode == 0, result.stderr


def test_validate_unknown_top_level_key_fails(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text("totally_made_up: yes\n")
    result = cli("validate")
    assert result.returncode == 3
    assert "totally_made_up" in result.stderr


def test_validate_wrong_type_fails(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text("pilot_version: nope\n")
    result = cli("validate")
    assert result.returncode == 3


def test_validate_unknown_hook_enabled_subkey_passes(cli, project_cwd):
    """Sub-keys under hook_enabled are open (additionalProperties: boolean)."""
    (project_cwd / ".laravel-superpowers.yaml").write_text(
        "hook_enabled:\n  some_future_hook: true\n"
    )
    result = cli("validate")
    assert result.returncode == 0, result.stderr
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
python3 -m pytest tests/test_config.py::test_validate_defaults_passes -v
```

Expected: FAIL (`unknown verb: validate`).

- [ ] **Step 3: Implement `cmd_validate`**

Add to `lib/config.py`:

```python
def _load_schema() -> dict:
    import json
    return json.load(open(_plugin_dir() / "config.schema.json"))


def cmd_validate(args: list[str]) -> int:
    """Validate one config file (path arg) or all three layers (no args)."""
    from jsonschema import validate as js_validate, ValidationError

    schema = _load_schema()

    if args:
        paths = [Path(args[0])]
    else:
        paths = [
            _plugin_dir() / "config.defaults.yaml",
            _user_config_path(),
            _project_config_path(),
        ]

    had_error = False
    for path in paths:
        if not path.exists():
            continue
        try:
            data = _load_yaml(path)
        except yaml.YAMLError as e:
            print(f"YAML parse error in {path}: {e}", file=sys.stderr)
            had_error = True
            continue
        try:
            js_validate(data, schema)
        except ValidationError as e:
            location = ".".join(str(p) for p in e.absolute_path) or "<root>"
            print(f"schema violation in {path} at {location}: {e.message}", file=sys.stderr)
            had_error = True

    return 3 if had_error else 0
```

Update `main()` to dispatch `validate`:

```python
def main() -> int:
    if len(sys.argv) < 2:
        print("usage: config.py <get|show|validate|init|doctor> [args]", file=sys.stderr)
        return 2
    verb, *rest = sys.argv[1:]
    dispatch = {"get": cmd_get, "validate": cmd_validate}
    if verb not in dispatch:
        print(f"unknown verb: {verb}", file=sys.stderr)
        return 2
    return dispatch[verb](rest)
```

- [ ] **Step 4: Run all tests**

```bash
python3 -m pytest tests/test_config.py -v
```

Expected: all eleven tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/config.py tests/test_config.py
git commit -m "feat(#22): validate subcommand with JSON Schema"
```

---

## Task 10: Test + implement `show` subcommand with source annotation

**Files:**
- Modify: `lib/config.py`
- Test: `tests/test_config.py` (append)

- [ ] **Step 1: Write the failing tests**

```python
def test_show_outputs_yaml_with_source_comments(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text("pilot_version: 1\n")
    result = cli("show")
    assert result.returncode == 0, result.stderr
    # Each top-level key gets a [defaults|user|project] tag
    assert "pilot_version: 1  # [user]" in result.stdout
    assert "audit_aggressiveness: every-phase  # [defaults]" in result.stdout


def test_show_marks_project_keys(cli, user_config_dir, project_cwd):
    (project_cwd / ".laravel-superpowers.yaml").write_text("tier_preference: all\n")
    result = cli("show")
    assert "tier_preference: all  # [project]" in result.stdout
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL (`unknown verb: show`).

- [ ] **Step 3: Implement `cmd_show`**

Add to `lib/config.py`:

```python
def _source_of(key: str, defaults: dict, user: dict, project: dict) -> str:
    """Which layer is the highest source of a top-level key?"""
    if key in project:
        return "project"
    if key in user:
        return "user"
    if key in defaults:
        return "defaults"
    return "unknown"


def cmd_show(_args: list[str]) -> int:
    """Print merged config as YAML, annotating each top-level key's source."""
    defaults = _load_yaml(_plugin_dir() / "config.defaults.yaml")
    user = _load_yaml(_user_config_path())
    project = _load_yaml(_project_config_path())
    merged = _deep_merge(_deep_merge(defaults, user), project)

    for key in merged:
        source = _source_of(key, defaults, user, project)
        rendered = yaml.safe_dump({key: merged[key]}, default_flow_style=False).rstrip()
        # If it's a scalar, append the comment on the same line.
        # If it's a dict/list, prepend the comment on its own line above.
        if "\n" in rendered:
            print(f"# [{source}]")
            print(rendered)
        else:
            print(f"{rendered}  # [{source}]")
    return 0
```

Add to dispatch in `main()`:
```python
dispatch = {"get": cmd_get, "validate": cmd_validate, "show": cmd_show}
```

- [ ] **Step 4: Run all tests**

```bash
python3 -m pytest tests/test_config.py -v
```

Expected: all thirteen tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/config.py tests/test_config.py
git commit -m "feat(#22): show subcommand annotates each key with its source layer"
```

---

## Task 11: Test + implement `init` subcommand

**Files:**
- Modify: `lib/config.py`
- Test: `tests/test_config.py` (append)

- [ ] **Step 1: Write the failing tests**

```python
def test_init_creates_user_config_with_commented_defaults(cli, user_config_dir):
    target = user_config_dir / "config.yaml"
    # Fixture creates the dir but not the file; init should write it.
    assert not target.exists()
    result = cli("init")
    assert result.returncode == 0, result.stderr
    assert target.exists()
    content = target.read_text()
    # All values commented out except the schema pointer
    assert "yaml-language-server" in content
    assert "# pilot_version: 2" in content


def test_init_refuses_overwrite_without_force(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text("pilot_version: 1\n")
    result = cli("init")
    assert result.returncode == 2
    assert "exists" in result.stderr.lower()


def test_init_force_overwrites(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text("pilot_version: 1\n")
    result = cli("init", "--force")
    assert result.returncode == 0
    content = (user_config_dir / "config.yaml").read_text()
    assert "yaml-language-server" in content


def test_init_project_creates_local_yaml(cli, project_cwd):
    result = cli("init", "--project")
    assert result.returncode == 0
    assert (project_cwd / ".laravel-superpowers.yaml").exists()
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL (`unknown verb: init`).

- [ ] **Step 3: Implement `cmd_init`**

Add to `lib/config.py`:

```python
SCHEMA_POINTER = "# yaml-language-server: $schema=https://raw.githubusercontent.com/altraWeb/laravel-superpowers/main/config.schema.json\n"


def _init_template() -> str:
    """Return the contents to seed a new user/project config file with."""
    defaults_text = (_plugin_dir() / "config.defaults.yaml").read_text()
    # Comment out every non-comment, non-blank line so the file is a no-op
    # by default. User uncomments what they want to override.
    body_lines = []
    for line in defaults_text.splitlines():
        stripped = line.strip()
        if stripped == "" or stripped.startswith("#"):
            body_lines.append(line)
        else:
            body_lines.append(f"# {line}")
    return SCHEMA_POINTER + "\n".join(body_lines) + "\n"


def cmd_init(args: list[str]) -> int:
    project_mode = "--project" in args
    force = "--force" in args
    if project_mode:
        target = _project_config_path()
    else:
        target = _user_config_path()
        target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() and not force:
        print(f"config already exists: {target} (use --force to overwrite)", file=sys.stderr)
        return 2
    target.write_text(_init_template())
    print(f"wrote {target}")
    return 0
```

Add to dispatch:
```python
dispatch = {"get": cmd_get, "validate": cmd_validate, "show": cmd_show, "init": cmd_init}
```

- [ ] **Step 4: Run all tests**

```bash
python3 -m pytest tests/test_config.py -v
```

Expected: all seventeen tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/config.py tests/test_config.py
git commit -m "feat(#22): init subcommand scaffolds commented user/project config"
```

---

## Task 12: Test + implement `doctor` subcommand

**Files:**
- Modify: `lib/config.py`
- Test: `tests/test_config.py` (append)

- [ ] **Step 1: Write the failing tests**

```python
def test_doctor_lists_found_configs(cli, user_config_dir, project_cwd):
    (user_config_dir / "config.yaml").write_text("pilot_version: 1\n")
    (project_cwd / ".laravel-superpowers.yaml").write_text("tier_preference: all\n")
    result = cli("doctor")
    assert result.returncode == 0, result.stderr
    assert "defaults" in result.stdout
    assert str(user_config_dir / "config.yaml") in result.stdout
    assert str(project_cwd / ".laravel-superpowers.yaml") in result.stdout
    assert "schema validation: ok" in result.stdout


def test_doctor_reports_schema_failure(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text("pilot_version: nope\n")
    result = cli("doctor")
    assert "schema validation: FAIL" in result.stdout
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL (`unknown verb: doctor`).

- [ ] **Step 3: Implement `cmd_doctor`**

Add to `lib/config.py`:

```python
def cmd_doctor(_args: list[str]) -> int:
    """Print diagnostic info: found configs, schema status, recent errors."""
    paths = [
        ("defaults", _plugin_dir() / "config.defaults.yaml"),
        ("user", _user_config_path()),
        ("project", _project_config_path()),
    ]
    print("=== Configs ===")
    for label, path in paths:
        exists = "found" if path.exists() else "absent"
        print(f"  [{label}] {path} — {exists}")

    print("\n=== Schema validation ===")
    rc = cmd_validate([])
    print(f"  schema validation: {'ok' if rc == 0 else 'FAIL'}")

    errors_log = _user_config_path().parent / "errors.log"
    print("\n=== Recent errors (last 20 lines) ===")
    if errors_log.exists():
        lines = errors_log.read_text().splitlines()
        for line in lines[-20:]:
            print(f"  {line}")
    else:
        print(f"  (no errors.log at {errors_log})")
    return 0
```

Add to dispatch:
```python
dispatch = {"get": cmd_get, "validate": cmd_validate, "show": cmd_show, "init": cmd_init, "doctor": cmd_doctor}
```

- [ ] **Step 4: Run all tests**

```bash
python3 -m pytest tests/test_config.py -v
```

Expected: all nineteen tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/config.py tests/test_config.py
git commit -m "feat(#22): doctor subcommand for diagnostics"
```

---

## Task 13: Test + implement defensive YAML parse error handling

**Files:**
- Modify: `lib/config.py` — `_load_yaml` should raise typed error; callers convert to exit 3
- Test: `tests/test_config.py` (append)

- [ ] **Step 1: Write the failing tests**

```python
def test_get_with_broken_user_yaml_falls_back_to_defaults(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text(":::not valid yaml:::\n")
    result = cli("get", "pilot_version")
    # Falls back to default value, but writes WARN to stderr
    assert result.returncode == 0
    assert result.stdout.strip() == "2"
    assert "YAML parse error" in result.stderr


def test_validate_with_broken_yaml_returns_3(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text(":::not valid yaml:::\n")
    result = cli("validate")
    assert result.returncode == 3
    assert "YAML parse error" in result.stderr
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
python3 -m pytest tests/test_config.py::test_get_with_broken_user_yaml_falls_back_to_defaults -v
```

Expected: FAIL (parse error crashes or returns wrong code).

- [ ] **Step 3: Make `_load_yaml` resilient + warn**

Replace `_load_yaml` in `lib/config.py`:

```python
def _load_yaml(path: Path, warn: bool = True) -> dict:
    """Load a YAML file. Returns empty dict if missing or unparseable.

    When `warn` is True (default), prints a WARN to stderr on parse error
    so the caller can degrade gracefully without surprising the operator.
    """
    if not path.exists():
        return {}
    try:
        with open(path) as f:
            return yaml.safe_load(f) or {}
    except yaml.YAMLError as e:
        if warn:
            print(f"WARN: YAML parse error in {path}: {e}", file=sys.stderr)
        return {}
```

For `cmd_validate`, parse errors should still produce exit 3 — keep its own try/except:

In `cmd_validate`, replace the `_load_yaml(path)` call with a strict reload:
```python
        try:
            with open(path) as f:
                data = yaml.safe_load(f) or {}
        except yaml.YAMLError as e:
            print(f"YAML parse error in {path}: {e}", file=sys.stderr)
            had_error = True
            continue
```

- [ ] **Step 4: Run all tests**

```bash
python3 -m pytest tests/test_config.py -v
```

Expected: all twenty-one tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/config.py tests/test_config.py
git commit -m "feat(#22): defensive YAML parsing — fall back + warn on broken overlay"
```

---

## Task 14: Hook-integration shell test

**Files:**
- Create: `tests/test_hook_integration.sh`

- [ ] **Step 1: Write the integration test**

```bash
#!/usr/bin/env bash
# Hook-integration smoke test: simulates a hook reading config the way #16-21 will.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$REPO_DIR"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"
export HOME="$TMP_HOME"

# Case 1: defaults — pilot_version should be 2
val=$(python3 "$PLUGIN_DIR/lib/config.py" get pilot_version)
[ "$val" = "2" ] || { echo "FAIL case 1: expected 2, got '$val'"; exit 1; }

# Case 2: user overlay
mkdir -p "$HOME/.claude/plugins/altraweb-laravel/laravel-superpowers"
echo "pilot_version: 1" > "$HOME/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml"
val=$(python3 "$PLUGIN_DIR/lib/config.py" get pilot_version)
[ "$val" = "1" ] || { echo "FAIL case 2: expected 1, got '$val'"; exit 1; }

# Case 3: hook fail-open — broken yaml + key fallback in shell
echo ":::broken:::" > "$HOME/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml"
val=$(python3 "$PLUGIN_DIR/lib/config.py" get hook_enabled.banned_token_leak_guard 2>/dev/null || echo "true")
[ "$val" = "true" ] || { echo "FAIL case 3: expected true, got '$val'"; exit 1; }

# Case 4: missing python deps simulation — shell fallback works
val=$(false 2>/dev/null || echo "fallback-default")
[ "$val" = "fallback-default" ] || { echo "FAIL case 4"; exit 1; }

echo "all hook-integration cases pass"
```

- [ ] **Step 2: Make executable and run**

```bash
chmod +x tests/test_hook_integration.sh
bash tests/test_hook_integration.sh
```

Expected: `all hook-integration cases pass`.

- [ ] **Step 3: Commit**

```bash
git add tests/test_hook_integration.sh
git commit -m "test(#22): hook-integration shell smoke test"
```

---

## Task 15: Write `docs/config.md`

**Files:**
- Create: `docs/config.md`

- [ ] **Step 1: Write the docs**

```markdown
# Plugin Configuration Reference

`laravel-superpowers` reads YAML config from three layers (lowest to highest precedence):

| Layer | Path | When to use |
|---|---|---|
| Defaults | `<plugin>/config.defaults.yaml` | Baked in — do not edit |
| User-global | `~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml` | Per-machine preferences |
| Per-project | `<project>/.laravel-superpowers.yaml` | Per-repo overrides |

Override hierarchy is **deep recursive**: nested keys (e.g. `hook_enabled.banned_token_leak_guard`) can be overridden individually without repeating the surrounding block.

## Prerequisites

The helper needs Python 3.10+ with `PyYAML` and `jsonschema`:

```bash
pip3 install --user --break-system-packages pyyaml jsonschema
```

(macOS Homebrew Python uses PEP 668 — the `--break-system-packages` flag is required.)

## Quickstart

```bash
# Show effective merged config
python3 <plugin>/lib/config.py show

# Scaffold a user-global config you can edit
python3 <plugin>/lib/config.py init

# Scaffold a project-local config
python3 <plugin>/lib/config.py init --project

# Validate your config against the schema
python3 <plugin>/lib/config.py validate

# Diagnose problems
python3 <plugin>/lib/config.py doctor
```

## Keys

### `pilot_version` — integer, one of `1`, `2`, default `2`

Pilot contract version. `1` = audits optional, `2` = audits are binding hard-gates.

### `hook_enabled.<hook_name>` — boolean, default `true`

Per-hook enable/disable. Set a specific hook to `false` to no-op it without affecting others. Sub-keys here are open — future hooks can opt in without a schema update.

Currently shipped hook names:
- `banned_token_leak_guard` (#16)
- `no_claude_attribution` (#17)
- `teamcity_always` (#18)
- `anti_silent_deferral` (#19)
- `brainstorm_t1_audit` (#20)
- `visual_companion_default_on` (#21)

### `audit_aggressiveness` — string, one of `every-phase | every-commit | brainstorm-only`, default `every-phase`

When the Tier-1 audit hook auto-dispatches.

### `banned_tokens.project_extras` — list of strings, default `[]`

Additional tokens the banned-token-leak-guard hook should reject. Example:

```yaml
banned_tokens:
  project_extras:
    - "AcmeCorp"
    - "INT-1234"
```

### `banned_tokens.exception_paths` — list of glob strings

Paths where banned tokens are tolerated. Defaults include `docs/plans/**`, `docs/superpowers/**`, `CHANGELOG.md`.

### `visual_companion_default` — string, one of `on | off | ask`, default `on`

Default for the brainstorming skill's visual companion offer.

### `tier_preference` — string, one of `T1-only | T1+T2 | all`, default `T1+T2`

Which roadmap tiers to surface in auto-suggestions.

### `teamcity_always` — boolean, default `true`

Whether to always pass `--teamcity` to `php artisan test` for parsable output.

## IDE autocomplete

User and project configs can add a schema pointer as their first line:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/altraWeb/laravel-superpowers/main/config.schema.json
```

VSCode with the YAML extension and Zed pick this up automatically and provide completion + inline validation.

## Examples

### Disable one hook in one project

```yaml
# ./.laravel-superpowers.yaml
hook_enabled:
  banned_token_leak_guard: false
```

All other `hook_enabled` keys inherit from user-global or defaults.

### Add project-specific banned tokens

```yaml
# ./.laravel-superpowers.yaml
banned_tokens:
  project_extras:
    - "AcmeCorp"
    - "INT-1234"
```

### Globally prefer the all-tier suggestion set

```yaml
# ~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml
tier_preference: all
```
```

- [ ] **Step 2: Commit**

```bash
git add docs/config.md
git commit -m "docs(#22): user-facing config reference"
```

---

## Task 16: Update root `README.md` with Configuration section

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read the current README**

Run:
```bash
cat README.md
```

- [ ] **Step 2: Add a "Configuration" section before the "Skills" section**

Insert (the exact placement depends on current structure — put it after "Install"):

```markdown
## Configuration

Per-user and per-project settings via YAML. See [`docs/config.md`](docs/config.md) for the full reference.

```bash
# Scaffold a user-global config you can edit
python3 <plugin>/lib/config.py init

# See effective merged config with source attribution
python3 <plugin>/lib/config.py show
```

Requires Python 3.10+ with `pyyaml` and `jsonschema`. On Homebrew Python:

```bash
pip3 install --user --break-system-packages pyyaml jsonschema
```
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(#22): README points to plugin config foundation"
```

---

## Task 17: Final full-suite run + PR readiness check

- [ ] **Step 1: Run the entire test suite**

```bash
python3 -m pytest tests/test_config.py -v && bash tests/test_hook_integration.sh
```

Expected: all 21 pytest cases pass + hook-integration script reports `all hook-integration cases pass`.

- [ ] **Step 2: Validate defaults + schema end-to-end**

```bash
python3 lib/config.py validate
```

Expected: exit 0, no output.

- [ ] **Step 3: Sanity-check `show` against the canonical defaults**

```bash
python3 lib/config.py show
```

Expected: every top-level key annotated `# [defaults]` (assumes no user/project config present locally).

- [ ] **Step 4: Confirm git status is clean**

```bash
git status
```

Expected: `nothing to commit, working tree clean`.

- [ ] **Step 5: Push branch + flip Draft PR #32 to ready-for-review**

```bash
git push
```

Then via GitHub web UI or `gh`:
```bash
gh pr ready 32
```

(The spec PR #32 will be expanded with the implementation. Alternatively, this implementation can land on its own branch + separate PR — see Execution Handoff below.)

---

## Self-Review Notes

**Spec coverage:**
- All §1–9 of the spec are covered by tasks above
- §10 open questions (auto-detect plugin dir, errors.log rotation, validate short-circuit) intentionally deferred — captured below for follow-up tickets if they matter

**Deferred items (not blocking #22 acceptance):**
- `errors.log` rotation/cleanup — could add a `doctor --clear-log` flag later; for now log grows unbounded
- `validate` short-circuit vs walk-all — current implementation walks all, accumulates errors, exits 3 if any
- Auto-detect plugin dir from `$0` — current implementation uses `$CLAUDE_PLUGIN_ROOT` with fallback to script location; sufficient for the hook integration pattern

**Placeholder scan:** none — every step contains actual code or commands.

**Type consistency:**
- `_merged_config()` used in Tasks 7, 8, 10 — same signature throughout
- `_deep_merge(base, overlay)` — `base` always defaults-side, `overlay` always higher-precedence-side
- `cmd_*` functions all return `int` exit code

**Schema/code sync:** `config.defaults.yaml` (Task 2) and `config.schema.json` (Task 3) covered by Task 3 sanity check + the `test_validate_defaults_passes` test in Task 9.

---

## Execution Handoff

**Two execution options:**

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks. Fast iteration, clean per-task context.

2. **Inline Execution** — I execute tasks in this session using executing-plans. Batch execution with checkpoints for your review.

Which approach?
