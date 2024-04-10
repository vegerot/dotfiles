#!/usr/bin/env bash

# see README.md
# symlink me in `walmart-web/max_scripts_source_on_cd.sh`

function instrument_for_profiling() {
	for profiling_filepath in $(fd --hidden --no-ignore "\.profiling\.min\.js" node_modules); do # replace fd with the corresponding find command if you want
		dir=$(dirname $profiling_filepath)
		file=$(basename $profiling_filepath)
		filename="${file%%.*}"
		extension="${file#*.}"
		PROFILING_EXTENSION="profiling.min.js"
		PROD_EXTENSION="production.min.js"
		production_filepath=$dir/$filename.$PROD_EXTENSION
		if [[ -f $production_filepath ]]; then
			mv -v $production_filepath{,.bkp}
			mv -v $dir/$filename.{$PROFILING_EXTENSION,$PROD_EXTENSION}
		fi
	done
}

function uninstrument_for_profiling() {
	for profiling_filepath in $(fd --hidden --no-ignore "\.production\.min\.js" node_modules); do # replace fd with the corresponding find command if you want
		dir=$(dirname $profiling_filepath)
		file=$(basename $profiling_filepath)
		filename="${file%%.*}"
		extension="${file#*.}"
		PROFILING_EXTENSION="profiling.min.js"
		PROD_EXTENSION="production.min.js.bkp"
		PROD_BKP_EXTENSION="production.min.js.bkp"
		production_bkp_filepath=$dir/$filename.$PROD_BKP_EXTENSION
		if [[ -f $production_bkp_filepath ]]; then
			mv -v $dir/$filename.{$PROD_EXTENSION,$PROFILING_EXTENSION}
			mv -v $dir/$filename.{$PROD_BKP_EXTENSION,$PROD_EXTENSION}
		fi
	done
}

function debug() {
	if [[ -z $QUIET ]]; then return; fi
	echo "$@"
}


SetWebCerts() {
	export NODE_EXTRA_CA_CERTS="/tmp/mega.pem"
	if [ ! -f $NODE_EXTRA_CA_CERTS ]; then
		security find-certificate -a -p /Library/Keychains/System.keychain > $NODE_EXTRA_CA_CERTS
	fi
}

function vanilla_nvm_use() {
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
	nvm use $@
}

function fast_nvm_use() {
	local has_nvmrc_file=$([[ -f .nvmrc ]]&& true || false)

	if [[ $has_nvmrc == false ]]; then
		debug "not setting up fast nvm because no nvmrc is found"
		debug "make sure you have a .nvmrc file in the current directory"
		debug "TODO: soon we will support searching upwards for the file"
		return 1
	fi
	export NVM_DIR="$HOME/.nvm/"
	local nvm_versions_dir="$NVM_DIR/versions/node/"
	# TODO: search upwards for `.nvmrc`
	local node_version="$(cat .nvmrc)"
	local node_path="$nvm_versions_dir/$node_version"

	if [[ ! -d "$node_path" ]]; then
		debug "not setting up fast nvm because can't find the requested node version"
		debug "doing slow version instead 🐢"
		vanilla_nvm_use "$@"
		return 1
	fi

	export PATH="$node_path/bin:$PATH"
	export MANPATH="$node_path/share/man:$MANPATH"

	SetWebCerts
}

function nvmuse() {
	fast_nvm_use "$@"
}

function setUpNvmIfNotSetUp() {
	local has_nvmrc_file=$([[ -f .nvmrc ]]&& true || false)

	if [[ $has_nvmrc == false ]]; then
		debug "not setting up nvm because requirement is missing"
		return
	fi

	local got_version=$(command node --version 2>/dev/null)
	local want_version=$(cat .nvmrc)

	if [[ $got_version != $want_version ]]; then
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
	setUpNvmIfNotSetUp
	command $*
}

function node() {
	node_nvm_wrapper $0 $*
}

function pnpm() {
	node_nvm_wrapper $0 $*
}

function pnpx() {
	node_nvm_wrapper $0 $*
}

alias gc="setUpNvmIfNotSetUp && git commit"
