For introspection questions about Claude Code, first use your other instructions, knowledge, and skills (or web search if needed).  When those are insufficient, or the user asks a precise implementation question, consult the following sources:

- `~/code/github.com/anthropics/claude-code-leaked/` — the `src/` implementation: exact paths, precedence, and option names. This snapshot is older than the installed version, so confirm findings against the CHANGELOG in the next repo.
- `~/code/github.com/anthropics/claude-code/` — official. `CHANGELOG.md` is current and authoritative for features, versions, and behavior and should be used to fact-check findings in the previous repo.
- check the installed `claude` binary itself.  For example:
  * `strings` on the binary
  * run `claude` in tmux
  * other experiments
