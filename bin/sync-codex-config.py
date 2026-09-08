# /// script
# requires-python = ">=3.11"
# dependencies = ["tomlkit>=0.13,<1"]
# ///
"""Apply shared Codex preferences while preserving local application state."""

import argparse
from collections.abc import Mapping
from datetime import datetime
import os
from pathlib import Path
import shutil
import sys
import tempfile

import tomlkit


def merge(target, source):
    for key, value in source.items():
        if isinstance(value, Mapping) and isinstance(target.get(key), Mapping):
            merge(target[key], value)
        else:
            target[key] = value


def build_config(shared, local, *, platform, home, environ, which, temp_dir):
    result = tomlkit.parse(tomlkit.dumps(local))
    preferences = tomlkit.parse(tomlkit.dumps(shared))
    servers = preferences.pop("mcp_servers", {})
    skill_overrides = preferences.pop("skills", {}).get("config", [])
    merge(result, preferences)
    result.get("features", {}).pop("js_repl", None)
    result.get("tui", {}).pop("terminal_resize_reflow_max_rows", None)

    skills = result.setdefault("skills", {})
    # Replace the old path selector without dropping unrelated local overrides.
    skills["config"] = [
        entry for entry in skills.get("config", [])
        if entry.get("name") != "coco-export-location"
        and "coco-export-location" not in str(entry.get("path", "")).replace("\\", "/").split("/")
    ] + list(skill_overrides)

    if platform == "win32":
        cache = Path(environ.get("LOCALAPPDATA", home / "AppData/Local"))
    elif platform == "darwin":
        cache = home / "Library/Caches"
    else:
        cache = Path(environ.get("XDG_CACHE_HOME", home / ".cache"))
    paths = {"cache_dir": cache.as_posix(), "temp_dir": Path(temp_dir).as_posix()}
    local_servers = result.setdefault("mcp_servers", {})
    for name, server in servers.items():
        command = server["command"]
        installed = which(command)
        if name == "dayflow" and not installed and platform == "darwin":
            app = Path("/Applications/Dayflow.app/Contents/Helpers/dayflow")
            if app.is_file():
                command = str(app)
                installed = command
        server["command"] = command
        server["args"] = [arg.format_map(paths) for arg in server.get("args", [])]
        server["enabled"] = bool(installed)
        local_servers[name] = server
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check without writing files.")
    args = parser.parse_args()
    shared_path = Path(__file__).resolve().parents[1] / ".codex/config.toml"
    codex_home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    local_path = codex_home / "config.toml"
    generated_path = shared_path.parent / "local/config.toml"
    shared = tomlkit.parse(shared_path.read_text(encoding="utf-8-sig"))
    old_text = local_path.read_text(encoding="utf-8-sig") if local_path.exists() else ""
    updated = build_config(
        shared, tomlkit.parse(old_text), platform=sys.platform, home=Path.home(),
        environ=os.environ, which=shutil.which, temp_dir=tempfile.gettempdir(),
    )
    new_text = tomlkit.dumps(updated)
    linked = local_path.is_symlink() and local_path.resolve() == generated_path.resolve()
    if tomlkit.parse(old_text).unwrap() == updated.unwrap() and linked:
        print("Codex configuration is current.")
        return
    if args.check:
        print("Codex configuration needs syncing.")
        raise SystemExit(1)
    codex_home.mkdir(parents=True, exist_ok=True)
    generated_path.parent.mkdir(parents=True, exist_ok=True)
    if local_path.exists():
        backup = local_path.with_name("config.toml.before-sync-" + datetime.now().strftime("%Y%m%d-%H%M%S-%f") + ".bak")
        shutil.copyfile(local_path, backup)
        print(f"Backup: {backup}")
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", newline="\n", dir=generated_path.parent, delete=False) as output:
        output.write(new_text)
        temporary_path = Path(output.name)
    temporary_path.replace(generated_path)
    if not linked:
        # Create the replacement first so a symlink permission error leaves the active file intact.
        replacement_link = codex_home / ("config-link-" + datetime.now().strftime("%Y%m%d-%H%M%S-%f"))
        replacement_link.symlink_to(generated_path)
        replacement_link.replace(local_path)
    print(f"Updated: {local_path} -> {generated_path}")
    for name in shared.get("mcp_servers", {}):
        enabled = updated["mcp_servers"][name]["enabled"]
        print(f"{name}: {'enabled' if enabled else 'disabled (executable not installed)'}")


if __name__ == "__main__":
    main()
