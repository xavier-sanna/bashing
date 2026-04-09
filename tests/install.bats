setup() {
	load 'test_helper/common'
	_bashing_setup
}

teardown() {
	_bashing_teardown
}

@test "copies the library tree and appends the managed gitignore block" {
	run env BASHING_REPO_URL="$LOCAL_REPO_URL" "$INSTALL_SCRIPT" "$PROJECT_DIR"

	[ "$status" -eq 0 ]
	[ "$output" = "Installed bashing into $PROJECT_DIR/bashing" ]
	assert_installed_tree
	assert_gitignore_block
	assert_no_temp_clone_dir
}

@test "rewrites an existing managed gitignore block without duplicating markers" {
	printf '%s\n' \
		'node_modules/' \
		'' \
		'###> bashing ###' \
		'/old-bashing/' \
		'###< bashing ###' \
		'' \
		'.env' >"$PROJECT_DIR/.gitignore"

	run env BASHING_REPO_URL="$LOCAL_REPO_URL" "$INSTALL_SCRIPT" "$PROJECT_DIR"

	[ "$status" -eq 0 ]
	[ "$output" = "Installed bashing into $PROJECT_DIR/bashing" ]
	[ "$(grep -Fc '###> bashing ###' "$PROJECT_DIR/.gitignore")" = "1" ]
	[ "$(grep -Fc '###< bashing ###' "$PROJECT_DIR/.gitignore")" = "1" ]
	assert_file_contains "$PROJECT_DIR/.gitignore" 'node_modules/'
	assert_file_contains "$PROJECT_DIR/.gitignore" '.env'
	assert_file_contains "$PROJECT_DIR/.gitignore" '/bashing/'
}

@test "supports curl and wget style piped execution" {
	run env BASHING_REPO_URL="$LOCAL_REPO_URL" bash -s -- "$PROJECT_DIR" <"$INSTALL_SCRIPT"

	[ "$status" -eq 0 ]
	[ "$output" = "Installed bashing into $PROJECT_DIR/bashing" ]
	assert_file_exists "$PROJECT_DIR/bashing/load.sh"
	assert_file_contains "$PROJECT_DIR/.gitignore" '/bashing/'
}
