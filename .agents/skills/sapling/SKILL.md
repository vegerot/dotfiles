---
name: sapling
description: Use Sapling (`sl`) instead of `git` for version control tasks. Prefer Sapling-native workflows, command translations, and Smartlog-first behavior.  Use this skill whenever the user asks you to do anything in a Sapling repository, when the repository appears to use Sapling (e.g. when it includes `.sl/` or `.git/sl/` in the root), or when the user mentions "sapling", "sl", or "git".
---

# Sapling skill

Use this skill whenever the user asks you to inspect, modify, commit, review, rebase, undo, or publish work in a Sapling repository, or when the repository appears to use Sapling (e.g. when it includes `.sl/` or `.git/sl/` in the root).

## Core rule

Prefer `sl` over `git` for all version-control tasks.  If the user insists on using Git, then use git after confirming they don't want to use sl.  You may also use git if using sl repeatedly is causing you to get stuck on a problem that you think git would solve more easily.

## Goal

Behave like a Sapling-native assistant: use `sl` first, map Git intent to Sapling correctly, and avoid assuming Git workflows such as staging/index-based commits.

## Mental model differences from Git

Sapling is not Git with renamed commands. Important differences:

You MUST read and understand ~/workspace/github.com/facebook/sapling/website/docs/introduction/{differences-git.md,git-cheat-sheet.md}

- The most IMPORTANT difference is that while git encourages users to think in terms of branches, `sl` encourages users to think in terms of a linear commit **stack** and a mutable working copy. This affects how users should approach version control tasks and the mental model they should have when using Sapling.
- Do NOT think of ~branches~, instead think of **stacks**.
- `sl` with no arguments shows the Smartlog graph.
- Sapling does **not** use a staging index like Git.
- `sl add` starts tracking files.
- `sl commit` creates a commit from pending changes.
- `sl amend` updates the current commit.
- Commit stacks and working-copy navigation are central to Sapling.
- `sl log` is for deeper history; `smartlog` is the day-to-day view.
- `sl push` and `sl pr` are the main publishing paths for GitHub workflows.
    * NEVER run `sl push` or `sl pr` without explicit user permission. If you want to use `push` or `pr` without being asked, ask the user for permission first.
- append `--config ui.paginate=false` to all `sl` commands that might produce long output

## Default workflow

When working in Sapling:

1. Start by checking `sl` / Smartlog.
2. Use `sl status` to inspect pending changes.
3. Use `sl diff` to review changes.
4. Use `sl show` to inspect a commit.
5. Use `sl commit` or `sl amend` instead of `git commit` or `git commit --amend`.
6. Use `sl goto` instead of checkout/reset-like movement.
7. Use `sl rebase`, `sl fold`, `sl split`, `sl histedit`, `sl absorb`, `sl hide`, `sl uncommit`, `sl undo`, and `sl redo` when manipulating commits or history.
8. Use `sl push` or `sl pr` when publishing changes to GitHub.

When unsure, use `sl githelp -- <git command>` to translate a Git command to Sapling.

## Publishing changes to GitHub

Prefer these patterns:

- When not opening a pull request, push a stack with `sl push`
- Create or update pull-request workflow with `sl pr` when appropriate

Be explicit about whether the user is asking for:

- a Sapling stack workflow
- a GitHub PR workflow
- a plain push to a remote bookmark/branch

## Commit / history editing guidance

Use Sapling-native commands to rewrite history safely:

- `sl amend` for small fixes to the current commit
- `sl absorb` to fold unstaged changes into earlier commits in the stack
- `sl split` to split a commit into smaller commits
- `sl fold` to combine commits
- `sl histedit` to reorder, edit, combine, or delete commits interactively
- `sl rebase` to move commits between bases
- `sl hide` / `sl unhide` for removing and restoring commits from view
- `sl uncommit` to move part or all of the current commit back to pending changes
- `sl unamend` to undo the last amend
- `sl undo` and `sl redo` to reverse local operations

## Repository setup guidance

If the repository is meant to be used with Sapling exclusively:

- assume no staging index exists
- avoid Git-centric instructions like `git add . && git commit -m ...` unless translated into Sapling

## Response style

When helping the user, use Sapling terminology consistently:

- say "working copy" rather than "checkout" when appropriate
- say "smartlog" when referring to the main view
- say "commit stack" when discussing stacked changes
- mention Git only as a compatibility layer or translation target

## Helpful commands to remember

- `sl`
- `sl status`
- `sl diff`
- `sl show`
- `sl log`
- `sl goto`
- `sl add`
- `sl remove`
- `sl forget`
- `sl revert`
- `sl purge`
- `sl shelve`
- `sl commit`
- `sl amend`
- `sl metaedit`
- `sl rebase`
- `sl graft`
- `sl hide`
- `sl unhide`
- `sl previous`
- `sl next`
- `sl split`
- `sl fold`
- `sl histedit`
- `sl absorb`
- `sl uncommit`
- `sl unamend`
- `sl undo`
- `sl redo`
- `sl config`
- `sl doctor`
- `sl grep`
- `sl journal`
- `sl web`
- `sl pr`
- `sl push`

## Use documentation when needed

If a command choice is unclear, consult Sapling help:

- `sl --help`
- `sl help commands`
- `sl help <command>`
- `sl githelp -- <git command>`
- ~/workspace/github.com/facebook/sapling/website/docs/
- ~/workspace/github.com/facebook/sapling/eden/scm

When facing a TOUGH challenge that requires deep understanding of Sapling's behavior, ground your answer in `~/workspace/github.com/facebook/sapling/eden/scm/`

## Goal

Behave like a Sapling-native assistant: use `sl` first, map Git intent to Sapling correctly, and avoid assuming Git workflows such as staging/index-based commits.
