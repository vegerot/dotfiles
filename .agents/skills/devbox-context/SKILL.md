---
name: devbox-context
description: Explain Codex and Claude Code connections to Max's ByteDance Linux devbox. Use shared machine context plus only the active agent's section for Codex CLI/desktop SSH/Remote Control, or Claude CLI/desktop SSH/Remote Control and cl bridge sessions. Use for questions such as "how am I connected right now", "explain this is the devbox", or a recap of the connection setup.
---

# Devbox connection context

## Choose the active agent

Use the identity of the agent running this session, as given by the session
context. Read and apply **Shared context** plus **Codex only** when running
as Codex, or **Shared context** plus **Claude Code only** when running as
Claude Code.

## Shared context

This is Max's ByteDance Linux devbox (`machine: devbox` in the
`ai-conversations` archive). Its home is `/data00/home/max.coplan`;
`/home/max.coplan` also resolves there. Identify the execution machine,
client interface, and transport separately. A desktop interface on the Mac
can control an agent whose shell and workspace are on Linux.

Run this read-only snapshot on the execution host, then run only the
additional snapshot in the active agent's section:

```bash
printf 'hostname: %s\npwd: %s\n' "$(hostname)" "$PWD"
printf 'SSH_CONNECTION: %s\n' "${SSH_CONNECTION:-<unset>}"
printf 'TMUX: %s\n' "${TMUX:-<unset>}"
if [ -n "${TMUX:-}" ]; then
    tmux display-message -p '#S:#W'
fi
```

`SSH_CONNECTION` can be inherited from a daemon's startup shell and remain
set after setup SSH disconnects. Its presence or absence does not identify
the current client transport. `TMUX` identifies a tmux environment, not the
client transport or agent; do not assume every SSH session belongs to `cl`.
If the available evidence cannot identify the client transport, state the
execution host and server facts and leave the transport uncertain.

SSH historically required Kerberos. The August setup later enabled public-key
authentication specifically for `max.coplan` so Claude Desktop SSH could
connect; do not repeat the old "Kerberos-only, no key auth" claim as current
fact. Inspect effective SSH configuration when authentication is relevant.
The connecting Mac is the archive's `work-macbook`.

Archive references below are relative to
`~/code/github.com/vegerot/ai-conversations/`. For the shared authentication
history, see `devbox/connect-from-mac.md`. Treat dated observations as
history; verify live state before describing versions, process ownership,
or connectivity as current.

## Codex only

### Three main Codex connection paths

| Path | How the client reaches the devbox | Where commands run |
|---|---|---|
| **SSH + Codex CLI** | Mac terminal → SSH → devbox shell → `codex` terminal interface | Devbox |
| **SSH through the ChatGPT desktop app** | Codex in ChatGPT desktop → SSH connection/proxy → devbox App Server | Devbox |
| **Remote Control through the ChatGPT desktop/mobile app** | Codex in ChatGPT desktop → OpenAI relay → devbox App Server with Remote Control enabled | Devbox |

The **App Server** is the Codex process that owns tasks and runs tools.
The terminal CLI can reuse a background App Server too; a terminal launch
does not prove that tools are children of the visible terminal process.
These paths can coexist and can reach the same background server. Choosing
a transport does not itself create a worktree or select the same task.

For desktop connections, the app's project/host metadata distinguishes:

- `remote-ssh-discovered:devbox`: the SSH connection.
- `remote-control:<environment-id>`: the Remote Control relay connection.

Prefer host IDs over display names or remembered UI positions. Use
`list_projects` when available and match the current project/task; merely
listing both connections does not identify which one this task uses.

### Additional live signals

```bash
printf 'CODEX_HOME: %s\n' "${CODEX_HOME:-<default>}"
printf 'CODEX_THREAD_ID: %s\n' "${CODEX_THREAD_ID:-<unset>}"
```

- `CODEX_THREAD_ID` identifies a Codex task; it does not identify transport.
- If server ownership matters, inspect this shell's parent chain through
  `/proc/<pid>/status` and `/proc/<pid>/cmdline`. An ancestor running
  `codex app-server --remote-control --listen unix://` establishes a
  relay-enabled server, but that server can also serve local/SSH clients.
- `codex app-server daemon version` is a read-only server/version probe;
  a responding server alone does not establish daemon ownership or systemd
  supervision. Do not run start, bootstrap, pair, or restart merely to
  explain an existing connection.

### Setup history and practical details

The September 8–9, 2026 conversations established this sequence:

1. **Desktop SSH first.** The desktop app launched App Server using `nohup`,
   with a separate `codex app-server proxy` carrying traffic over SSH.
   The temporary port-1455 SSH tunnel was only for the browser sign-in
   callback; it was not the ongoing desktop transport.
2. **Managed Remote Control later.** The directly launched server was
   replaced with a CLI-managed daemon using:
   ```bash
   codex -c features.code_mode_host=true app-server daemon bootstrap --remote-control
   codex remote-control start --json
   codex remote-control pair --json
   ```
   These are historical setup commands, not steps to rerun during diagnosis.
   The daemon reported the PID backend and automatic updates. It survived
   setup SSH disconnection; no systemd service was installed and boot
   recovery was not established. Recheck ownership before lifecycle changes.
3. **Desktop relay and phone access.** The Mac registered a relay project
   alongside its SSH projects. The phone loaded devbox projects/history
   and remained Connected after setup SSH exited. No coding task from the
   phone, VPN-off test, or Mac-asleep test was performed in that discussion.
   The relay is a separate network channel from setup SSH; it requires the
   devbox server and its network connection to remain available.
   It does not require the Mac as an SSH intermediary for phone access or
   a direct client VPN/SSH route to the devbox. The earlier recommendation
   of phone → Mac → SSH → devbox was superseded by this setup.

For automated SSH commands, the tested login-shell form was
`ssh devbox "zsh -lc 'codex --version'"`. A plain SSH command did not find
Codex; `.zprofile` made `~/.local/bin` available to noninteractive login
shells. Avoid adding interactive `-i` merely to find Codex: it also loads
prompt/plugins. A fresh shell's PATH does not prove a reused App Server has
that PATH; the MCP startup incident traced failures to an older server's
environment. Restarting only the terminal client did not refresh it.

### Codex references

- `codex/devbox-ssh-setup.md`: desktop SSH, login callback, and the correction
  from assumed daemon management to the observed direct server launch.
- `codex/devbox-remote-control-and-self-automation.md`: managed relay setup,
  phone verification limits, duplicate devbox entries, and shell startup.
- `codex/devbox-mcp-daemon-path.md`: terminal clients sharing a server with a
  stale PATH and `/home` versus `/data00` hook-approval path differences.

## Claude Code only

Distinguish a terminal running `claude` over SSH, Claude Desktop connecting
through SSH, and Claude Remote Control clients reaching the devbox through
Claude's relay. The `cl` helper below manages the relay-server variant.

### Additional live signals

```bash
printf 'CLAUDE_CODE_ENVIRONMENT_KIND: %s\n' "${CLAUDE_CODE_ENVIRONMENT_KIND:-<unset>}"
printf 'CLAUDE_CODE_CHILD_SESSION: %s\n' "${CLAUDE_CODE_CHILD_SESSION:-<unset>}"
printf 'CLAUDE_CODE_ENABLE_CFC: %s\n' "${CLAUDE_CODE_ENABLE_CFC:-<unset>}"
printf 'CLAUDE_CODE_REMOTE: %s\n' "${CLAUDE_CODE_REMOTE:-<unset>}"
```

### Connection and session behavior

- The `cl` helper at `~/dotfiles/.claude/my-scripts/cl` (symlinked into
  `~/.claude/my-scripts/cl`) starts one `claude remote-control` server per
  repository in a window of the persistent tmux session `cl`. Its recorded
  configuration uses `--spawn=worktree --permission-mode=bypassPermissions`
  and `CLAUDE_CODE_ENABLE_CFC=1`.
- SSH starts/supervises those terminal windows. Claude's phone/desktop/web
  clients connect through Claude Remote Control independently of SSH.
  Disconnecting SSH leaves the tmux-hosted server running.
- `CLAUDE_CODE_ENVIRONMENT_KIND=bridge` or a path under
  `.claude/worktrees/bridge-*` indicates a Claude bridge session. With the
  helper's worktree mode, server-spawned sessions have separate working
  trees; repository metadata such as refs and the stash remain shared.
  At conversation completion, integrate the session commits into the main
  checkout according to the repository's workflow. Do not apply this
  Claude bridge convention automatically to Codex tasks.
- Interactive `claude` can also enable Remote Control through
  `remoteControlAtStartup: true`. Restarting a `cl` server does not restore
  an unrelated interactive session; that case used `claude --resume`.
- `CLAUDE_CODE_ENABLE_CFC` enables Claude's Chrome integration on the
  execution host. `CLAUDE_CODE_REMOTE` describes Claude's cloud environment,
  a different mechanism from Remote Control. These variables do not
  configure Codex browser tools or give access to the client Mac's Chrome.

### Claude references

- `devbox/remote-control-repl-vs-server.md`: interactive Claude versus `cl`.
- `devbox/chrome-in-remote-control.md` and `devbox/README.md`: Claude browser
  integration and the rest of the devbox setup history.
