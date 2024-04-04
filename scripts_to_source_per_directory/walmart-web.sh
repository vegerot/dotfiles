#!/usr/bin/env sh

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

function setUpNvmIfNotExists() {
	local has_nvmrc_file=$([[ -f .nvmrc ]]&& true || false)
	# this comes from ~/.sh_functions
	local has_nvmuse=$(command -v nvmuse) && true || false

	if [[ $has_nvmrc == false || $has_nvmuse == false ]]; then
		echo "not setting up nvm because requirement is missing"
		return
	fi

	local got_version=$(command node --version 2>/dev/null)
	local want_version=$(cat .nvmrc)

	if [[ $got_version != $want_version ]]; then
		nvmuse
	fi
}

# acceptable overhead: ~17ms slower
# ```sh
# ❯ hyperfine \
#         "source ../../../max_scripts_source_on_cd.sh && command node --version"\
#         "source ../../../max_scripts_source_on_cd.sh && node --version"
# Benchmark 1: source ../../../max_scripts_source_on_cd.sh && command node --version
#   Time (mean ± σ):      16.2 ms ±   4.8 ms    [User: 7.6 ms, System: 1.9 ms]
#   Range (min … max):     6.9 ms …  37.5 ms    161 runs
#
# Benchmark 2: source ../../../max_scripts_source_on_cd.sh && node --version
#   Time (mean ± σ):      33.2 ms ±   6.4 ms    [User: 9.0 ms, System: 6.8 ms]
#   Range (min … max):    21.4 ms …  51.3 ms    66 runs
#
# Summary
#   source ../../../max_scripts_source_on_cd.sh && command node --version ran
#     2.05 ± 0.73 times faster than source ../../../max_scripts_source_on_cd.sh && node --version
#```

function node_nvm_wrapper() {
	setUpNvmIfNotExists
	command $*
}

function node() {
	node_nvm_wrapper $0 $*
}

function pnpm() {
	node_nvm_wrapper $0 $*
}

alias gc="setUpNvmIfNotExists && git commit"
