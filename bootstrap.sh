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
                \( -type f -o -type l \) \
                ! -path "*/.git/*" \
                ! -path "*/.sl/*" \
                ! -path "./.claude/worktrees/*" \
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
                \( -type f -o -type l \) \
                ! -path "*/.git/*" \
                ! -path "*/.sl/*" \
                ! -path "./.claude/worktrees/*" \
                ! -path "./.DS_Store" \
                ! -path "./.osx" \
                ! -path "./bootstrap.sh" \
                ! -path "./README.md" \
                ! -path "./LICENSE-MIT.txt" \
                -exec bash -xc '
                    file=$1
                    cd "$HOME"
                    directory=$(dirname "$file")
                    destination="$HOME/$file"
                    mkdir -pv "$directory"
                    # A linked parent directory can make the destination the source itself.
                    # Compare parents so this also protects dangling source symlinks.
                    if [[ "$HOME/dotfiles/$directory" -ef "$HOME/$directory" ]]; then
                        printf "Already linked: %s\n" "$destination"
                        exit 0
                    fi
                    if [[ -d "$destination" && ! -L "$destination" ]]; then
                        printf "Refusing to replace directory: %s\n" "$destination" >&2
                        exit 1
                    fi
                    ln -svfn "$HOME/dotfiles/$file" "$destination"
                ' bash {} \;
        rm -f ~/AGENTS.md
}

function normal() {
        find . \
                \( -type f -o -type l \) \
                ! -path "*/.git/*" \
                ! -path "*/.sl/*" \
                ! -path "./.claude/worktrees/*" \
                ! -path "./.DS_Store" \
                ! -path "./.osx" \
                ! -path "./bootstrap.sh" \
                ! -path "./README.md" \
                ! -path "./LICENSE-MIT.txt" \
                -exec bash -xc '
                    file=$1
                    cd "$HOME"
                    destination="$HOME/$file"
                    mkdir -pv "$(dirname "$file")"
                    if [[ -d "$destination" && ! -L "$destination" ]]; then
                        printf "Skipping existing directory: %s\n" "$destination"
                        exit 0
                    fi
                    ln -svn "$HOME/dotfiles/$file" "$destination"
                ' bash {} \;
        rm -f ~/AGENTS.md
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
