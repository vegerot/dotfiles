# POSIX stuff
[[ -r "$HOME/.profile" ]] && source ~/.profile

# completions
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

# prompt
PROMPT_DIRTRIM=3

GREEN_START='\[\033[01;32m\]'
LIGHT_GREEN_START='\[\033[01;92m\]'
BLUE_START='\[\033[01;34m\]'
MAGENTA_START='\033[01;35m'

COLOR_RESET='\033[0m'

PROMPT_WHOAMI="🪪${GREEN_START}\u${COLOR_RESET}@${LIGHT_GREEN_START}\h${COLOR_RESET}"
PROMPT_WHEREAMI="📁${BLUE_START}\w/${COLOR_RESET}"
PROMPT_JUST_BRANCH='$(git branch --show-current >/dev/null 2>&1 && printf "🌿$(git branch --show-current) "|| printf "")'
PROMPT_BRANCH="${MAGENTA_START}${PROMPT_JUST_BRANCH}${COLOR_RESET}"
PROMPT_LAST_STATUS='$([ $? != 0 ] && printf "❌ " || printf "")'
PROMPT_START='$ '
PS1="${PROMPT_LAST_STATUS}$PROMPT_WHOAMI: $PROMPT_WHEREAMI $PROMPT_BRANCH\n$PROMPT_START"

# history
export HISTSIZE=42069
export HISTFILESIZE=69420
shopt -s histappend
shopt -s histverify
shopt -s lithist
export PROMPT_COMMAND="history -a"

if type randomcowcommand 2>&1 >/dev/null; then
  randomcowcommand --async
fi
