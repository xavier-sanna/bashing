#!/usr/bin/env bash

if [[ -n "${__BASHLIB_BOOTSTRAP:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
__BASHLIB_BOOTSTRAP=1

__bashlib_bootstrap_fail() {
  printf '%s\n' "$1" >&2
  return 1 2>/dev/null || exit 1
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
}
TASKS_ROOT="$(__bashlib_bootstrap_resolve_dir "$BASHLIB_ROOT/..")" || {
  __bashlib_bootstrap_fail "Unable to resolve tasks root from $BASHLIB_ROOT"
}
TASK_DIR="$(__bashlib_bootstrap_resolve_dir "$(dirname -- "$__bashlib_bootstrap_caller")")" || {
  __bashlib_bootstrap_fail "Unable to resolve task directory for $__bashlib_bootstrap_caller"
}
TASK_FILE="$TASK_DIR/$(basename -- "$__bashlib_bootstrap_caller")"
PROJECT_ROOT="$(__bashlib_bootstrap_find_project_root "$TASKS_ROOT")" || {
  __bashlib_bootstrap_fail "Unable to resolve project root from $TASKS_ROOT"
}

# shellcheck source=./load.sh
# shellcheck disable=SC1091
source "$BASHLIB_ROOT/load.sh"
