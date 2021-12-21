#Path stuff

## important stuff goes first
export PATH="/usr/local/opt/ruby/bin:$PATH"


## Unimportant stuff goes at the end
export PATH="$PATH:/usr/local/lib:$HOME/go/bin:/opt/cisco/anyconnect/bin:$HOME/dotfiles/bin:$HOME/.mint/bin"

# sledge:binary path
export SLEDGE_BIN=/Users/m0c0j7y/.sledge/bin
export PATH="${PATH}:${SLEDGE_BIN}"

# make sure this is the last thing
export PATH="$PATH:."

