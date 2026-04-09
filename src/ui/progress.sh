#!/usr/bin/env bash
# progress.sh — simple in-place progress bar

if [[ -n "${__BASHLIB_PROGRESS:-}" ]]; then return 0 2>/dev/null || exit 0; fi
__BASHLIB_PROGRESS=1

progress_bar() {
	local cur="$1" total="$2" width="${3:-40}"
	__bashlib_tty || return 0
	((total == 0)) && total=1
	((cur < 0)) && cur=0
	((cur > total)) && cur="$total"

	local pct=$((cur * 100 / total))
	local filled=$((cur * width / total))
	local empty=$((width - filled))

	printf '\r['
	__bashlib_repeat '#' "$filled"
	__bashlib_repeat '-' "$empty"
	printf '] %3d%%' "$pct"

	# Use an explicit if to avoid set -e aborting on a false condition
	if ((cur >= total)); then
		printf '\n'
	fi

	return 0
}
