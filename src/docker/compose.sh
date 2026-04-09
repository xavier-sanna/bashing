#!/usr/bin/env bash

if [[ -n "${__BASHLIB_COMPOSE:-}" ]]; then return 0 2>/dev/null || exit 0; fi
__BASHLIB_COMPOSE=1

detect_compose() {
  __BASHLIB_COMPOSE_ROOT_DIR="${1:-${PROJECT_ROOT:-}}"

  if command -v docker >/dev/null 2>&1 && (
    cd "${__BASHLIB_COMPOSE_ROOT_DIR}" &&
      docker compose version >/dev/null 2>&1
  ); then
    COMPOSE_CMD=(docker compose)
    return 0
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose)
    return 0
  fi

  die "Docker Compose is not available."
}

compose() {
  (
    cd "${__BASHLIB_COMPOSE_ROOT_DIR:-${PROJECT_ROOT:-}}" &&
      "${COMPOSE_CMD[@]}" "$@"
  )
}

compose_running_services() {
  local output

  if ! output="$(compose ps --status running --services 2>&1)"; then
    printf '%s\n' "$output" >&2
    die "Unable to query Docker Compose services."
  fi

  printf '%s\n' "$output"
}

ensure_compose_service_running() {
  local service_name="$1"
  local running_services

  running_services="$(compose_running_services)"

  if ! grep -qx "$service_name" <<<"$running_services"; then
    die "$service_name service must be running before continuing."
  fi
}
