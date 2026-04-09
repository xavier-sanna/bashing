#!/usr/bin/env bash
# log.sh — pretty logging with levels

if [[ -n "${__BASHLIB_LOG:-}" ]]; then return 0 2>/dev/null || exit 0; fi
__BASHLIB_LOG=1

: "${LOG_LEVEL:=info}"  # debug, info, warn, error, none
: "${LOG_TO_STDERR:=1}" # 1=stderr, 0=stdout

__log_out() { if [[ "${LOG_TO_STDERR}" == "1" ]]; then cat >&2; else cat; fi; }

__log_level_num() {
	case "$1" in
	debug) echo 10 ;; info) echo 20 ;; warn) echo 30 ;; error) echo 40 ;; none) echo 100 ;;
	*) echo 20 ;;
	esac
}
__LOG_THRESHOLD=$(__log_level_num "$LOG_LEVEL")

__sym_info="i"
__sym_success="+"
__sym_warn="!"
__sym_error="x"
if [[ "${COLOR_EMOJI:-1}" == 1 ]]; then
	__sym_info="ℹ"
	__sym_success="✔"
	__sym_warn="⚠"
	__sym_error="✖"
fi

__log_emit() { # $1=level $2=color $3=prefix $4=msg
	local want=$(__log_level_num "$1")
	((want < __LOG_THRESHOLD)) && return 0
	printf '%b\n' "$(color_text "$2" "$3 $4")" | __log_out
}

log_debug() { __log_emit debug "$C_DIM" "·" "$1"; }
log_info() { __log_emit info "$C_CYAN" "$__sym_info" "$1"; }
log_success() { __log_emit info "$C_GREEN" "$__sym_success" "$1"; }
log_warn() { __log_emit warn "$C_YELLOW" "$__sym_warn" "$1"; }
log_error() { __log_emit error "$C_RED" "$__sym_error" "$1"; }
