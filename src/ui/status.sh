#!/usr/bin/env bash
# status.sh — with_status wrapper (spinner + elapsed time)

if [[ -n "${__BASHLIB_STATUS:-}" ]]; then return 0 2>/dev/null || exit 0; fi
__BASHLIB_STATUS=1

with_status() {
  local msg="$1"
  shift
  local start ts code had_errexit=0
  start=$(date +%s 2>/dev/null || printf '0')
  spinner_start "$msg"
  [[ $- == *e* ]] && had_errexit=1 && set +e
  "$@"
  code=$?
  ((had_errexit)) && set -e
  spinner_stop "$code"
  ts=$(date +%s 2>/dev/null || printf '0')
  local elapsed=$((ts - start))
  ((elapsed < 0)) && elapsed=0
  printf '%b\n' "$(color_text "$C_DIM" "(${elapsed}s)")"
  return "$code"
}
