#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${BASHING_REPO_URL:-https://github.com/xavier-sanna/bashing.git}"
START_MARKER='###> bashing ###'
END_MARKER='###< bashing ###'

die() {
	printf '%s\n' "$1" >&2
	exit 1
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

print_gitignore_block() {
	printf '%s\n' "$START_MARKER" '/bashing/' "$END_MARKER"
}

update_gitignore() {
	local gitignore_file="$1"
	local tmp_file="${gitignore_file}.tmp"
	local found=0
	local in_block=0

	: >"$tmp_file"

	if [[ -f "$gitignore_file" ]]; then
		while IFS= read -r line || [[ -n "$line" ]]; do
			if [[ "$line" == "$START_MARKER" ]]; then
				if ((found == 0)); then
					print_gitignore_block >>"$tmp_file"
					found=1
				fi
				in_block=1
				continue
			fi

			if ((in_block)); then
				if [[ "$line" == "$END_MARKER" ]]; then
					in_block=0
				fi
				continue
			fi

			printf '%s\n' "$line" >>"$tmp_file"
		done <"$gitignore_file"
	fi

	if ((found == 0)); then
		if [[ -s "$tmp_file" ]]; then
			printf '\n' >>"$tmp_file"
		fi
		print_gitignore_block >>"$tmp_file"
	fi

	mv "$tmp_file" "$gitignore_file"
}

main() {
	local target_dir="${1:-$PWD}"
	local clone_dir=""
	local install_dir=""

	require_cmd git

	[[ -d "$target_dir" ]] || die "Target directory does not exist: $target_dir"
	target_dir="$(cd -- "$target_dir" >/dev/null 2>&1 && pwd -P)"

	install_dir="$target_dir/bashing"
	clone_dir="$target_dir/.bashing-clone.$$"

	[[ ! -e "$install_dir" ]] || die "Refusing to overwrite existing directory: $install_dir"
	[[ ! -e "$clone_dir" ]] || die "Temporary clone path already exists: $clone_dir"

	cleanup() {
		if [[ -n "$clone_dir" && -d "$clone_dir" ]]; then
			rm -rf "$clone_dir"
		fi
	}
	trap cleanup EXIT

	git clone --quiet --depth 1 "$REPO_URL" "$clone_dir"
	[[ -d "$clone_dir/src" ]] || die "Cloned repository does not contain a src directory."

	mkdir "$install_dir"
	cp -R "$clone_dir/src/." "$install_dir/"

	rm -rf "$clone_dir"
	trap - EXIT

	update_gitignore "$target_dir/.gitignore"

	printf '%s\n' "Installed bashing into $install_dir"
}

main "$@"
