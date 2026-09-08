# Codex configuration

🔧 `config.toml` stores shared preferences for macOS, Windows, and GNU+Linux.
The active `~/.codex/config.toml` links to `dotfiles/.codex/local/config.toml`.
This generated file is untracked and contains this machine's runtime settings.

After changing the shared preferences or installing an optional tool, run:

```text
uv run bin/sync-codex-config.py
```

Run this command from the dotfiles repository. Install `uv` first.
Use `--check` to check whether a sync is needed without writing files.
The Unix bootstrap runs the sync after installing links.

The sync preserves existing local runtime settings, notification helpers,
plugin cache locations, project trust, and hook approval state.
It saves a backup before each change.
It creates the active symlink and preserves it during later syncs.

Shared preferences override matching local preferences.
Each shared tool server replaces its local definition.
Other local tool servers remain unchanged.
Executable detection enables installed tools and disables absent tools.
Dayflow also supports its standard macOS application location.

The script expands `{cache_dir}` and `{temp_dir}` in shared tool arguments.
These are sync placeholders, not Codex configuration variables.
Chrome launch and attach modes keep separate definitions.
The existing `chrome_devtools` entry also remains available.

Application runtime settings are supplied locally by the Codex application.
On a new machine, start the application to configure its runtime integrations.
Before updating an older installation that links directly to dotfiles,
save its active configuration locally so its runtime settings remain available.

Keybindings and `hooks.json` remain shared through symlinks.
