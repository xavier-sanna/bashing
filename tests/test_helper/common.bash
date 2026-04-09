#!/usr/bin/env bash
# shellcheck disable=SC2034

_bashing_create_source_repo() {
	SOURCE_REPO="$(mktemp -d "${TMPDIR:-/tmp}/bashing-source.XXXXXX")" || return 1

	mkdir "$SOURCE_REPO/src" || return 1
	cp -R "$PROJECT_ROOT/src/." "$SOURCE_REPO/src/" || return 1

	git -C "$SOURCE_REPO" init --quiet || return 1
	git -C "$SOURCE_REPO" config user.email "bats@example.test" || return 1
	git -C "$SOURCE_REPO" config user.name "Bats Test" || return 1
	git -C "$SOURCE_REPO" add src || return 1
	git -C "$SOURCE_REPO" commit --quiet -m "fixture" || return 1

	LOCAL_REPO_URL="file://$SOURCE_REPO"
}

_bashing_setup() {
	TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)" || return 1
	PROJECT_ROOT="$(cd "$TEST_DIR/.." >/dev/null 2>&1 && pwd)" || return 1
	INSTALL_SCRIPT="$PROJECT_ROOT/install.sh"
	SOURCE_REPO=""
	PROJECT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/bashing-test.XXXXXX")" || return 1

	_bashing_create_source_repo || return 1
	printf 'node_modules/\n' >"$PROJECT_DIR/.gitignore"
}

_bashing_teardown() {
	[ -n "${PROJECT_DIR:-}" ] && [ -d "$PROJECT_DIR" ] && rm -rf "$PROJECT_DIR"
	[ -n "${SOURCE_REPO:-}" ] && [ -d "$SOURCE_REPO" ] && rm -rf "$SOURCE_REPO"
}

assert_file_exists() {
	[ -f "$1" ]
}

assert_file_executable() {
	[ -x "$1" ]
}

assert_file_contains() {
	grep -Fq "$2" "$1"
}

assert_file_not_contains() {
	if grep -Fq "$2" "$1"; then
		return 1
	fi

	return 0
}

assert_installed_tree() {
	assert_file_exists "$PROJECT_DIR/bashing/load.sh"
	assert_file_exists "$PROJECT_DIR/bashing/bootstrap.sh"
	assert_file_exists "$PROJECT_DIR/bashing/log.sh"
	assert_file_exists "$PROJECT_DIR/bashing/self-update.sh"
	assert_file_executable "$PROJECT_DIR/bashing/self-update.sh"
	assert_file_exists "$PROJECT_DIR/bashing/utils/utils.sh"
	assert_file_exists "$PROJECT_DIR/bashing/utils/helpers.sh"
	assert_file_exists "$PROJECT_DIR/bashing/docker/compose.sh"
	assert_file_exists "$PROJECT_DIR/bashing/ui/ui.sh"
	assert_file_exists "$PROJECT_DIR/bashing/ui/colors.sh"
	assert_file_exists "$PROJECT_DIR/bashing/ui/spinner.sh"
	assert_file_exists "$PROJECT_DIR/bashing/ui/progress.sh"
	assert_file_exists "$PROJECT_DIR/bashing/ui/status.sh"
	assert_file_exists "$PROJECT_DIR/bashing/privileges/sudo.sh"
	assert_file_exists "$PROJECT_DIR/bashing/privileges/sudo-puns"
}

assert_gitignore_block() {
	assert_file_contains "$PROJECT_DIR/.gitignore" '###> bashing ###'
	assert_file_contains "$PROJECT_DIR/.gitignore" '/bashing/'
	assert_file_contains "$PROJECT_DIR/.gitignore" '###< bashing ###'
}

assert_no_temp_clone_dir() {
	temp_clone_count="$(find "$PROJECT_DIR" -maxdepth 1 -type d \( -name '.bashing-clone.*' -o -name '.bashing-update-*' \) | wc -l | tr -d ' ')"
	[ "$temp_clone_count" = "0" ]
}
