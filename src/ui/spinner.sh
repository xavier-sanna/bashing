#!/usr/bin/env bash
# spinner.sh — spinner_start/spinner_stop

if [[ -n "${__BASHLIB_SPINNER:-}" ]]; then
	if (return 0 2>/dev/null); then
		return 0
	fi
	exit 0
fi
__BASHLIB_SPINNER=1

__BASHLIB_SPIN_PID=""

spinner_start() {
	local msg="${1:-Working}"
	if ! __bashlib_tty; then
		printf '%s... ' "$msg"
		return
	fi
	local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
	__bashlib_is_utf8 || frames=('-' "\\" '|' '/')
	command -v tput >/dev/null 2>&1 && tput civis 2>/dev/null || true
	(
		local i=0
		while :; do
			printf '\r%s %s' "${frames[i]}" "$msg"
			((i = (i + 1) % ${#frames[@]}))
			__bashlib_sleep 0.1
		done
	) &
	__BASHLIB_SPIN_PID=$!
}

spinner_stop() {
	local code="${1:-0}"
	if [[ -n "$__BASHLIB_SPIN_PID" ]]; then
		kill "$__BASHLIB_SPIN_PID" >/dev/null 2>&1 || true
		wait "$__BASHLIB_SPIN_PID" 2>/dev/null || true
		__BASHLIB_SPIN_PID=""
		command -v tput >/dev/null 2>&1 && tput cnorm 2>/dev/null || true
		# Clear the spinner line
		printf '\r\033[K'
	fi
	if ((code == 0)); then log_success "Done"; else log_error "Failed (exit $code)"; fi
}
