#!/usr/bin/env bash
# load.sh — single entrypoint to source bashlib modules safely (idempotent)

# Guard against re-sourcing
if [[ -n "${__BASHLIB_LOADED:-}" ]]; then
	if (return 0 2>/dev/null); then
		return 0
	fi
	exit 0
fi
__BASHLIB_LOADED=1

# Resolve this file’s directory (portable macOS/Linux)
__bashlib_readlink() {
	local target="$1"
	while [[ -L "$target" ]]; do
		local dir
		dir=$(cd -P -- "$(dirname -- "$target")" && pwd)
		if ! target=$(command readlink -- "$target" 2>/dev/null); then
			target=$(command readlink "$target") || return 1
		fi
		[[ $target != /* ]] && target="$dir/$target"
	done
	cd -P -- "$(dirname -- "$target")" >/dev/null && pwd
}

if [[ -z "${BASHLIB_ROOT:-}" ]]; then
	BASHLIB_ROOT="$(__bashlib_readlink "${BASH_SOURCE[0]}")" || {
		printf 'Failed to resolve BASHLIB_ROOT from %s\n' "${BASH_SOURCE[0]}" >&2
		if (return 0 2>/dev/null); then
			return 1
		fi
		exit 1
	}
fi

# Minimal mode? export BASHLIB_MINIMAL=1 to skip optional modules
# shellcheck source=./utils/utils.sh
source "$BASHLIB_ROOT/utils/utils.sh"

# shellcheck source=./utils/helpers.sh
source "$BASHLIB_ROOT/utils/helpers.sh"
# shellcheck source=./docker/compose.sh
source "$BASHLIB_ROOT/docker/compose.sh"

# shellcheck source=./ui/colors.sh
source "$BASHLIB_ROOT/ui/colors.sh"
# shellcheck source=./log.sh
source "$BASHLIB_ROOT/log.sh"
# shellcheck source=./ui/ui.sh
source "$BASHLIB_ROOT/ui/ui.sh"
# shellcheck source=./privileges/sudo.sh
source "$BASHLIB_ROOT/privileges/sudo.sh"

if [[ "${BASHLIB_MINIMAL:-0}" != "1" ]]; then
	# shellcheck source=./ui/spinner.sh
	source "$BASHLIB_ROOT/ui/spinner.sh"
	# shellcheck source=./ui/progress.sh
	source "$BASHLIB_ROOT/ui/progress.sh"
	# shellcheck source=./ui/status.sh
	source "$BASHLIB_ROOT/ui/status.sh"
fi
