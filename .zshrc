# Compute how long startup takes.
# Only GNU date supports milliseconds, and also only GNU date has `--help`
if type gdate > /dev/null; then
  start=$(gdate +%s.%N)
elif $(date --help &> /dev/null); then
  start=`date +%s.%N`
else
  start=$(python3 -c "import time; print(time.time())")
fi

source ~/.profile
~/dotfiles/bin/randomcowcommand&

export CDPATH="$CDPATH:$HOME/gecgithub01.walmart.com/m0c0j7y/:$HOME/gecgithub01.walmart.com/walmart-web/walmart-web-worktree/"

# for some reason "\n" doesn't work in $PS1??
NEWLINE="
"
export PS1="${NEWLINE}$PS1${NEWLINE}$ "

# HISTORY
HISTSIZE=1073741823000
SAVEHIST=$HISTSIZE
HIST_EXPIRE_DUPS_FIRST=1
export HISTSIZE
export SAVEHIST
export HIST_EXPIRE_DUPS_FIRST

setopt EXTENDED_HISTORY
setopt histexpiredupsfirst
setopt incappendhistorytime

unsetopt histignorespace

# COMMAND LINE EDITING
setopt vi
## edit the current line in vim with `C-x C-e` like in bash
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line
## 10ms for key sequences.  Makes going to normal mode fast
KEYTIMEOUT=1
bindkey -M vicmd "" edit-command-line

# change cursor shape in vi mode
zle-keymap-select () {
    if [[ $KEYMAP == vicmd ]]; then
        # the command mode for vi
        echo -ne "\e[2 q"
    else
        # the insert mode for vi
        echo -ne "\e[5 q"
    fi
}
precmd_functions+=(zle-keymap-select)
zle -N zle-keymap-select


setopt correct
COMPLETION_WAITING_DOTS="true"
## Only check compinit once a day
## credit: https://medium.com/@dannysmith/little-thing-2-speeding-up-zsh-f1860390f92

autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C


# Compute time taken
if type gdate > /dev/null; then
  end=$(gdate +%s.%N)
elif $(date --help &> /dev/null); then
  end=`date +%s.%N`
else
  end=$(python3 -c "import time; print(time.time())")
fi
runtime=$( echo "$end - $start" | bc -l )
printf "%.2f seconds\n" $runtime
