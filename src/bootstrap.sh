#!/usr/bin/env bash

if [[ -n "${__BASHLIB_BOOTSTRAP:-}" ]]; then
	if (return 0 2>/dev/null); then
		return 0
	fi
	exit 0
fi
__BASHLIB_BOOTSTRAP=1

__bashlib_bootstrap_fail() {
	printf '%s\n' "$1" >&2
}

__bashlib_bootstrap_resolve_dir() {
	CDPATH='' cd -- "$1" >/dev/null 2>&1 && pwd -P
}

__bashlib_bootstrap_find_project_root() {
	local dir="$1"
	local parent

	while :; do
		if [[ -e "$dir/.git" || -f "$dir/mise.toml" || -f "$dir/docker-compose.yaml" ]]; then
			printf '%s' "$dir"
			return 0
		fi

		parent="$(dirname -- "$dir")"
		[[ "$parent" != "$dir" ]] || break
		dir="$parent"
	done

	return 1
}

__bashlib_bootstrap_caller="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
BASHLIB_ROOT="$(__bashlib_bootstrap_resolve_dir "$(dirname -- "${BASH_SOURCE[0]}")")" || {
	__bashlib_bootstrap_fail "Unable to resolve bash library root from ${BASH_SOURCE[0]}"
	if (return 0 2>/dev/null); then
		return 1
	fi
	exit 1
}
TASKS_ROOT="$(__bashlib_bootstrap_resolve_dir "$BASHLIB_ROOT/..")" || {
	__bashlib_bootstrap_fail "Unable to resolve tasks root from $BASHLIB_ROOT"
	if (return 0 2>/dev/null); then
		return 1
	fi
	exit 1
}
TASK_DIR="$(__bashlib_bootstrap_resolve_dir "$(dirname -- "$__bashlib_bootstrap_caller")")" || {
	__bashlib_bootstrap_fail "Unable to resolve task directory for $__bashlib_bootstrap_caller"
	if (return 0 2>/dev/null); then
		return 1
	fi
	exit 1
}
# shellcheck disable=SC2034 # Public variable exported into the sourcing script.
TASK_FILE="$TASK_DIR/$(basename -- "$__bashlib_bootstrap_caller")"
# shellcheck disable=SC2034 # Public variable exported into the sourcing script.
PROJECT_ROOT="$(__bashlib_bootstrap_find_project_root "$TASKS_ROOT")" || {
	__bashlib_bootstrap_fail "Unable to resolve project root from $TASKS_ROOT"
	if (return 0 2>/dev/null); then
		return 1
	fi
	exit 1
}

# shellcheck source=./load.sh
# shellcheck disable=SC1091
source "$BASHLIB_ROOT/load.sh"
