#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

: "${LOG_LEVEL:=debug}"

# Demo from the source checkout. Installed project scripts usually source
# "$(dirname "${BASH_SOURCE[0]}")/bashing/bootstrap.sh" instead.
# shellcheck source=./src/bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/src/bootstrap.sh"

DEMO_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/bashing-demo.XXXXXX")"
trap 'rm -rf "$DEMO_TMP_DIR"' EXIT

demo_command() {
	printf '%b\n' "$(color_text "$C_DIM" "$ $*")"
}

demo_wait() {
	__bashlib_sleep "${1:-0.15}"
}

demo_bootstrap() {
	section "Bootstrap Context" "Path resolution and task runner compatibility"

	table "Name;Value" "$(
		printf 'BASHLIB_ROOT;%s\n' "$BASHLIB_ROOT"
		printf 'PROJECT_ROOT;%s\n' "$PROJECT_ROOT"
		printf 'TASKS_ROOT;%s\n' "$TASKS_ROOT"
		printf 'TASK_DIR;%s\n' "$TASK_DIR"
		printf 'TASK_FILE;%s\n' "$TASK_FILE"
		printf 'runner;%s\n' "$(detect_task_runner "$TASK_FILE")"
	)"

	log_info "resolve_script_path demo: $(resolve_script_path "$TASK_FILE")"
}

demo_utils() {
	section "Utility Helpers" "Small reusable Bash primitives"

	table "Helper;Example;Result" "$(
		printf '__bashlib_to_lower;HELLO Demo;%s\n' "$(__bashlib_to_lower 'HELLO Demo')"
		printf '__bashlib_to_upper;hello demo;%s\n' "$(__bashlib_to_upper 'hello demo')"
		printf '__bashlib_repeat;=- repeated 8;%s\n' "$(__bashlib_repeat '=-' 8)"
		printf '__bashlib_cols;terminal width;%s\n' "$(__bashlib_cols)"
		printf '__bashlib_is_utf8;locale check;%s\n' "$(__bashlib_is_utf8 && printf yes || printf no)"
	)"

	demo_command "require_cmd bash"
	require_cmd bash
	log_success "bash is available"
}

demo_dotenv() {
	local env_file="$DEMO_TMP_DIR/.env.demo"

	section "Dotenv Helpers" "Parsing .env files and trimming values"

	cat >"$env_file" <<'EOF'
# Comments and export prefixes are supported.
export PROJECT_NAME="Bashing Demo"
APP_HOST_WEB=demo.local
APP_HOST_API="api.demo.local" # trailing comment is ignored
TRIM_ME='  keep inner spaces  '
EOF

	demo_command "dotenv_load $env_file"
	dotenv_load "$env_file"

	table "Variable;Value" "$(
		printf 'PROJECT_NAME;%s\n' "${PROJECT_NAME:-}"
		printf 'APP_HOST_WEB;%s\n' "${APP_HOST_WEB:-}"
		printf 'APP_HOST_API;%s\n' "${APP_HOST_API:-}"
		printf 'trim leading;%s\n' "$(__bashlib_trim_leading '    padded left')"
		printf 'trim trailing;%s\n' "$(__bashlib_trim_trailing 'padded right    ')"
	)"
}

demo_colors_and_logs() {
	section "Colors And Logs" "Styling text and level-based messages"

	printf '%b\n' "$(color_text "$C_BOLD" "bold text")"
	printf '%b\n' "$(color_text "$C_DIM" "dim text")"
	printf '%b\n' "$(color_text "$C_UNDERLINE" "underlined text")"
	printf '%b\n' "$(color_text "$C_GREEN" "green text")"
	printf '%b\n' "$(color_text "$C_WHITE" "$C_BG_BLUE" "white on blue")"

	log_debug "debug message because LOG_LEVEL=${LOG_LEVEL}"
	log_info "informational message"
	log_success "success message"
	log_warn "warning message"
	log_error "example error-style message"
}

demo_ui() {
	section "UI Helpers" "Titles, boxes, tables, separators, and indentation"

	TITLE_ALIGN=center TITLE_ICON="*" TITLE_ICON_W=1 title "Default Box" "with subtitle"
	TITLE_DECOR=underline TITLE_ALIGN=left TITLE_UPPER=0 title "Underline title" "left aligned"
	TITLE_DECOR=bracket TITLE_ALIGN=left TITLE_UPPER=0 title "Bracket title"
	TITLE_DECOR=block TITLE_ALIGN=left TITLE_UPPER=0 title "Block title"

	color_box "color_box" $'Multi-line content\nwith a colored border/body style' "$C_CYAN"

	table "Feature;Function;Example" $'separator;hr;full-width rule\nsection;section;heading + subtitle\ntable;table;fixed-width columns'

	printf '%s\n' "Indented output:" | indent '  > '
	printf '%s\n%s\n' "first line" "second line" | indent '  | '
}

demo_status_and_progress() {
	section "Status Helpers" "Spinner, status wrapper, and progress bar"

	demo_command "with_status \"Short task\" bash -c 'sleep 0.2'"
	with_status "Short task" bash -c 'sleep 0.2'

	demo_command "spinner_start / spinner_stop"
	spinner_start "Manual spinner"
	demo_wait 0.2
	spinner_stop 0

	if __bashlib_tty; then
		demo_command "progress_bar current total width"
		for i in 0 1 2 3 4 5; do
			progress_bar "$i" 5 24
			demo_wait 0.05
		done
	else
		log_info "progress_bar is TTY-only; run ./demo.sh in an interactive terminal to see it animate."
	fi
}

demo_sudo() {
	section "Privilege Helpers" "Opt-in sudo support"

	table "Helper;Current result" "$(
		printf 'CAN_SUDO;%s\n' "${CAN_SUDO:-false}"
		printf 'can_sudo;%s\n' "$(can_sudo && printf yes || printf no)"
		printf 'is_elevated;%s\n' "$(is_elevated && printf yes || printf no)"
	)"

	log_info "sudo_run is intentionally skipped unless CAN_SUDO is enabled and sudo is already authenticated."
	if can_sudo && is_elevated; then
		demo_command "sudo_run true"
		sudo_run true
		log_success "sudo_run completed without prompting"
	fi

	log_info "display_pun can render one optional sudo prompt pun:"
	display_pun || log_warn "No sudo pun file available."
}

demo_compose() {
	section "Docker Compose Helpers" "Safe detection with concrete call examples"

	if (detect_compose "$PROJECT_ROOT") >/dev/null 2>&1; then
		detect_compose "$PROJECT_ROOT"
		table "Helper;Example" "$(
			printf 'detect_compose;%s\n' "$(printf '%q ' "${COMPOSE_CMD[@]}")"
			printf 'compose;compose ps\n'
			printf 'compose_running_services;compose ps --status running --services\n'
			printf 'ensure_compose_service_running;ensure_compose_service_running database\n'
		)"

		if [[ -f "$PROJECT_ROOT/compose.yaml" || -f "$PROJECT_ROOT/docker-compose.yaml" || -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
			log_info "Running compose_running_services for this project:"
			compose_running_services || true
		else
			log_warn "No Compose file found in PROJECT_ROOT; runtime service queries are skipped."
		fi
	else
		log_warn "Docker Compose is not available; detection and service checks are skipped."
	fi
}

demo_update_script() {
	section "Installed Copy Updates" "Self-update entrypoint"

	table "Script;Purpose" "$(
		printf 'install.sh;clone repo, copy src into bashing/, update .gitignore\n'
		printf 'self-update.sh;replace an installed bashing/ directory with fresh src contents\n'
	)"

	log_info "Installed projects can run ./bashing/self-update.sh or ./scripts/bashing/self-update.sh."
	log_warn "The demo does not run self-update because it would replace the active library copy."
}

main() {
	TITLE_ALIGN=center TITLE_ICON=">" TITLE_ICON_W=1 title "bashing demo" "all modules in one safe script"

	demo_bootstrap
	demo_utils
	demo_dotenv
	demo_colors_and_logs
	demo_ui
	demo_status_and_progress
	demo_sudo
	demo_compose
	demo_update_script

	section "Done"
	log_success "Demo completed."
}

main "$@"
