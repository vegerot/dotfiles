# Codex configuration

🔧 `~/.codex/config.toml` links directly to this directory's `config.toml` on
macOS, Windows, and GNU+Linux. Edit either path; no generation or sync command
is needed. Restart Codex to load configuration changes.

The Unix bootstrap links this file like the other dotfiles. Existing machines
using a generated config need a one-time switch: save the current config,
carry over settings to keep, and replace the active link with a link to
`dotfiles/.codex/config.toml`. The old generated file is then unused.

Codex can write preferences, project trust records, and application settings
into this shared file. Review those changes before committing them.

Tool commands are resolved from `PATH`. All configured tools remain enabled;
computers without a command may show a startup warning. Chrome launch and
attach modes keep separate entries and use the default Chrome Dev profile.
Chrome file logging is disabled by omitting `--log-file`.

Agent instructions and `hooks.json` remain shared through symlinks.
