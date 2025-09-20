#Path stuff

#if [[ "$PATH" == *$HOME/.cargo/bin* && -z $ALWAYS_SOURCE_PATHS ]]; then
#	#echo "skipping path stuff"
#	return
#fi

#[[ -f /etc/zprofile ]] && source /etc/zprofile
## important stuff goes first

[[ "$OSTYPE" == "darwin"* ]] && export PATH="/usr/local/bin$HOME/.cargo/bin:/usr/local/opt/ruby/bin:$PATH"

if [[ -d /opt/homebrew ]]; then
	export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/opt/curl/bin:$PATH"
fi
# use self-built Go if present
[[ -x $HOME/workspace/googlesource.com/go/bin/go ]] && export PATH="$HOME/workspace/googlesource.com/go/bin:$PATH"

export PATH="$HOME/bin:$HOME/.local/bin:/sbin:$PATH"


### -----------------------------------
## Unimportant stuff goes at the end
[[ -d $HOME/.cargo/bin ]] && export PATH="$PATH:$HOME/.cargo/bin"
[[ -d /opt/homebrew/opt/rustup ]] && export PATH="$PATH:/opt/homebrew/opt/rustup"

export DENO_INSTALL="$HOME/.deno"
[[ -d $DENO_INSTALL ]] && export PATH="$PATH:$DENO_INSTALL/bin"

export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/lib:$GOPATH/bin:$HOME/dotfiles/bin"

CISCO_BIN="/opt/cisco/anyconnect/bin"
[[ -d $CISCO_BIN ]] && export PATH="$PATH:$CISCO_BIN"

export FZF_BASE="$HOME/workspace/github.com/junegunn/fzf/"
if [[ ! "$PATH" == *$FZF_BASE/bin* ]]; then
	PATH="${PATH:+${PATH}:}$FZF_BASE/bin"
fi

ZIGTOOLS="$HOME/workspace/github.com/zigtools"
if [[ -f $ZIGTOOLS/zls/zig-out/bin/zls ]]; then
	export PATH="$PATH:$ZIGTOOLS/zls/zig-out/bin"
fi
ZIG_14="/opt/homebrew/opt/zig@0.14/bin"
[[ -d $ZIG_14 ]] && export PATH="$PATH:$ZIG_14"


## macOS' toolchain doesn't come with tools like clang-format and clang-tidy
## instead, use LLVM for those tools but stick with the builtin ones otherwise
llvm=/opt/homebrew/opt/llvm/bin
llvm2=/usr/local/opt/llvm/bin
if [[ -d ${llvm} ]]; then
	export PATH="$PATH:${llvm}"
elif [[ -d ${llvm2} ]]; then
	export PATH="$PATH:${llvm2}"
fi

# zig
ZIG="$HOME/.local/zig"
[[ -d $ZIG ]] && export PATH="$PATH:$ZIG"
# Walmart iOS dev stuff
MINT_PATH=$HOME/.mint
[[ -d $MINT_PATH ]] && export PATH="$PATH:$MINT_PATH/bin"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$PATH:$BUN_INSTALL/bin"

# ADB installed by Android Studio
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools/"

# Nvidia CUDA stuff
if [[ -d /usr/local/cuda/bin ]]; then
	export PATH="$PATH:/usr/local/cuda/bin"
fi

# Invoke AI image generation
if [[ -d $HOME/Invoke ]]; then
	export PATH="$PATH:$HOME/Invoke"
fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PATH:$PNPM_HOME" ;;
esac
# pnpm end

# sledge:binary path
#export SLEDGE_BIN="$HOME/.sledge/bin"
#export PATH="${PATH}:${SLEDGE_BIN}"

# cargo
#. "$HOME/.cargo/env"


# make sure this is the last thing
export PATH="$PATH:./node_modules/.bin:."

### -----------------------------------
### MAN path

export MANPATH="/usr/local/share/man:$MANPATH:"
if [[ $OSTYPE == "darwin"* ]]; then
	export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
	export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
fi

### fpath stuff for zsh on macOS
if [[ $SHELL == *"zsh"* && $OSTYPE == "darwin"* && -d /opt/homebrew/share/zsh/site-functions ]]; then
	fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi

#if command -v pyenv 1>/dev/null 2>&1; then
if false; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
if [[ -n ${PYTHONPATH:-} ]] ; then
	export PYTHONPATH="$PYTHONPATH:."
else
	export PYTHONPATH="."
fi

if [[ -d /usr/lib/wsl/lib ]]; then
	if [[ -z ${LD_LIBRARY_PATH:-} ]]; then
		export LD_LIBRARY_PATH="/usr/lib/wsl/lib"
	else
		export LD_LIBRARY_PATH="/usr/lib/wsl/lib:$LD_LIBRARY_PATH"
	fi
fi

