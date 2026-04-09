#!/usr/bin/env bash
# utils.sh — environment detection & small helpers

if [[ -n "${__BASHLIB_UTILS:-}" ]]; then
	if (return 0 2>/dev/null); then
		return 0
	fi
	exit 0
fi
__BASHLIB_UTILS=1

# TTY check
__bashlib_tty() { [[ -t 1 ]]; }

__bashlib_to_lower() {
	printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

__bashlib_to_upper() {
	printf '%s' "$1" | tr '[:lower:]' '[:upper:]'
}

# UTF-8 locale check
__bashlib_is_utf8() {
	local l="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
	l="$(__bashlib_to_lower "$l")"
	[[ "$l" == *"utf-8"* || "$l" == *"utf8"* ]]
}

# Terminal width (fallback 80)
__bashlib_cols() {
	if command -v tput >/dev/null 2>&1 && tput cols >/dev/null 2>&1; then
		tput cols
	else
		printf '80'
	fi
}

__bashlib_repeat() {
	local str="$1" count="${2:-0}" buf
	((count > 0)) || return 0
	printf -v buf '%*s' "$count" ''
	buf="${buf// /$str}"
	printf '%s' "$buf"
}

resolve_script_path() {
	local script_path="$1"
	printf '%s/%s' \
		"$(cd -- "$(dirname -- "$script_path")" >/dev/null 2>&1 && pwd)" \
		"$(basename -- "$script_path")"
}

is_current_mise_task() {
	local script_path
	script_path="$(resolve_script_path "$1")"
	[[ -n "${MISE_TASK_FILE:-}" ]] && [[ "$MISE_TASK_FILE" == "$script_path" ]]
}

detect_task_runner() {
	if is_current_mise_task "$1"; then
		printf '%s' "mise"
		return 0
	fi

	if [[ -n "${MAKELEVEL:-}" || -n "${MAKEFLAGS:-}" ]]; then
		printf '%s' "make"
		return 0
	fi

	printf '%s' "direct"
}

# Require a command or exit with message
require_cmd() { command -v "$1" >/dev/null 2>&1 || {
	printf 'Missing required command: %s\n' "$1" >&2
	exit 127
}; }

# Portable sleep that tolerates fractional seconds
# Falls back to bash read -t (fractional ok on bash ≥4.2), then integer sleep.
__bashlib_sleep() {
	local secs="${1:-0.05}"
	# Try native sleep (works on many systems for floats)
	sleep "$secs" 2>/dev/null && return 0
	# Try bash read -t with a dummy FD (supports fractional on bash ≥4.2)
	# shellcheck disable=SC2162
	{ read -rt "$secs" _ < <(:); } 2>/dev/null && return 0
	# Fallback to closest integer seconds (0 -> no delay)
	local isecs="${secs%.*}"
	[[ -z "$isecs" ]] && isecs=0
	sleep "$isecs" 2>/dev/null || true
}

die() {
	local code="${2:-1}"
	printf '%s\n' "$1" >&2
	exit "$code"
}
