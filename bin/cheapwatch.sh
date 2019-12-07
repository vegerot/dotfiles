#!/bin/sh

# Not quite your Rolex

while true ; do
	clear
	printf "[%s] Output of %s:\n" "$(date)" "$*"
	# "$@" <- we don't want to do it this way, just this:
	${SHELL-/bin/sh} -c "$*"
	sleep 1  # genuine Quartz movement
done

