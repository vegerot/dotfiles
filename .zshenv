typeset -aU path
typeset -U PATH
# Non-login shells, including `ssh host command`, only read .zshenv.
# Login shells load the shared environment from .zprofile instead, after
# macOS's /etc/zprofile/path_helper has reordered PATH.
if [[ ! -o login && -r ~/.profile ]]; then
	source ~/.profile
fi
