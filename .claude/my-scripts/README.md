# 🖥️ How to code on the devbox from your Mac

Written **2026-08-21**. This box is `n251-236-182.byted.org` / `10.251.236.182`,
veLinux 2, x86_64. Claude Code here is **2.1.237** at `~/.local/bin/claude`.

This directory holds my own scripts. `.paths.sh` puts it on `PATH`. It contains one
script today: [`cl`](./cl).

---

## ⚡ Cheat sheet — Remote Control

```sh
cl dotfiles          # start or jump to the server for a repo
cl <git-url>         # clone into ~/code/<host>/<org>/<repo>, then start
cl reindex           # rebuild the repo index after cloning by hand
cl update            # update claude, then restart the servers on it
tmux attach -t cl    # see all running servers, one window each
```

Then open **<https://claude.ai/code>** or the app's **Code** tab, and pick
**`devbox-<repo>`**. Every chat there gets its own git worktree.

| Need | Do this |
|---|---|
| Fresh clone refuses to start | `cd <repo> && claude`, accept the trust dialog, quit |
| Show a QR code | <kbd>space</kbd> in the server window |
| Switch worktree ↔ same-dir | <kbd>w</kbd> in the server window |
| Server row gone from the app | `cl <repo>` again |
| Been down over ~4 hours | `claude --resume <id>`, then `/remote-control` |

Full detail in [section 1](#1--remote-control--the-main-way).

---

## 🚦 Pick a way

| Way | Use it when | Works today |
|---|---|---|
| **1. Remote Control** | Phone, browser, laptop lid closed, long jobs | ✅ primary |
| **2. `@devbox-<repo>` from Mac Claude Code** | You are already in a Mac terminal session | ✅ |
| **3. Claude Desktop SSH** | You sit at the Mac and want the desktop app | ✅ |
| **4. Plain `ssh`** | You need a real shell | ✅ rare |

Ways 1 and 3 both run Claude Code **on this box**. Neither needs a tunnel.

---

## 1. 🌐 Remote Control — the main way

A `claude remote-control` server runs here inside `tmux`. It makes only **outbound
HTTPS** to `api.anthropic.com`. No port forwarding. No inbound access.

### Connect

Open **<https://claude.ai/code>**, or the **Code** tab in the Claude mobile app.
Pick the server by name. Each running server is one row.

Every chat you start there gets **its own git worktree** on this box, so parallel
chats never fight over files. Default capacity is 32 sessions per server.

### Start a server — one per repo

```sh
cl dotfiles                                      # repo already cloned
cl git@github.com:anthropics/claude-code.git     # clones it first
```

`cl` is the script next to this file, `~/.claude/my-scripts/cl`. `~/dotfiles/.paths.sh`
puts that directory on `PATH`, so every shell has it. It does four things:

1. Finds the repo in `~/.cache/cl-repos`, or clones a URL into
   `~/code/<host>/<org>/<repo>`.
2. Makes a `tmux` window in session `cl`, one per repo.
3. Runs `claude remote-control --name=devbox-<repo> --spawn=worktree` there.
4. Jumps you to that window.

Subcommands: `cl reindex` rebuilds the repo index. `cl clone <url>` clones only.
`cl update` updates Claude Code and restarts every server on the new binary.

### Why `cl` and not `cc`

`cc` was the first name. But `/usr/bin/cc` is the system C compiler, and
`~/.claude/my-scripts` goes **before** `/usr/bin` on `PATH`. `make` and `configure`
default to `cc`, so every build on this box would have run the helper instead.

`cl` is free on Linux, so it takes no name that a build needs.

### Why one server per repo

A server is bound to the directory it starts in. `~/code` is **not** a git repo, so a
single server rooted there gets no `CLAUDE.md`, no git context, and no worktrees.

### Names

The name is `devbox-<repo>`. It is both the row in the Claude app and the address for
cross-machine messaging. See way 2.

### Runtime keys

Press <kbd>space</kbd> for a QR code. Press <kbd>w</kbd> to toggle spawn mode between
`worktree` and `same-dir`.

### ⚠️ Gotcha: workspace trust

`claude remote-control` refuses a directory Claude has never run in:

> `Error: Workspace not trusted. Please run` `claude` `in <dir> first to review and
> accept the workspace trust dialog.`

There is **no CLI flag** for this. So `cl <new-repo>` fails the first time on every
fresh clone. Fix it once per repo:

```sh
cd ~/code/<host>/<org>/<repo> && claude     # accept the dialog, then quit
```

Home-directory trust is never saved, by design. Do not try to trust `~`.

### ⏳ Gotcha: the 4-hour window

`claude remote-control --continue` reattaches to the last session **for that
directory**. The window is ~4 hours, and it is **rolling** — the clock starts only when
the server process stops. A server left running never expires.

After 4 hours, resume by session ID:

```sh
ls -t ~/.claude/projects/$(pwd | sed 's/[^a-zA-Z0-9]/-/g')/*.jsonl
claude --resume <session-id>     # then run /remote-control
```

Bare `claude --resume` will **not** list server-mode sessions. They run as `--print`
sessions.

### 📌 Gotcha: a server pins its claude version

`claude` updates in place, but a **running** server keeps the binary it started with.
Every chat it spawns is a child of that binary, so the chats run the old version too.
A server left up for days silently runs an old Claude Code.

`cl update` fixes it in one step: it runs `claude update`, then restarts every server.

`cl` marks each of its tmux windows with a `@cl_repo` option, which is how `cl update`
finds the servers and leaves the plain shell windows alone. A server started by hand
carries no mark, so `cl update` skips it.

⚠️ A restart interrupts the chats in that server. It does not lose them: the transcript
lives on Anthropic's servers.

⚠️ `claude respawn` is a different thing. It restarts **background jobs** — the
`claude --bg` / `claude agents` family — and never sees these tmux servers.

### Live right now

`devbox-dotfiles`, rooted at `~/code/github.com/vegerot/dotfiles`, in `tmux` window
`cl:dotfiles`.

---

## 2. 💬 `@devbox-<repo>` from Claude Code on the Mac

With Remote Control running here, a Mac Claude Code session can address this box
directly. Run `/list-agents` on the Mac. Rows look like:

```
devbox-dotfiles [f55a07]  ·  Remote Control  ·  idle
```

Then write, in a normal prompt:

```
Ask @devbox-dotfiles whether the build finished
```

⚠️ Current limit: this box **receives** your message but cannot message the Mac back.
Read its answer in its own transcript, or at claude.ai/code.

⚠️ Cross-machine messages travel through Anthropic servers. Same-machine messages use a
local socket. Set `isolatePeerMachines: true` to approve each one.

---

## 3. 🖱️ Claude Desktop SSH

The Desktop **Code** tab opens a session on this box over SSH. Point and click.

### Set it up

In the app: **Code** tab → the environment dropdown → add an SSH connection.

Or pre-declare it in the **Mac's** `~/.claude/settings.json`:

```json
{
  "sshConfigs": [
    {
      "id": "devbox",
      "name": "veLinux Devbox",
      "sshHost": "max.coplan@10.251.236.182",
      "startDirectory": "~/code"
    }
  ]
}
```

Optional keys: `sshPort` (default 22) and `sshIdentityFile`. ⚠️ The key is
`sshIdentityFile`, **not** `identityFile`. `sshHost` also takes a `~/.ssh/config`
alias.

### 🔐 Why this needed a server change

This box was **Kerberos-only**. `/etc/ssh/sshd_config` lines 1–2 set
`PubkeyAuthentication no` and `PasswordAuthentication no`, and only `gssapi-with-mic`
was accepted.

Desktop bundles the `ssh2` npm library, which has **no GSSAPI support**. It tried
`none`, `publickey`, then `password`, got `USERAUTH_FAILURE (gssapi-with-mic)` each
time, then showed a password box that could never succeed.

The fix, appended to `/etc/ssh/sshd_config` on **2026-08-21**:

```
Match User max.coplan
    PubkeyAuthentication yes
```

Kerberos stays on for everyone. Password auth stays off. Only your account gained
pubkey. Backup: `/etc/ssh/sshd_config.bak-before-pubkey-20260821`.

⚠️ **Provisioning may revert this.** Lines 1–2 were machine-written at build time. If
Desktop SSH suddenly asks for a password again, that is what happened. Re-apply the
`Match` block, run `sudo sshd -t`, then `sudo systemctl reload ssh` — never `restart`.

Your public key lives in `~/.ssh/authorized_keys`.

### 📦 What Desktop installed here

On first connect it wrote `~/.claude/remote/`, about **320 MB**:

| Path | Size | What |
|---|---|---|
| `srv/<sha>/server` | 6.1 MB | Static Go binary, `claude-ssh`. Runs `--serve` and `--bridge` |
| `ccd-cli/2.1.234` | 314 MB | A **second, pinned** Claude Code CLI |
| `run/<id>/` | tiny | `rpc.sock`, `daemon.token`, `remote-server.log` |

It listens on a **unix socket only**, mode `srw-------`. No TCP port. Nothing new is
reachable from the network.

It does **not** conflict with your install. `claude` still resolves to
`~/.local/bin/claude` (2.1.237), and `ccd-cli` is not on `PATH`. Their auto-updates are
independent.

They **do share state**: the same `~/.claude/` and `~/.claude.json`. That is mostly
good — Desktop inherits your `CLAUDE.md`, skills, and trusted-workspace list. Do not
delete `ccd-cli`; Desktop re-downloads 314 MB on the next connect.

### 🚫 Known limits

- Terminal panel is local to the Mac.
- "Send to web" does not work for SSH sessions.
- Skills load from **this box's** `~/.claude/skills/`.
- `ProxyCommand` is honored. `ProxyJump` is not.

---


## 4. ⌨️ Plain `ssh` — rare

```sh
ssh -t max.coplan@10.251.236.182 'bash -lc "tmux attach -t cl"'
```

Always use `bash -lc`. A **login** shell is what puts `claude`, `fd`, and the
`/opt/tiger` toolchain on `PATH`. `~/.bashrc` returns early for non-interactive shells,
so `ssh host 'cmd'` sees almost nothing without `-l`.

tmux prefix here is the default **`C-b`**.

---

## 🧰 Reference

### This box

| Item | Value |
|---|---|
| Host | `max.coplan@10.251.236.182` |
| Login | Kerberos (`~/.k5login`), plus your pubkey |
| Claude Code | 2.1.237, native install, logged in as `mchcopl@gmail.com`, plan Max |
| Installed | `rg`, `fd`, `jq`, `atuin`, `tmux` 3.3a, `git` 2.39.5, `traex` |
| Missing | `sl` (Sapling) |
| sudo | passwordless |

### Repo layout

Go style: `~/code/<host>/<org>/<repo>`. `~/code` itself is **not** a git repo. Repos are
cloned **on demand** — use `cl <git-url>`.

Git work identity is automatic. Inside `~/code/code.byted.org/**`, git reports
`max.coplan@ByteDance.com` via `includeIf` in `~/.gitconfig`.

### Do not break these

| Thing | Why |
|---|---|
| `~/.k5login` | Kerberos principals. Deleting it locks you out |
| `~/.ssh/config` + `aime_remote_ssh_key` | AIME cube proxies |
| `~/.aime/socat-*-linux` on `PATH` | `~/.ssh/config` `ProxyCommand` needs it. Set in `~/dotfiles/.paths.sh` |
| `/etc/profile.d/*` | System PATH files. Leave alone |

### Useful commands here

```sh
cl <repo|url>          # start or jump to a Remote Control server
cl reindex             # rebuild ~/.cache/cl-repos
cl update              # update claude, then restart the servers
claude rc              # same as `claude remote-control` (hidden alias)
claude doctor          # version, commit, update channel
tmux attach -t cl      # the server windows
```

---

## 🩺 Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Workspace not trusted` | Fresh clone | `cd <repo> && claude`, accept, quit |
| Desktop asks for an SSH password | The `Match` block was reverted | Re-apply it, `sshd -t`, `systemctl reload ssh` |
| `claude: command not found` over ssh | Not a login shell | Use `bash -lc "..."` |
| `--continue` says nothing recorded | Past the 4-hour window | `claude --resume <id>`, then `/remote-control` |
| Server row missing at claude.ai/code | Process stopped | `cl <repo>` again |
| Chats run an old Claude Code | The server pins the binary it started with | `cl update` |
| Mouse scroll dead in tmux | Server started before the config existed | `tmux source-file ~/.config/tmux/tmux.conf` |
