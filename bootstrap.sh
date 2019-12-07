#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function doIt() {
    find . -type f -not -path "*/.git/*" -not -path "./.DS_Store" -not -path "./.osx" -not -path "./bootstrap.sh" -not -path "./README.md" -not -path "./LICENSE-MIT.txt" -exec echo '{}' "->" ~/'{}' \;
	source ~/.zshrc;
}

if [[ "$1" == "--force" ]]; then
	doIt;
else
	read "REPLY?This may overwrite existing files in your home directory. Are you sure? (y/n) ";
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
