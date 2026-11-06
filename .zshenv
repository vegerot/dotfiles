typeset -aU path
typeset -U PATH
# Non-login shells, including `ssh host command`, only read .zshenv.
# Login shells load the shared environment from .zprofile instead, after
# macOS's /etc/zprofile/path_helper has reordered PATH.
if [[ ! -o login && -r ~/.profile ]]; then
	source ~/.profile
fi

# Claude Code: report a Bash tool call that ran 10 s or more. Each call is a
# fresh shell, so $SECONDS is the command's run time. A background command's
# line lands in its output file. Other tools: ~/dotfiles/bin/claude-slow-tool-note.
if [[ -n ${CLAUDECODE:-} ]]; then
	trap '(( SECONDS >= 10 )) && print -u2 "⏱ Bash took ${SECONDS} s."' EXIT
fi
