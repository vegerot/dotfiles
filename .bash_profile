# POSIX stuff
source ~/.profile

# completions
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

# prompt
PS1="\n📁\W/ \$(git branch --show-current >/dev/null 2>&1 && printf \"🌿\$(git branch --show-current) \"|| printf '') \n\$([ \$? != 0 ] && printf '❌' || printf '')$ "

# history
export HISTSIZE=42069
export HISTFILESIZE=69420
shopt -s histappend
shopt -s histverify
shopt -s lithist
export PROMPT_COMMAND="history -a"

