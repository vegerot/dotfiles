#!/usr/bin/env bash

set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

function doIt() {
    if [ "$1" "==" "--dry-run" ]; then
	dry_run
    elif [ "$1" "==" "--force" ]; then
        echo "forced"
	force
    else
        echo "NOTE: This will not overwrite any existing files.  Rerun with --force to overwrite existing dotfiles"
	normal
    fi
    set +x
}

function dry_run() {
        find . -type f -not -path "*/.git/*" -not -path "./.DS_Store" -not -path "./.osx" -not -path "./bootstrap.sh" -not -path "./brew.sh" -not -path "./README.md" -not -path "./LICENSE-MIT.txt" -exec echo ~/dotfiles/'{}' "->" ~/'{}' \;
}

function force() {
        find . -type f -not -path "*/.git/*" -not -path "*/.sl/*" -not -path "./.DS_Store" -not -path "./.osx" -not -path "./bootstrap.sh" -not -path "./README.md" -not -path "./LICENSE-MIT.txt" | xargs -I{} bash -xc 'cd $HOME; mkdir -pv $(dirname {}) ; ln --symbolic --verbose --force ~/dotfiles/{} ~/{};'
}

function normal() {
        find . -type f -not -path "*/.git/*" -not -path "*/.sl/*" -not -path "./.DS_Store" -not -path "./.osx" -not -path "./bootstrap.sh" -not -path "./README.md" -not -path "./LICENSE-MIT.txt" | xargs -I{} bash -xc 'cd $HOME; mkdir -pv $(dirname {}) ; ln --symbolic --verbose ~/dotfiles/{} ~/{};'
}

force = ${1:-""}
if [[ $force == "--force" ]]; then
		doIt $force;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " REPLY
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt $force;
	fi;
fi;
unset doIt;
set +x
