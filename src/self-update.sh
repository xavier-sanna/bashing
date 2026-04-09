#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${BASHING_REPO_URL:-https://github.com/xavier-sanna/bashing.git}"

die() {
	printf '%s\n' "$1" >&2
	exit 1
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

resolve_dir() {
	CDPATH='' cd -- "$1" >/dev/null 2>&1 && pwd -P
}

main() {
	local script_dir=""
	local project_dir=""
	local clone_dir=""
	local new_dir=""
	local backup_dir=""

	require_cmd git

	script_dir="$(resolve_dir "$(dirname -- "${BASH_SOURCE[0]}")")" ||
		die "Unable to resolve bashing installation directory."
	project_dir="$(resolve_dir "$script_dir/..")" ||
		die "Unable to resolve project directory."

	[[ "$(basename -- "$script_dir")" == "bashing" ]] ||
		die "self-update.sh must be run from an installed bashing directory."

	clone_dir="$project_dir/.bashing-update-clone.$$"
	new_dir="$project_dir/.bashing-update-new.$$"
	backup_dir="$project_dir/.bashing-update-backup.$$"

	[[ ! -e "$clone_dir" ]] || die "Temporary clone path already exists: $clone_dir"
	[[ ! -e "$new_dir" ]] || die "Temporary update path already exists: $new_dir"
	[[ ! -e "$backup_dir" ]] || die "Temporary backup path already exists: $backup_dir"

	cleanup() {
		rm -rf "$clone_dir" "$new_dir"
	}
	trap cleanup EXIT

	git clone --quiet --depth 1 "$REPO_URL" "$clone_dir"
	[[ -d "$clone_dir/src" ]] || die "Cloned repository does not contain a src directory."

	mkdir "$new_dir"
	cp -R "$clone_dir/src/." "$new_dir/"

	mv "$script_dir" "$backup_dir"
	if ! mv "$new_dir" "$script_dir"; then
		mv "$backup_dir" "$script_dir"
		die "Unable to replace bashing installation."
	fi

	rm -rf "$backup_dir" "$clone_dir"
	trap - EXIT

	printf '%s\n' "Updated bashing in $script_dir"
}

main "$@"
