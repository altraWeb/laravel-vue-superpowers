"""Tests for lib/config.py."""


def test_get_returns_default_value(cli):
    """With no user/project overlay, `get` returns the default."""
    result = cli("get", "pilot_version")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "2"


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


def test_user_overlay_overrides_default(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text("pilot_version: 1\n")
    result = cli("get", "pilot_version")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "1"


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


def test_get_with_broken_user_yaml_falls_back_to_defaults(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text("key: {broken yaml\n")
    result = cli("get", "pilot_version")
    # Falls back to default value, but writes WARN to stderr
    assert result.returncode == 0
    assert result.stdout.strip() == "2"
    assert "YAML parse error" in result.stderr


def test_validate_with_broken_yaml_returns_3(cli, user_config_dir):
    (user_config_dir / "config.yaml").write_text("key: {broken yaml\n")
    result = cli("validate")
    assert result.returncode == 3
    assert "YAML parse error" in result.stderr


def test_get_with_yaml_list_overlay_falls_back_safely(cli, user_config_dir):
    """A user config that is a YAML list (not a mapping) must not crash deep_merge."""
    (user_config_dir / "config.yaml").write_text("- not\n- a\n- mapping\n")
    result = cli("get", "pilot_version")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "2"  # falls back to defaults
    assert "expected mapping" in result.stderr


def test_warn_appends_to_errors_log(cli, user_config_dir):
    """YAML parse warnings are appended to errors.log for `doctor` to surface."""
    (user_config_dir / "config.yaml").write_text("key: {broken yaml\n")
    cli("get", "pilot_version")  # triggers parse error + warn
    errors_log = user_config_dir / "errors.log"
    assert errors_log.exists()
    content = errors_log.read_text()
    assert "YAML parse error" in content


def test_get_sprint_state_context_injection_default(cli):
    """New B-phase hook flag defaults to true."""
    result = cli("get", "hook_enabled.sprint_state_context_injection")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "true"


def test_get_stale_branch_sweep_auto_prune_default(cli):
    """Auto-prune opt-in defaults to false."""
    result = cli("get", "stale_branch_sweep.auto_prune")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "false"


def test_get_pilot_2_contract_enforcer_default(cli):
    """Phase E enforcer hook flag defaults to true."""
    result = cli("get", "hook_enabled.pilot_2_contract_enforcer")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "true"


def test_get_vendor_source_preflight_default(cli):
    result = cli("get", "hook_enabled.vendor_source_preflight")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "true"


def test_get_lang_key_existence_preflight_default(cli):
    result = cli("get", "hook_enabled.lang_key_existence_preflight")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "true"
