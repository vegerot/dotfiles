function get_cmd_and_abbreviate_it {
	local cmd="$1"
	local res=$(eval $cmd)
	local abbreviated=$(abbreviate_paths "$res")
	printf "$abbreviated"
	return
}

abbreviate_path() {
	local file_path="$1"
	local path_dir=$(dirname $file_path)
	IFS=/ read -ra path_parts <<< "$path_dir"
	local filename=$(basename $file_path)
	local abbreviated=""
	for part in "${path_parts[@]}"; do
		abbreviated+="${part:0:1}/"
	done
	abbreviated="${abbreviated%/}/$filename"
	printf "$abbreviated "

}
abbreviate_paths() {
	# vim foo/bar/baz.txt -> vim f/b/baz.txt

	local args=($1)
	for arg in ${args[@]}; do
		# only abbreviate files
		if [[ -a $arg ]]; then
			abbreviate_path "$arg"
		else printf "$arg "
		fi
	done
	printf "\n"
	return
}

