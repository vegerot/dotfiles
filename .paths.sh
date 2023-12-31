#Path stuff

if [[ "$PATH" == *$HOME/.cargo/bin* && -z $ALWAYS_SOURCE_PATHS ]]; then
	echo "skipping path stuff"
	return
fi

[[ -f /etc/zprofile ]] && source /etc/zprofile
## important stuff goes first
export PATH="$HOME/.cargo/bin:$PATH"

[[ "$OSTYPE" == "darwin"* ]] && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.cargo/bin:/usr/local/opt/ruby/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# Walmart iOS dev stuff
MINT_PATH=$HOME/.mint
[[ -d $MINT_PATH ]] && export PATH=$MINT_PATH/bin:$PATH


## Unimportant stuff goes at the end
export DENO_INSTALL="$HOME/.deno"
[[ -d $DENO_INSTALL ]] && export PATH="$PATH:$DENO_INSTALL/bin"

export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/lib:$GOPATH/bin:/Users/m0c0j7y/.deno/bin:/opt/cisco/anyconnect/bin:$HOME/dotfiles/bin:$HOME/.mint/bin/"

CISCO_BIN="/opt/cisco/anyconnect/bin"
[[ -d $CISCO_BIN ]] && export PATH="$PATH:$CISCO_BIN"

export FZF_BASE="$HOME/workspace/github.com/junegunn/fzf/"
if [[ ! "$PATH" == *$FZF_BASE/bin* ]]; then
	PATH="${PATH:+${PATH}:}$FZF_BASE/bin"
fi

## macOS' toolchain doesn't come with tools like clang-format and clang-tidy
## instead, use LLVM for those tools but stick with the builtin ones otherwise
local llvm=/opt/homebrew/opt/llvm/bin
if [[ -d ${llvm} ]]; then
	export PATH="$PATH:${llvm}"
fi

# ADB installed by Android Studio
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools/"

# pnpm
export PNPM_HOME="/home/max/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# sledge:binary path
export SLEDGE_BIN="$HOME/.sledge/bin"
export PATH="${PATH}:${SLEDGE_BIN}"


# cargo
#. "$HOME/.cargo/env"

# make sure this is the last thing
export PATH="$PATH:."

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
