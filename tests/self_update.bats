setup() {
	load 'test_helper/common'
	_bashing_setup

	env BASHING_REPO_URL="$LOCAL_REPO_URL" "$INSTALL_SCRIPT" "$PROJECT_DIR" >/dev/null
}

teardown() {
	_bashing_teardown
}

@test "updates an installed bashing directory from the configured repository" {
	printf '%s\n' 'stale file' >"$PROJECT_DIR/bashing/log.sh"
	printf '%s\n' 'remove me' >"$PROJECT_DIR/bashing/obsolete.sh"

	run env BASHING_REPO_URL="$LOCAL_REPO_URL" "$PROJECT_DIR/bashing/self-update.sh"

	[ "$status" -eq 0 ]
	[ "$output" = "Updated bashing in $PROJECT_DIR/bashing" ]
	assert_installed_tree
	assert_file_not_contains "$PROJECT_DIR/bashing/log.sh" 'stale file'
	[ ! -e "$PROJECT_DIR/bashing/obsolete.sh" ]
	assert_no_temp_clone_dir
}

@test "can be run from outside the project directory" {
	run env BASHING_REPO_URL="$LOCAL_REPO_URL" bash -c "cd /tmp && \"\$1\"" _ "$PROJECT_DIR/bashing/self-update.sh"

	[ "$status" -eq 0 ]
	[ "$output" = "Updated bashing in $PROJECT_DIR/bashing" ]
	assert_installed_tree
	assert_no_temp_clone_dir
}
