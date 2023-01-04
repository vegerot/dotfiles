#Path stuff

case ":${PATH}:" in
    *:"$HOME/.cargo/bin":*)
        ;;
    *)

source /etc/zprofile
## important stuff goes first
export PATH="$HOME/.cargo/bin:/usr/local/opt/ruby/bin:$PATH"
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


## Unimportant stuff goes at the end
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/lib:$GOPATH/bin:/opt/cisco/anyconnect/bin:$HOME/dotfiles/bin:$HOME/.mint/bin/"

# sledge:binary path
export SLEDGE_BIN="$HOME/.sledge/bin"
export PATH="${PATH}:${SLEDGE_BIN}"


# cargo
#. "$HOME/.cargo/env"

# make sure this is the last thing
export PATH="$PATH:."

        ;;
esac
