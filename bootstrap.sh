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
        find . \
                -type f \
                ! -path "*/.git/*" \
                ! -path "*/.sl/*" \
                ! -path "./.DS_Store" \
                ! -path "./.osx" \
                ! -path "./bootstrap.sh" \
                ! -path "./brew.sh" \
                ! -path "./README.md" \
                ! -path "./LICENSE-MIT.txt" \
                -exec bash -c 'file=$1; printf "%s -> %s\n" "$HOME/dotfiles/$file" "$HOME/$file"' bash {} \;
}

function force() {
        find . \
                -type f \
                ! -path "*/.git/*" \
                ! -path "*/.sl/*" \
                ! -path "./.DS_Store" \
                ! -path "./.osx" \
                ! -path "./bootstrap.sh" \
                ! -path "./README.md" \
                ! -path "./LICENSE-MIT.txt" \
                -exec bash -xc 'file=$1; cd "$HOME"; mkdir -pv "$(dirname "$file")"; ln -svf "$HOME/dotfiles/$file" "$HOME/$file"' bash {} \;
}

function normal() {
        find . \
                -type f \
                ! -path "*/.git/*" \
                ! -path "*/.sl/*" \
                ! -path "./.DS_Store" \
                ! -path "./.osx" \
                ! -path "./bootstrap.sh" \
                ! -path "./README.md" \
                ! -path "./LICENSE-MIT.txt" \
                -exec bash -xc 'file=$1; cd "$HOME"; mkdir -pv "$(dirname "$file")"; ln -sv "$HOME/dotfiles/$file" "$HOME/$file"' bash {} \;
}

mode=${1:-""}
if [[ $mode == "--force" || $mode == "--dry-run" ]]; then
	doIt "$mode"
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " REPLY
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt "$mode"
	fi
fi
unset doIt
set +x
