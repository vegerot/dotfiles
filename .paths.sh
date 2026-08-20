#Path stuff

#case ":$PATH:" in *":$HOME/.cargo/bin:"*) [ -z "${ALWAYS_SOURCE_PATHS:-}" ] && return ;; esac
#	#echo "skipping path stuff"
#	return
#esac

#[ -f /etc/zprofile ] && . /etc/zprofile
## important stuff goes first

case "$(uname -s)" in
	Darwin) export PATH="/usr/local/bin$HOME/.cargo/bin:/usr/local/opt/ruby/bin:$PATH" ;;
esac

if [ -d /opt/homebrew ]; then
	export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/opt/curl/bin:$PATH"
fi
# use self-built Go if present
[ -x "$HOME/workspace/googlesource.com/go/bin/go" ] && export PATH="$HOME/workspace/googlesource.com/go/bin:$PATH"

export PATH="$HOME/bin:$HOME/.local/bin:/sbin:$PATH"

# My own scripts. This goes before /usr/bin on purpose: `cc` here is the Claude
# Code helper, and it must win over /usr/bin/cc, the C compiler.
[ -d "$HOME/.claude/my-scripts" ] && export PATH="$HOME/.claude/my-scripts:$PATH"


### -----------------------------------
## Unimportant stuff goes at the end
[ -d /usr/games ] && export PATH="$PATH:/usr/games"
[ -d "$HOME/.cargo/bin" ] && export PATH="$PATH:$HOME/.cargo/bin"
[ -d /opt/homebrew/opt/rustup ] && export PATH="$PATH:/opt/homebrew/opt/rustup"

export DENO_INSTALL="$HOME/.deno"
[ -d "$DENO_INSTALL" ] && export PATH="$PATH:$DENO_INSTALL/bin"

export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/lib:$GOPATH/bin:$HOME/dotfiles/bin"

CISCO_BIN="/opt/cisco/anyconnect/bin"
[ -d "$CISCO_BIN" ] && export PATH="$PATH:$CISCO_BIN"

export FZF_BASE="$HOME/workspace/github.com/junegunn/fzf/"
case ":$PATH:" in
	*":$FZF_BASE/bin:"*) ;;
	*) PATH="${PATH:+${PATH}:}$FZF_BASE/bin" ;;
esac

ZIGTOOLS="$HOME/workspace/github.com/zigtools"
if [ -f "$ZIGTOOLS/zls/zig-out/bin/zls" ]; then
	export PATH="$PATH:$ZIGTOOLS/zls/zig-out/bin"
fi
ZIG_14="/opt/homebrew/opt/zig@0.14/bin"
[ -d "$ZIG_14" ] && export PATH="$PATH:$ZIG_14"


## macOS' toolchain doesn't come with tools like clang-format and clang-tidy
## instead, use LLVM for those tools but stick with the builtin ones otherwise
llvm=/opt/homebrew/opt/llvm/bin
llvm2=/usr/local/opt/llvm/bin
if [ -d "$llvm" ]; then
	export PATH="$PATH:${llvm}"
elif [ -d "$llvm2" ]; then
	export PATH="$PATH:${llvm2}"
fi

# zig
ZIG="$HOME/.local/zig"
[ -d "$ZIG" ] && export PATH="$PATH:$ZIG"
# Walmart iOS dev stuff
MINT_PATH=$HOME/.mint
[ -d "$MINT_PATH" ] && export PATH="$PATH:$MINT_PATH/bin"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$PATH:$BUN_INSTALL/bin"

# adb
if [ -d "$HOME/Library/Android/sdk/platform-tools/" ]; then
	export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
elif [ -d "$HOME/Android/Sdk/platform-tools/" ]; then
	export PATH="$PATH:$HOME/Android/Sdk/platform-tools"
elif [ -d "$HOME/.local/bin/android-platform-tools/" ]; then
	export PATH="$PATH:$HOME/.local/bin/android-platform-tools"
fi

if [ -d "/opt/google/android-studio/bin/" ]; then
	export PATH="$PATH:/opt/google/android-studio/bin"
fi

if [ -d "/opt/google/antigravity/" ]; then
	export PATH="$PATH:/opt/google/antigravity"
fi

[ -d "$HOME/.atuin/bin/" ] && export PATH="$HOME/.atuin/bin:$PATH"

# Nvidia CUDA stuff
if [ -d /usr/local/cuda/bin ]; then
	export PATH="$PATH:/usr/local/cuda/bin"
fi

# Invoke AI image generation
if [ -d "$HOME/Invoke" ]; then
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

if [ -d "$HOME/.npm-global/bin" ]; then
	export PATH="$PATH:$HOME/.npm-global/bin"
fi


# ByteDance devbox: AIME ships its own socat build, and ~/.ssh/config needs it
# on PATH for the ProxyCommand that reaches internal cube-* hosts. The devbox's
# stock ~/.bashrc exports this, but ~/.bashrc returns early for non-interactive
# shells, so ssh's ProxyCommand never saw it. Setting it here covers login
# shells too. No-op on machines without ~/.aime.
#
# On a glob with no matches, bash keeps the pattern, so the -d test drops it.
# zsh prints an error instead (NOMATCH), which aborts this file. NULL_GLOB
# removes the pattern and overrides NOMATCH. LOCAL_OPTIONS restores both when
# the function returns, so neither option leaks into the shell.
_aime_socat_path() {
	[ -n "${ZSH_VERSION:-}" ] && setopt local_options null_glob

	local dir
	for dir in "$HOME"/.aime/socat-*-linux; do
		[ -d "$dir" ] && export PATH="$PATH:$dir"
	done
}
_aime_socat_path
unset -f _aime_socat_path

# make sure this is the last thing
export PATH="$PATH:./node_modules/.bin:."

### -----------------------------------
### MAN path

export MANPATH="/usr/local/share/man:${MANPATH:-}:"
case "$(uname -s)" in
Darwin)
	export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
	export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
	;;
esac
if [ -d "$HOME/.local/share/man/" ]; then
	export MANPATH="$MANPATH:$HOME/.local/share/man"
fi

### fpath stuff for zsh on macOS
case "${SHELL:-}:$(uname -s)" in
	*zsh:Darwin)
		if [ -d /opt/homebrew/share/zsh/site-functions ]; then
			FPATH="/opt/homebrew/share/zsh/site-functions${FPATH:+:$FPATH}"
		fi
		;;
esac

#if command -v pyenv 1>/dev/null 2>&1; then
if false; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
if [ -n "${PYTHONPATH:-}" ] ; then
	export PYTHONPATH="$PYTHONPATH:."
else
	export PYTHONPATH="."
fi

if [ -d /usr/lib/wsl/lib ]; then
	if [ -z "${LD_LIBRARY_PATH:-}" ]; then
		export LD_LIBRARY_PATH="/usr/lib/wsl/lib"
	else
		export LD_LIBRARY_PATH="/usr/lib/wsl/lib:$LD_LIBRARY_PATH"
	fi
fi

if [ -d /opt/homebrew/include ]; then
	export CPATH="/opt/homebrew/include:${CPATH:-}"
fi
if [ -d /opt/homebrew/lib ]; then
	export LIBRARY_PATH="/opt/homebrew/lib:${LIBRARY_PATH:-}"
fi

