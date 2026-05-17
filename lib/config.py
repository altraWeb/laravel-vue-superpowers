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


def _errors_log_path() -> Path:
    return _user_config_path().parent / "errors.log"


def _warn(message: str) -> None:
    """Print a WARN to stderr and append it to the user-global errors.log."""
    print(f"WARN: {message}", file=sys.stderr)
    log_path = _errors_log_path()
    try:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with open(log_path, "a") as f:
            f.write(f"{message}\n")
    except OSError:
        pass  # errors.log itself failing must not break hooks


def _load_yaml(path: Path, warn: bool = True) -> dict:
    """Load a YAML file. Returns empty dict if missing, unparseable, or not a mapping.

    When `warn` is True (default), warns via stderr + appends to errors.log
    so the caller can degrade gracefully without surprising the operator.
    """
    if not path.exists():
        return {}
    try:
        with open(path) as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        if warn:
            _warn(f"YAML parse error in {path}: {e}")
        return {}
    if data is None:
        return {}
    if not isinstance(data, dict):
        if warn:
            _warn(f"YAML in {path} is {type(data).__name__}, expected mapping — ignored")
        return {}
    return data


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


def _user_config_path() -> Path:
    """Return the user-global config path.

    Note: path uses `laravel-superpowers` (the V2 plugin name), not
    `laravel-livewire-superpowers` (V3 name). This is intentional — preserved
    across the V3 rename so existing V2 users' configs continue to apply
    without migration. See V3 design spec Section 8.
    """
    return Path(os.environ["HOME"]) / ".claude" / "plugins" / "altraweb-laravel" / "laravel-superpowers" / "config.yaml"


def _project_config_path() -> Path:
    """Return the per-project config path.

    Note: filename uses `.laravel-superpowers.yaml` (the V2 plugin name), not
    `.laravel-livewire-superpowers.yaml` (V3 name). This is intentional — preserved
    across the V3 rename so existing V2 users' per-project configs continue to apply
    without migration. See V3 design spec Section 8.
    """
    return Path.cwd() / ".laravel-superpowers.yaml"


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
    """Return defaults merged with user overlay, then project overlay."""
    defaults = _load_yaml(_plugin_dir() / "config.defaults.yaml")
    user = _load_yaml(_user_config_path())
    project = _load_yaml(_project_config_path())
    return _deep_merge(_deep_merge(defaults, user), project)


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
            with open(path) as f:
                data = yaml.safe_load(f) or {}
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


def _source_of(key: str, defaults: dict, user: dict, project: dict) -> str:
    """Which layer is the highest source of a top-level key?"""
    if key in project:
        return "project"
    if key in user:
        return "user"
    if key in defaults:
        return "defaults"
    return "unknown"


# SCHEMA_POINTER: URL uses the V3 plugin name (laravel-livewire-superpowers). See V3 design spec Section 8.
SCHEMA_POINTER = "# yaml-language-server: $schema=https://raw.githubusercontent.com/altraWeb/laravel-livewire-superpowers/main/config.schema.json\n"


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


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: config.py <get|show|validate|init|doctor> [args]", file=sys.stderr)
        return 2
    verb, *rest = sys.argv[1:]
    dispatch = {"get": cmd_get, "validate": cmd_validate, "show": cmd_show, "init": cmd_init, "doctor": cmd_doctor}
    if verb not in dispatch:
        print(f"unknown verb: {verb}", file=sys.stderr)
        return 2
    return dispatch[verb](rest)


if __name__ == "__main__":
    sys.exit(main())
