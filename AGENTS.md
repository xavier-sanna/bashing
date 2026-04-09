# Repository Guidelines

## Project Structure & Module Organization
This repository is a small Bash helper library rooted in `src/`. `src/load.sh` is the main entrypoint, `src/bootstrap.sh` resolves task and project paths, and `src/self-update.sh` updates installed copies. General helpers live in `src/utils/`, Docker helpers in `src/docker/compose.sh`, UI modules under `src/ui/`, and privilege helpers in `src/privileges/`. Example consumer scripts live in `examples/`; `demo.sh` shows all modules together.

## Build, Test, and Development Commands
There is no build step. Use lightweight Bash validation instead:

- `bash -n install.sh demo.sh src/*.sh src/utils/*.sh src/docker/*.sh src/ui/*.sh src/privileges/*.sh examples/* tests/test_helper/*.bash`: syntax-check shell scripts, examples, and shared test helpers.
- `shellcheck src/*.sh src/utils/*.sh src/docker/*.sh src/ui/*.sh src/privileges/*.sh`: run static analysis; the codebase already includes ShellCheck directives.
- `mise run test`: run the full Bats suite in `tests/`.
- `mise run hooks:install`: enable the versioned `.githooks/pre-commit` hook locally.
- `bash -lc 'source ./src/load.sh && type log_info >/dev/null && type with_status >/dev/null'`: smoke-test the main loader and optional modules.
- `BASHLIB_MINIMAL=1 bash -lc 'source ./src/load.sh'`: verify the minimal load path without spinner/progress/status helpers.

## Coding Style & Naming Conventions
Use `#!/usr/bin/env bash` for scripts, `shfmt` default formatting, and lowercase snake_case for functions such as `detect_compose` or `dotenv_load`. Reserve uppercase snake_case for globals and exported settings like `PROJECT_ROOT` or `LOG_LEVEL`. Keep modules idempotent with `__BASHLIB_*` guards, prefer `local` variables inside functions, and quote expansions unless unquoted splitting is required.

## Testing Guidelines
Tests use Bats and live in `tests/`. Add new tests as `tests/<feature>.bats`; put shared helpers in `tests/test_helper/*.bash`. For each change, run `bash -n install.sh demo.sh src/*.sh src/utils/*.sh src/docker/*.sh src/ui/*.sh src/privileges/*.sh examples/* tests/test_helper/*.bash`, `shellcheck ...` when available, and `mise run test`.

## Commit & Pull Request Guidelines
Git history currently contains only `initial commit`, so no mature convention exists yet. Use short, imperative commit subjects such as `add dotenv parsing helper` or `tighten compose detection`. Pull requests should describe affected modules, list the validation commands you ran, and include terminal screenshots only when output formatting changes in `src/ui/ui.sh`, `src/ui/spinner.sh`, or `src/ui/status.sh`.

## Security & Configuration Tips
Treat privilege escalation as opt-in. `src/privileges/sudo.sh` respects `CAN_SUDO`; new helpers should not assume elevated access by default. Do not hardcode secrets or environment-specific paths into shared modules.
