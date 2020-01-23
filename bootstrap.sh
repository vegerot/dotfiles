#!/usr/bin/env bash

set -o xtrace

function doIt() {
    if [ "$1" "==" "--dry-run" ]; then
        find . -type f -not -path "*/.git/*" -not -path "./.DS_Store" -not -path "./.osx" -not -path "./bootstrap.sh" -not -path "./brew.sh" -not -path "*/node_modules/*" -not -path "./README.md" -not -path "./LICENSE-MIT.txt" -exec echo ~/dotfiles/'{}' "->" ~/'{}' \;
    elif [ "$1" "==" "--force" ]; then
	    find . -type f -not -path "*/.git/*" -not -path "./init" -not -path "./brew.sh" -not -path "./.DS_Store" -not -path "./.macos" -not -path "./bootstrap.sh" -not -path "*/node_modules/*" -not -path "./README.md" -not -path "./LICENSE-MIT.txt" -exec sh -c 'file="{}"; mkdir -pv $HOME/${file%/*}/; ln -fsv ~/dotfiles/$file ~/$file' \;
    else
        echo "NOTE: This will not overwrite any existing files.  Rerun with --force to overwrite existing dotfiles"
        find . -type f -not -path "*/.git/*" -not -path "./.DS_Store" -not -path "./.osx" -not -path "./bootstrap.sh" -not -path "*/node_modules/*" -not -path "./README.md" -not -path "./LICENSE-MIT.txt" -exec mkdir -pv $(dirname {}) \; -exec ln -sv ~/dotfiles/'{}' ~/'{}' \;
    fi
    set +x
	source ~/.bash_profile;
}

if [[ "$1" == "--force" ]]; then
	doIt --force;
else
	read "REPLY?This may overwrite existing files in your home directory. Are you sure? (y/n) ";
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt $1;
	fi;
fi;
unset doIt;
set +x
