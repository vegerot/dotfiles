# Issue tracker: plan and progress

This repo has no ticket system. Work is tracked in the plan (`plan.md`, or the document the project uses as its plan) and the append-only `progress.md`. Do not create `.scratch/`, call `gh issue` or `glab issue`, or apply triage labels.

## When a skill says "publish to the issue tracker"

- **Spec** (from `/to-spec`): add a `## Spec: <feature>` section to the plan. Keep the spec template's headings. Merge with the plan's existing goal and decisions instead of repeating them. Show the diff and wait for approval before saving.
- **Tickets** (from `/to-tickets`): add a `## Work: <feature>` section to the plan with one entry per slice, numbered `NN` in dependency order (blockers first):

  ```md
  ### NN. <title>

  **What to build:** <end-to-end behaviour, from the user's perspective>
  **Blocked by:** NN, NN (or "None")
  **Acceptance criteria:**
  - <criterion>
  ```

  Use plain bullets for the acceptance criteria, not checkboxes: the plan holds no status.

## When a skill says "fetch the relevant ticket"

Read slice `NN` from the plan's `## Work` section, then search `progress.md` for entries about it.

## When a skill says "close" or "resolve" a ticket

Append a dated `progress.md` entry: `✅ NN <title> done`, which acceptance criteria were checked and how, and a `Next:` block. Commit the entry with the work, in one commit; the entry names the slice, not the commit hash. Never edit the plan to mark it done.

## Comments

Append them to `progress.md` as entries that name the slice (`NN`). Never rewrite old entries.

## Frontier

A slice is ready when every slice in its `Blocked by` line has a done entry in `progress.md` and it has none itself. The lowest-numbered ready slice wins.

## Parallel work

Only the orchestrating agent writes `progress.md`, after each merge to the integration branch. Implementer subagents report back to it and never edit `progress.md` or the plan, so parallel worktrees cannot conflict on them.
