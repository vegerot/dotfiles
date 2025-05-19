#!/usr/bin/env bash


function debug() {
	if [[ -z ${VERBOSE:-} ]]; then return; fi
	echo "$@"
}

function vanilla_nvm_use() {
	set +x
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
	nvm use $@
}

function get_nvmrc() {
	find-up() {
		local current_path
		current_path=$(pwd)/
		# bug: this won't search /.nvmrc
		while [[ -n $current_path && "$current_path" != "/" ]]; do
			if [[ -e $current_path/$1 ]]; then
				echo $current_path/$1
				return
			fi
			current_path=${current_path%/*/}/
		done
	}
	find-up .nvmrc
}

function fast_nvm_use() {
	local nvmrc=$(get_nvmrc)
	local has_nvmrc=$([[ -f $nvmrc ]] && true || false)

	if [[ $has_nvmrc == false ]]; then
		debug "not setting up fast nvm because no nvmrc is found"
		debug "make sure you have a .nvmrc file in the current directory"
		debug "TODO: soon we will support searching upwards for the file"
		vanilla_nvm_use "$@"
		return 1
	fi
	export NVM_DIR="$HOME/.nvm/"

	local nvm_versions_dir="$NVM_DIR/versions/node/"
	# TODO: search upwards for `.nvmrc`
	local node_version="$(<$nvmrc)"
	local node_paths=($(eval echo "$nvm_versions_dir/?$node_version*" | tr ' ' '\n' | sort --version-sort --reverse))
	local node_path="${node_paths[1]:-''}"

	if [[ ! -d $node_path ]]; then
		debug "not setting up fast nvm because can't find the requested node version"
		debug "doing slow version instead 🐢"
		vanilla_nvm_use "$@"
		return 1
	fi

	export PATH="$node_path/bin:$PATH"
	export MANPATH="$node_path/share/man:$MANPATH"
}

function nvmuse() {
	fast_nvm_use "$@"
}

function setUpNvmIfNotSetUp() {
	local has_nvmrc=$([[ -f $(get_nvmrc) ]]&& echo true || echo false)

	if [[ $has_nvmrc == false ]]; then
		debug "not setting up nvm because requirement is missing"
		return
	fi

	local got_version=$(command node --version 2>/dev/null)
	local want_version=$(<$(get_nvmrc))

	if [[ $got_version != *$want_version* ]]; then
		debug "changing PATH to Node $want_version from Node $got_version"
		nvmuse
		return
	fi
}

# acceptable overhead: ~20ms slower
# ```sh
# ❯ hyperfine \
#          "source ../../max_scripts_source_on_cd.sh && command node --version"\
#          "source ../../max_scripts_source_on_cd.sh && node --version"
# Benchmark 1: source ../../max_scripts_source_on_cd.sh && command node --version
#   Time (mean ± σ):      31.4 ms ±   2.3 ms    [User: 18.0 ms, System: 5.1 ms]
#   Range (min … max):    28.3 ms …  39.9 ms    80 runs
#
# Benchmark 2: source ../../max_scripts_source_on_cd.sh && node --version
#   Time (mean ± σ):      48.6 ms ±   2.9 ms    [User: 19.7 ms, System: 12.1 ms]
#   Range (min … max):    44.6 ms …  56.3 ms    48 runs
#
# Summary
#   source ../../max_scripts_source_on_cd.sh && command node --version ran
#     1.54 ± 0.15 times faster than source ../../max_scripts_source_on_cd.sh && node --version
#```

function node_nvm_wrapper() {
	(
		set -o nounset
		set -o pipefail
		setUpNvmIfNotSetUp
		set +o errexit
		set +o nounset
		set +o pipefail

		command $*
	)
}

function node() {
	node_nvm_wrapper node $*
}

function pnpm() {
	node_nvm_wrapper $0 $*
}

function yarn() {
	node_nvm_wrapper $0 $*
}

function pnpx() {
	node_nvm_wrapper $0 $*
}

function emo() {
	node_nvm_wrapper $0 $*
}
