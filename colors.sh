#!/usr/bin/env bash
# colors.sh — color/style primitives (tput with ANSI fallback)

if [[ -n "${__BASHLIB_COLORS:-}" ]]; then return 0 2>/dev/null || exit 0; fi
__BASHLIB_COLORS=1

: "${COLOR_EMOJI:=1}" # set to 0 to disable emoji

# Decide if colors should be enabled
__bashlib_should_color() {
  [[ -n "${NO_COLOR:-}" ]] && return 1
  [[ "${FORCE_COLOR:-0}" == 1 ]] && return 0
  __bashlib_tty || return 1
  case "${TERM:-dumb}" in '' | dumb) return 1 ;; *) return 0 ;; esac
}

__BASHLIB_HAS_TPUT=0
if command -v tput >/dev/null 2>&1 && tput sgr0 >/dev/null 2>&1; then __BASHLIB_HAS_TPUT=1; fi

__BASHLIB_EMIT_COLOR=0
if __bashlib_should_color; then __BASHLIB_EMIT_COLOR=1; fi

# Helper to set a var to a capability (tput) or to an ANSI code, robust to IFS
__bashlib_set_cap() {
  # $1=varname  $2="cap [arg]"  $3=ANSI fallback
  local __var="$1" __cap="$2" __ansi="$3"

  # If color output is disabled, just set empty
  if [[ "$__BASHLIB_EMIT_COLOR" != 1 ]]; then
    printf -v "$__var" '%s' ""
    return
  fi

  # Try tput safely without relying on word-splitting (IFS)
  if [[ "$__BASHLIB_HAS_TPUT" == 1 ]]; then
    local capname caparg out ok=0
    capname="${__cap%% *}"
    caparg="${__cap#* }"
    if [[ "$capname" == "$caparg" ]]; then
      # no argument form, e.g. "bold"
      out=$(tput "$capname" 2>/dev/null) && ok=1
    else
      # arg form, e.g. "setaf 1"
      out=$(tput "$capname" "$caparg" 2>/dev/null) && ok=1
    fi
    if ((ok)); then
      printf -v "$__var" '%s' "$out"
      return
    fi
    # fall through to ANSI if tput-cap unsupported
  fi

  # Fallback: ANSI sequence (or empty if you prefer)
  printf -v "$__var" '%b' "$__ansi"
}

# Modifiers
__bashlib_set_cap C_RESET 'sgr0' '\033[0m'
__bashlib_set_cap C_BOLD 'bold' '\033[1m'
__bashlib_set_cap C_DIM 'dim' '\033[2m'
__bashlib_set_cap C_UNDERLINE 'smul' '\033[4m'
__bashlib_set_cap C_REVERSE 'rev' '\033[7m'

# Foreground
__bashlib_set_cap C_BLACK 'setaf 0' '\033[30m'
__bashlib_set_cap C_RED 'setaf 1' '\033[31m'
__bashlib_set_cap C_GREEN 'setaf 2' '\033[32m'
__bashlib_set_cap C_YELLOW 'setaf 3' '\033[33m'
__bashlib_set_cap C_BLUE 'setaf 4' '\033[34m'
__bashlib_set_cap C_MAGENTA 'setaf 5' '\033[35m'
__bashlib_set_cap C_CYAN 'setaf 6' '\033[36m'
__bashlib_set_cap C_WHITE 'setaf 7' '\033[37m'

# Background
__bashlib_set_cap C_BG_RED 'setab 1' '\033[41m'
__bashlib_set_cap C_BG_GREEN 'setab 2' '\033[42m'
__bashlib_set_cap C_BG_YELLOW 'setab 3' '\033[43m'
__bashlib_set_cap C_BG_BLUE 'setab 4' '\033[44m'
__bashlib_set_cap C_BG_MAGENTA 'setab 5' '\033[45m'
__bashlib_set_cap C_BG_CYAN 'setab 6' '\033[46m'
__bashlib_set_cap C_BG_WHITE 'setab 7' '\033[47m'

export C_RESET C_BOLD C_DIM C_UNDERLINE C_REVERSE
export C_BLACK C_RED C_GREEN C_YELLOW C_BLUE C_MAGENTA C_CYAN C_WHITE
export C_BG_RED C_BG_GREEN C_BG_YELLOW C_BG_BLUE C_BG_MAGENTA C_BG_CYAN C_BG_WHITE

# Generic text styler
color_text() {
  local styles=("${@:1:$#-1}") text="${!#}" s seq=""
  for s in "${styles[@]}"; do seq+="$s"; done
  printf '%b' "${seq}${text}${C_RESET}"
}
