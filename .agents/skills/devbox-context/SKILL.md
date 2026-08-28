---
name: devbox-context
description: Dumps the connection topology of a Claude Code session on the ByteDance Linux dev box (home /data00/home/max.coplan) into context — SSH vs claude remote-control, the cl tmux helper, bridge/worktree sessions, and CLAUDE_CODE_ENABLE_CFC. Use when the user needs to explain how this session reached them ("explain this is the devbox", "how am I connected right now", "explain ssh vs remote-control here") or wants a quick recap of the setup for themselves or someone else.
---

# Devbox connection context

This machine is the ByteDance Linux dev box (`machine: devbox` in the
`ai-conversations` taxonomy — home is `/data00/home/max.coplan`, not a fixed
hostname). Two independent "remote" layers can be in play at once, and
sessions here are commonly confused for the wrong one. Gather the live
signals, then explain using the background below.

## 1. Gather live signals

Run this once, non-interactively:

```bash
echo "hostname: $(hostname)"
echo "pwd: $PWD"
echo "SSH_CONNECTION: ${SSH_CONNECTION:-<none — not a direct SSH shell>}"
echo "TMUX: ${TMUX:-<none>}"
tmux display-message -p '#S:#W' 2>/dev/null || echo "tmux: not attached / no server"
echo "CLAUDE_CODE_ENVIRONMENT_KIND: ${CLAUDE_CODE_ENVIRONMENT_KIND:-<unset>}"
echo "CLAUDE_CODE_CHILD_SESSION: ${CLAUDE_CODE_CHILD_SESSION:-<unset>}"
echo "CLAUDE_CODE_ENABLE_CFC: ${CLAUDE_CODE_ENABLE_CFC:-<unset>}"
```

Interpret it:

- `SSH_CONNECTION` set + no `CLAUDE_CODE_ENVIRONMENT_KIND` → a plain SSH
  terminal session (or an agent running directly in one), most likely inside
  the `cl` tmux session.
- `CLAUDE_CODE_ENVIRONMENT_KIND=bridge` (or `pwd` matches
  `.claude/worktrees/bridge-*`) → this is a **Remote Control bridge session**:
  spawned by a `claude remote-control` server when a client (phone app,
  desktop app, or claude.ai/code in a browser) connected to it. It runs in
  its own git worktree, isolated from the main checkout and from other
  bridge sessions — the stash stack is the one thing still shared.
  drives the dev box's own Chrome, not the client device's.

## 2. Background to explain, in order

1. **The machine.** This is Max's ByteDance corporate Linux dev box, reached
   from the personal Mac (`work-macbook`) over **Kerberos-only SSH** — no
   password or key auth.
2. **The `cl` helper** (`~/dotfiles/.claude/my-scripts/cl`, symlinked into
   `~/.claude/my-scripts/cl`) runs one persistent `claude remote-control`
   server per repo, each in its own window of a single tmux session named
   `cl`. It starts servers with
   `--spawn=worktree --permission-mode=bypassPermissions` and
   `CLAUDE_CODE_ENABLE_CFC=1` in front.
3. **Two separate "remote" channels, easy to conflate:**
   - The SSH connection from the Mac only reaches the tmux **terminal** —
     that's how the `cl` server itself gets started and supervised.
   - **`claude remote-control`** is a second, independent channel: it opens
     a relay that the phone app, desktop app, or claude.ai/code in a browser
     connects to directly, over the network — not over that SSH session.
     Closing the SSH connection does not kill it; only killing the tmux
     window does.
4. **Bridge sessions are ephemeral worktrees.** Every time a client connects
   to a `remote-control` server, it spawns a fresh session in a new git
   worktree (`--spawn=worktree`) under `.claude/worktrees/bridge-<id>/`, so
   concurrent connections never step on each other's working-tree edits.
   - at the end of each conversation, merge all the commits into main and update the main checkout
5. **`CLAUDE_CODE_REMOTE`** (a cloud/Anthropic-VM session) is a *third*,
   unrelated thing — don't confuse it with `claude remote-control`. Only
   `CLAUDE_CODE_REMOTE` disables local Chrome; `remote-control` does not.

## 3. Deeper reading

Full incident history, with the reverse-engineering that found
`CLAUDE_CODE_ENABLE_CFC` and the bugs hit along the way, lives in
`~/code/github.com/vegerot/ai-conversations/devbox/README.md` and its four
conversation files. Point there for anything this summary compresses away.
