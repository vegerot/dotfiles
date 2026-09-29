typeset -aU path
typeset -U PATH
# Non-login shells, including `ssh host command`, only read .zshenv.
# Login shells load the shared environment from .zprofile instead, after
# macOS's /etc/zprofile/path_helper has reordered PATH.
if [[ ! -o login && -r ~/.profile ]]; then
	source ~/.profile
fi

# Desktop SSH prepends CODEX_INSTALL_DIR to PATH; ordinary terminals keep the fork.
if [[ -n ${CODEX_REMOTE_PAYLOAD-} && ${HOST%%.*} == devbox ]]; then
	export CODEX_INSTALL_DIR="$HOME/.codex/packages/app-server-daemon/current/bin"
fi
