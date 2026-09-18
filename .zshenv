typeset -aU path
typeset -U PATH
# SSH commands use non-login zsh and only read .zshenv. Interactive login
# shells wait until .zshrc, after macOS's /etc/zprofile/path_helper, so
# Homebrew stays ahead of /usr/bin without loading the environment twice.
if [[ ! -o login && -r ~/.profile ]]; then
	source ~/.profile
fi
