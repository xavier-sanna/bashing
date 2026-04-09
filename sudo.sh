#!/usr/bin/env bash
# sudo.sh — opt-in sudo helpers with optional prompt puns

if [[ -n "${__BASHLIB_SUDO:-}" ]]; then return 0 2>/dev/null || exit 0; fi
__BASHLIB_SUDO=1

SUDO_USED=0

__bashlib_sudo_root() {
  ((EUID == 0))
}

__bashlib_sudo_available() {
  __bashlib_sudo_root || command -v sudo >/dev/null 2>&1
}

__bashlib_sudo_truthy() {
  local value="${1:-}"

  value="${value//\"/}"
  value="${value//\'/}"
  value="$(__bashlib_trim_leading "$value")"
  value="$(__bashlib_trim_trailing "$value")"
  value="$(__bashlib_to_lower "$value")"

  case "$value" in
  1 | true | yes | on) return 0 ;;
  *) return 1 ;;
  esac
}

__bashlib_sudo_shell() {
  if [[ -n "${BASH:-}" ]]; then
    printf '%s' "$BASH"
    return 0
  fi

  command -v bash
}

__bashlib_sudo_puns_file() {
  printf '%s/sudo-puns' "${BASHLIB_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)}"
}

__bashlib_sudo_error() {
  local message="$1"

  if declare -F log_error >/dev/null 2>&1; then
    log_error "$message"
  else
    printf '%s\n' "$message" >&2
  fi
}

__bashlib_sudo_prompt() {
  __bashlib_tty || return 0
  is_elevated && return 0
  display_pun || true
}

__bashlib_sudo_run_function() {
  local function_name="$1"
  local rendered_args=""
  local bash_cmd

  shift
  printf -v rendered_args ' %q' "$@"
  bash_cmd="$(__bashlib_sudo_shell)"

  command sudo "$bash_cmd" -lc "$(declare -f "$function_name"); $function_name${rendered_args}"
}

__bashlib_sudo_run_alias() {
  local alias_name="$1"
  local alias_definition rendered_args=""
  local bash_cmd

  shift
  alias_definition="$(alias "$alias_name" 2>/dev/null)" || return 1
  printf -v rendered_args ' %q' "$@"
  bash_cmd="$(__bashlib_sudo_shell)"

  command sudo "$bash_cmd" -lc "shopt -s expand_aliases; ${alias_definition}; ${alias_name}${rendered_args}"
}

__bashlib_sudo_run_current_alias() {
  local alias_name="$1"
  local rendered_args="" code had_expand_aliases=0

  shift
  printf -v rendered_args ' %q' "$@"

  shopt -q expand_aliases && had_expand_aliases=1
  shopt -s expand_aliases
  eval "${alias_name}${rendered_args}"
  code=$?
  ((had_expand_aliases)) || shopt -u expand_aliases

  return "$code"
}

can_sudo() {
  __bashlib_sudo_truthy "${CAN_SUDO:-false}" || return 1
  __bashlib_sudo_available
}

is_elevated() {
  __bashlib_sudo_root && return 0
  command -v sudo >/dev/null 2>&1 || return 1
  sudo -n true >/dev/null 2>&1
}

display_pun() {
  local puns_file total_lines random_line

  puns_file="$(__bashlib_sudo_puns_file)"
  [[ -f "$puns_file" ]] || return 1

  total_lines=$(wc -l < "$puns_file")
  ((total_lines > 0)) || return 1

  random_line=$((RANDOM % total_lines + 1))
  sed -n "${random_line}p" "$puns_file" >&2
}

sudo_run() {
  local target="${1:-}"
  local target_type="" code

  [[ -n "$target" ]] || return 0

  can_sudo || {
    __bashlib_sudo_error "sudo is disabled or unavailable."
    return 1
  }

  target_type="$(type -t "$target" 2>/dev/null || true)"

  if __bashlib_sudo_root; then
    case "$target_type" in
    alias)
      __bashlib_sudo_run_current_alias "$target" "${@:2}"
      ;;
    *)
      "$@"
      ;;
    esac
    code=$?
    ((code == 0)) && SUDO_USED=1
    return "$code"
  fi

  __bashlib_sudo_prompt

  case "$target_type" in
  function)
    __bashlib_sudo_run_function "$target" "${@:2}"
    ;;
  alias)
    __bashlib_sudo_run_alias "$target" "${@:2}"
    ;;
  *)
    command sudo "$@"
    ;;
  esac
  code=$?

  ((code == 0)) && SUDO_USED=1
  return "$code"
}

Sudo() {
  sudo_run "$@"
}
