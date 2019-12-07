#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed programs
~/bin/update.sh

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
brew install coreutils

# Install GnuPG to enable PGP-signing commits.
#brew install gnupg
# Install gnu tools
brew install grep
brew install bash
brew install zsh
brew install awk
brew install gawk
brew install make
brew install cmake
brew install diffutils
brew install gnu-tar
brew install gnu-time
brew install gnu-which

# Install programming tools
brew install check
brew install llvm
brew install clang-format
brew install node
brew install python3
brew install perl

# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names
# Install a modern version of zsh
brew install zsh
brew install bash-completion2
brew install zsh-completions
brew install zsh-lovers
brew install zsh-syntax-highlighting

# Switch to using brew-installed zsh as default shell
if ! fgrep -q "${BREW_PREFIX}/bin/zsh" /etc/shells; then
  echo "${BREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/zsh";
fi;

# Install some other useful utilities like `sponge`.
brew install moreutils


# Install `wget` with IRI support.
brew install wget --with-iri
brew install curl


# Install more recent versions of some macOS tools.
brew install macvim --with-override-system-vi
brew install neovim
brew install openssh
brew install tmux
brew install php
brew install gmp

# Install some CTF tools; see https://github.com/ctfs/write-ups.
brew install binutils
brew install nmap
brew install xz

# Install other useful binaries.
brew install ack
brew install git
brew install git-lfs
brew install imagemagick --with-webp
brew install lua
brew install lynx
brew install pv
brew install rename
brew install ssh-copy-id
brew install rsync
brew install tree
brew install dos2unix
brew install htop

# Do less
brew install less

# fun stuff
brew install fzf
brew install ripgrep
brew install lolcat

#Install Casks
brew cask install iterm
brew cask install font-hack-nerd-font
brew cask install intel-power-gadget
brew cask install karabiner-elements
brew casks install xquartz
# Remove outdated versions from the cellar.
brew cleanup
