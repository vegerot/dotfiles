#!/usr/bin/env zsh
# zsh 5.9+ only. Sourced by `source_max_scripts` in .zshrc.
# Do not use bare glob qualifiers like `*(NOn)` here: some zsh instances run
# with `nobareglobqual`, which turns them into literal filename characters.

function debug() {
	if [[ -z ${VERBOSE:-} ]]; then return; fi
	echo "$@"
}

function vanilla_nvm_use() {
	set +x
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
	nvm use "$@"
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
	local has_nvmrc=$([[ -f $nvmrc ]] && echo true || echo false)

	if [[ $has_nvmrc == false ]]; then
		debug "not setting up fast nvm because no nvmrc is found"
		debug "make sure you have a .nvmrc file in this directory or a parent"
		vanilla_nvm_use "$@"
		return 1
	fi
	export NVM_DIR="$HOME/.nvm/"

	local nvm_versions_dir="$NVM_DIR/versions/node/"
	local node_version="$(<$nvmrc)"
	if [[ -z $node_version ]]; then
		# else the pattern below degrades to `?*` and silently picks the newest
		debug "not setting up fast nvm because .nvmrc is empty"
		vanilla_nvm_use "$@"
		return 1
	fi

	# `find` rather than a glob, for three reasons: no `eval` (`.nvmrc` is
	# untrusted input), an unmatched glob is fatal in zsh, and glob qualifiers
	# need `bareglobqual`, which is off in some zsh instances.
	local node_paths=($(find "$nvm_versions_dir" -mindepth 1 -maxdepth 1 -type d -name "?$node_version*" 2>/dev/null | sort --version-sort --reverse))
	local node_path="${node_paths[1]:-}"

	if [[ ! -d $node_path ]]; then
		debug "not setting up fast nvm because can't find the requested node version"
		debug "doing slow version instead 🐢"
		vanilla_nvm_use "$@"
		return 1
	fi

	export PATH="$node_path/bin:$PATH"
	export MANPATH="$node_path/share/man:${MANPATH:-}"
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

	# this starts Node only to read its version. That is ~29ms of the ~36ms
	# wrapper overhead. See the benchmark note below for why we keep it.
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

# Measured again 2026-08-12, in a repo with `.nvmrc` = 18.20.8. ⏱️
#
#   command node --version   (no wrapper)   31 ms
#   node --version           (wrapped)      67 ms   = 2.16x
#
# Cost per call: the Node version probe ~29ms, `find` + `sort` ~10ms, the
# subshell fork ~1ms, and each `get_nvmrc` tree walk ~1ms. So the probe is
# almost all of it. The wrapper starts Node twice: once to ask the version,
# once to do the work.
#
# You can delete the probe and gate on PATH instead, which cuts the overhead
# from ~36ms to ~7ms:
#
#   case ":$PATH:" in *"/versions/node/v$want_version/bin:"*) return ;; esac
#
# We chose NOT to do this. Only direct shell calls pay the cost. A child
# process of a wrapped command inherits the fixed PATH, so `pnpm test` pays
# ~30ms once, not once per Node process. 30ms is below what a human notices,
# and it disappears next to pnpm's own startup. The extra gate is more code
# and one more thing to get wrong.
#
# Revisit this only if you call `node` in a shell loop. There the cost
# multiplies: 500 iterations pays ~15s.

function node_nvm_wrapper() {
	(
		set -o nounset
		set -o pipefail
		setUpNvmIfNotSetUp
		set +o nounset
		set +o pipefail

		command "$@"
	)
}

function node() {
	node_nvm_wrapper node "$@"
}

function pnpm() {
	node_nvm_wrapper pnpm "$@"
}

function yarn() {
	node_nvm_wrapper yarn "$@"
}

function pnpx() {
	node_nvm_wrapper pnpx "$@"
}

function emo() {
	node_nvm_wrapper emo "$@"
}
