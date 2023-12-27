source ~/.profile

export CDPATH="$CDPATH:$HOME/gecgithub01.walmart.com/m0c0j7y/:$HOME/gecgithub01.walmart.com/walmart-web/walmart-web-worktree/"

# for some reason "\n" doesn't work in $PS1??
NEWLINE="
"
export PS1="${NEWLINE}$PS1${NEWLINE}$ "

HISTSIZE=10000000
SAVEHIST=10000000
setopt incappendhistorytime

# edit the current line in vim with `C-x C-e` like in bash
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

~/dotfiles/bin/randomcowcommand&

# bun completions
[ -s "/Users/m0c0j7y/.bun/_bun" ] && source "/Users/m0c0j7y/.bun/_bun"
