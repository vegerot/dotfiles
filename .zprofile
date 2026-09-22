# Login shells reach this file after macOS's /etc/zprofile/path_helper.
# Load the shared environment here so its PATH order wins for both interactive
# terminals and non-interactive login shells such as `zsh -lc`.
if [[ -r ~/.profile ]]; then
	source ~/.profile
fi
