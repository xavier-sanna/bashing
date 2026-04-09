#!/usr/bin/env bash
# load.sh — single entrypoint to source bashlib modules safely (idempotent)

# Guard against re-sourcing
if [[ -n "${__BASHLIB_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
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
    return 1 2>/dev/null || exit 1
  }
fi

# Minimal mode? export BASHLIB_MINIMAL=1 to skip optional modules
# shellcheck source=./utils.sh
source "$BASHLIB_ROOT/utils.sh"

# shellcheck source=./helpers.sh
source "$BASHLIB_ROOT/helpers.sh"
# shellcheck source=./compose.sh
source "$BASHLIB_ROOT/compose.sh"

# shellcheck source=./colors.sh
source "$BASHLIB_ROOT/colors.sh"
# shellcheck source=./log.sh
source "$BASHLIB_ROOT/log.sh"
# shellcheck source=./ui.sh
source "$BASHLIB_ROOT/ui.sh"
# shellcheck source=./sudo.sh
source "$BASHLIB_ROOT/sudo.sh"

if [[ "${BASHLIB_MINIMAL:-0}" != "1" ]]; then
  # shellcheck source=./spinner.sh
  source "$BASHLIB_ROOT/spinner.sh"
  # shellcheck source=./progress.sh
  source "$BASHLIB_ROOT/progress.sh"
  # shellcheck source=./status.sh
  source "$BASHLIB_ROOT/status.sh"
fi
