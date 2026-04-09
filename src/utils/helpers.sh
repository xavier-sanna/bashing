#!/usr/bin/env bash

if [[ -n "${__BASHLIB_HELPERS:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
__BASHLIB_HELPERS=1

__bashlib_helpers_error() {
  if declare -F log_error >/dev/null 2>&1; then
    log_error "$1"
  else
    printf '%s\n' "$1" >&2
  fi
}

__bashlib_trim_leading() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  printf '%s' "$value"
}

__bashlib_trim_trailing() {
  local value="$1"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

__bashlib_dotenv_strip_comment() {
  local value="$1" out="" ch prev="" in_single=0 in_double=0
  local i

  for ((i = 0; i < ${#value}; i++)); do
    ch="${value:i:1}"

    if ((in_single)); then
      [[ "$ch" == "'" ]] && in_single=0
      out+="$ch"
      continue
    fi

    if ((in_double)); then
      if [[ "$ch" == '"' && "$prev" != "\\" ]]; then
        in_double=0
      fi
      out+="$ch"
      prev="$ch"
      continue
    fi

    case "$ch" in
    "'")
      in_single=1
      ;;
    '"')
      in_double=1
      ;;
    '#')
      if [[ -z "$out" || "${out: -1}" =~ [[:space:]] ]]; then
        break
      fi
      ;;
    esac

    out+="$ch"
    prev="$ch"
  done

  __bashlib_trim_trailing "$out"
}

__bashlib_dotenv_parse_value() {
  local value
  value="$(__bashlib_trim_leading "$1")"
  value="$(__bashlib_dotenv_strip_comment "$value")"

  if [[ "$value" == \"*\" && "$value" == *\" ]]; then
    value="${value:1:${#value}-2}"
    value="${value//\\n/$'\n'}"
    value="${value//\\r/$'\r'}"
    value="${value//\\t/$'\t'}"
    value="${value//\\\"/\"}"
    value="${value//\\\\/\\}"
  elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
    value="${value:1:${#value}-2}"
  fi

  printf '%s' "$value"
}

dotenv_load() {
  local file="${1:-.env}" line key value line_no=0
  [[ -f "$file" ]] || {
    __bashlib_helpers_error "dotenv: $file not found"
    return 1
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    ((line_no += 1))
    line="$(__bashlib_trim_leading "$line")"
    line="$(__bashlib_trim_trailing "$line")"

    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "$line" == export[[:space:]]* ]]; then
      line="${line#export}"
      line="$(__bashlib_trim_leading "$line")"
    fi

    if [[ "$line" != *=* ]]; then
      __bashlib_helpers_error "dotenv: invalid line ${line_no} in ${file}"
      return 1
    fi

    key="$(__bashlib_trim_leading "${line%%=*}")"
    key="$(__bashlib_trim_trailing "$key")"
    value="${line#*=}"

    if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      __bashlib_helpers_error "dotenv: invalid key '${key}' on line ${line_no} in ${file}"
      return 1
    fi

    value="$(__bashlib_dotenv_parse_value "$value")"
    printf -v "$key" '%s' "$value"
  done < "$file"
}
