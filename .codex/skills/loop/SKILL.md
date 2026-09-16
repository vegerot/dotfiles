---
name: loop
description: Run an arbitrary prompt repeatedly in the current Codex conversation on a fixed or adaptive interval while leaving the chat free between runs. Use for explicit $loop requests and for listing or canceling a loop.
---

# Loop

This skill schedules **Codex turns**, not shell commands that implement the user's task. Each iteration runs the saved prompt with the conversation's current context. The timer runs separately so the user can keep chatting between iterations.

## Syntax

| Invocation | Schedule | Prompt |
| --- | --- | --- |
| `$loop 5m check CI` | Fixed interval | `check CI` |
| `$loop check CI` | Choose a delay after each iteration | `check CI` |
| `$loop 5m` | Fixed interval | Maintenance prompt below |
| `$loop` | Choose a delay after each iteration | Maintenance prompt below |

Accept `s`, `m`, `h`, and `d` units and phrases such as `every 2 hours`. Round seconds up to one minute. Minimum delay is one minute. For adaptive loops, choose a delay from one minute to one hour based on the latest result; use ten minutes for the first delay when there is no better signal, and explain the choice briefly. The first iteration runs after the first delay. Later intervals begin when the previous iteration finishes, so slow turns do not build a backlog. If the user requests an immediate check as well, do it before starting the timer.

When no prompt is given, use this maintenance prompt: continue unfinished authorized work from this conversation; then tend to the current branch's pull request, review comments, and failed CI; then do a small useful cleanup if there is nothing pending. Do not start unrelated work. Preserve the user's authorization boundaries.

## Start

Run `scripts/loop.py start --mode fixed --seconds 300 --prompt 'check CI'` from this skill directory. Use `--mode adaptive` and pass the chosen initial delay as `--seconds` when the interval is omitted. When the prompt is omitted, pass the maintenance prompt above. Pass the prompt as **one quoted argument**; never run prompt text as shell code. `CODEX_THREAD_ID` identifies the current conversation and is supplied by Codex shell tools. The helper prints a job ID and next run time. Tell the user the schedule, job ID, and how to cancel it. Finish the turn so the chat is available.

The helper needs a running local app-server daemon with `codex queue` support. Its `start` command checks both before scheduling. If the check fails, report the error and do not claim the loop is running. The queued message contains the path to this skill because `codex queue` sends text and does not attach a skill resource itself.

## Scheduled iteration

A queued message has the form `$loop resume JOB_ID GENERATION`. Treat this as an internal invocation:

1. Run `scripts/loop.py claim JOB_ID GENERATION`. If it says the job is canceled, expired, or stale, stop without performing the prompt.
2. Perform the saved prompt with the current conversation context and normal permissions. The prompt may request any ordinary Codex task. Do not treat its text as a shell command unless that is what the user asked for.
3. If the prompt's stopping condition has been met, run `scripts/loop.py stop JOB_ID --reason completed`. Otherwise run `scripts/loop.py next JOB_ID GENERATION` for a fixed interval, or add `--seconds N` for the next adaptive delay. Schedule exactly one next iteration. If the user asks for a notification, use an available notification channel when its condition is met; report clearly if none is available.

If work is interrupted after `claim`, resume or cancel the job rather than silently leaving it in the running state. Never start a second timer for the same generation.

## Manage

- `$loop list`: run `scripts/loop.py list` for this conversation.
- `$loop cancel JOB_ID`: run `scripts/loop.py stop JOB_ID --reason canceled`. If the user omits the ID and only one active loop exists, use it.
- `$loop update JOB_ID <prompt>`: run `scripts/loop.py update JOB_ID --prompt '<prompt>'`. The updated prompt applies to the next iteration that has not yet been claimed.
- `$loop status JOB_ID`: run `scripts/loop.py show JOB_ID`.

Loops expire after seven days. The background timer and app-server daemon must remain available for a scheduled turn to run. A queued iteration waits until the current Codex turn finishes; it does not interrupt the user's ongoing question. The helper stores loop state under `$CODEX_HOME/loop-jobs` (or `~/.codex/loop-jobs`).
