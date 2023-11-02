#Path stuff

case ":${PATH}:" in
    *:"$HOME/.cargo/bin":*)
        ;;
    *)

source /etc/zprofile
## important stuff goes first
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.cargo/bin:/usr/local/opt/ruby/bin:$PATH"
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# Walmart iOS dev stuff
export PATH=$HOME/.mint/bin:$PATH


## Unimportant stuff goes at the end
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/lib:$GOPATH/bin:/Users/m0c0j7y/.deno/bin:/opt/cisco/anyconnect/bin:$HOME/dotfiles/bin:$HOME/.mint/bin/"

# sledge:binary path
export SLEDGE_BIN="$HOME/.sledge/bin"
export PATH="${PATH}:${SLEDGE_BIN}"


# cargo
#. "$HOME/.cargo/env"

# make sure this is the last thing
export PATH="$PATH:."

        ;;
esac

### MAN path

export MANPATH="/usr/local/share/man:$MANPATH:"
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";

### fpath stuff for zsh
export FPATH="/opt/homebrew/share/zsh/site-functions:$FPATH"

# pnpm
export PNPM_HOME="/Users/m0c0j7y/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end# setup pyenv

#if command -v pyenv 1>/dev/null 2>&1; then
if false; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
