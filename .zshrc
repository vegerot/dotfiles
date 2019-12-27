#!/usr/bin/env zsh
#
ZSHRC="$HOME/"bin/zshrc
source $ZSHRC

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/matt/.sdkman"
[[ -s "/Users/matt/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/matt/.sdkman/bin/sdkman-init.sh"

export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
