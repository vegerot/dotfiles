For introspection questions about Claude Code, first use your other instructions, knowledge, and skills (e.g. `claude-code-guide` agent, `claude-api`, `update-config`, etc.), or web search if needed.  When those are insufficient, or the user asks a precise implementation question, consult the following sources:

- `~/code/github.com/anthropics/claude-code-source/` — the `src/` implementation: exact paths, precedence, and option names. This snapshot is older than the installed version, so confirm findings against the CHANGELOG in the next repo.  Make sure to read and update `how-claude-works.md` if you find new information.
- `~/code/github.com/anthropics/claude-code/` — official. `CHANGELOG.md` is current and authoritative for features, versions, and behavior and should be used to fact-check findings in the previous repo.
- check the installed `claude` binary itself.  For example:
  * `strings` on the binary
  * run `claude` in tmux
  * other experiments

Before relying on a repo under `~/code/github.com/anthropics/`, check its age with `git log -1 --format=%cr`.  If it is older than a day, update it first: `git pull` for a full clone, or `git fetch --depth=1 origin && git reset --hard FETCH_HEAD` for a shallow clone (`git rev-parse --is-shallow-repository`).
