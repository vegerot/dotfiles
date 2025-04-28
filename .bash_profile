# Compute how long startup takes.
# Only GNU date supports milliseconds, and also only GNU date has `--help`
if type gdate > /dev/null 2>&1; then
	start=$(gdate +%s.%N)
elif $(date --help &> /dev/null); then
	start=`date +%s.%N`
else
	start=$(python3 -c "import time; print(time.time())")
fi

# POSIX stuff
[[ -r "$HOME/.profile" ]] && source ~/.profile

# completions
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

# prompt
if [[ -f ~/workspace/github.com/facebook/sapling/eden/scm/contrib/scm-prompt.sh ]]; then
	source ~/workspace/github.com/facebook/sapling/eden/scm/contrib/scm-prompt.sh
fi
maybe_scm_prompt() {
	if type _scm_prompt >/dev/null 2>&1; then
		_scm_prompt
	fi
}
PROMPT_DIRTRIM=3

RED_START='\033[01;31m'
GREEN_START='\[\033[01;32m\]'
LIGHT_GREEN_START='\[\033[01;92m\]'
BLUE_START='\[\033[01;34m\]'
MAGENTA_START='\033[01;35m'

COLOR_RESET='\033[0m'

PROMPT_WHOAMI="🪪${GREEN_START}\u${COLOR_RESET}💻${LIGHT_GREEN_START}\h${COLOR_RESET}"
PROMPT_WHEREAMI="📁${BLUE_START}\w/${COLOR_RESET}"
PROMPT_JUST_BRANCH='$(git branch --show-current >/dev/null 2>&1 && printf "🌿$(git branch --show-current) "|| printf "")'
PROMPT_SAPLING='$(maybe_scm_prompt)'
PROMPT_BRANCH="${MAGENTA_START}${PROMPT_JUST_BRANCH}${PROMPT_SAPLING}${COLOR_RESET}"
PROMPT_LAST_STATUS='$(EXIT=$?;[ $EXIT != 0 ] && printf "❌${RED_START}($EXIT)" || printf "")'
PROMPT_START='$ '
PS1="\n${PROMPT_LAST_STATUS}$PROMPT_WHOAMI: $PROMPT_WHEREAMI $PROMPT_BRANCH\n$PROMPT_START"

# history
export HISTSIZE=420690
export HISTFILESIZE=694200
shopt -s histappend
shopt -s histverify
shopt -s lithist
export PROMPT_COMMAND="history -a"

if type randomcowcommand >/dev/null 2>&1; then
  if type manpath >/dev/null 2>&1; then
    randomcowcommand --async
  fi
fi

# Compute time taken
if type gdate > /dev/null 2>&1; then
	end=$(gdate +%s.%N)
elif $(date --help &> /dev/null); then
	end=`date +%s.%N`
else
	end=$(python3 -c "import time; print(time.time())")
fi

if type bc > /dev/null 2>&1; then
  runtime=$( echo "$end - $start" | bc -l )
else
  runtime=$( python3 <(echo "print($end - $start)") )
fi

startuptime=$(printf '%.2f seconds\n' $runtime)

if type rainbow > /dev/null 2>&1; then
	printf "$startuptime\n" | rainbow
else
	printf "$startuptime\n"
fi

