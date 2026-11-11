For introspection questions about Claude Code, first use your other instructions, knowledge, and skills (e.g. `claude-code-guide` agent, `claude-api`, `update-config`, etc.), or web search if needed.  When those are insufficient, or the user asks a precise implementation question, consult the following sources:

- `~/code/github.com/anthropics/claude-code-source/` — the `src/` implementation: exact paths, precedence, and option names. The `src/` snapshot is version 2.1.88, dates from 2026-03-31, and is never updated, so it is many months older than the installed version. `git log` in this repo shows the age of the notes, not of `src/`. Use `src/` as a map of names to search for, then confirm every behavior claim against the installed binary and the CHANGELOG in the next repo before stating it.  Make sure to read and update `how-claude-works.md` if you find new information.
- `~/code/github.com/anthropics/claude-code/` — official. `CHANGELOG.md` is current and authoritative for features, versions, and behavior and should be used to fact-check findings in the previous repo.
- check the installed `claude` binary itself.  For example:
  * `strings` on the binary
  * run `claude` in tmux
  * other experiments

Before relying on `~/code/github.com/anthropics/claude-code/`, check its age with `git log -1 --format=%cr`.  If it is older than a day, update it first: `git pull` for a full clone, or `git fetch --depth=1 origin HEAD && git reset --hard FETCH_HEAD` for a shallow clone (`git rev-parse --is-shallow-repository`).  Name `HEAD`: a bare `git fetch` on a detached checkout fetches every branch and points `FETCH_HEAD` at the alphabetically first one, which can be months old.
