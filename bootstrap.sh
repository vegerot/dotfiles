#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function doIt() {
    find . -type f -not -path "*/.git/*" -not -path "./.DS_Store" -not -path "./.osx" -not -path "./bootstrap.sh" -not -path "./README.md" -not -path "./LICENSE-MIT.txt" -exec ln -s '{}' ~/'{}' \;
	source ~/.zshrc;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
