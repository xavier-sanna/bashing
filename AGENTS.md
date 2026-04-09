# Repository Guidelines

## Project Structure & Module Organization
This repository is a small Bash helper library rooted in `src/`. `src/load.sh` is the main entrypoint and `src/bootstrap.sh` resolves task and project paths. General helpers live in `src/utils/`, Docker helpers live in `src/docker/compose.sh`, UI-facing modules live under `src/ui/`, and privilege helpers live in `src/privileges/` (`sudo.sh`, `sudo-puns`). `src/log.sh` remains a standalone root-level module within `src/`.

## Build, Test, and Development Commands
There is no build step. Use lightweight Bash validation instead:

- `bash -n src/*.sh src/utils/*.sh src/docker/*.sh src/ui/*.sh src/privileges/*.sh`: syntax-check all modules.
- `shellcheck src/*.sh src/utils/*.sh src/docker/*.sh src/ui/*.sh src/privileges/*.sh`: run static analysis; the codebase already includes ShellCheck directives.
- `bash -lc 'source ./src/load.sh && type log_info >/dev/null && type with_status >/dev/null'`: smoke-test the main loader and optional modules.
- `BASHLIB_MINIMAL=1 bash -lc 'source ./src/load.sh'`: verify the minimal load path without spinner/progress/status helpers.

## Coding Style & Naming Conventions
Use `#!/usr/bin/env bash` for scripts, 2-space indentation, and lowercase snake_case for functions such as `detect_compose` or `dotenv_load`. Reserve uppercase snake_case for globals and exported settings like `PROJECT_ROOT` or `LOG_LEVEL`. Keep modules idempotent with `__BASHLIB_*` guards, prefer `local` variables inside functions, and quote expansions unless unquoted splitting is required. Reuse shared helpers like `die`, `log_*`, and `color_text` instead of ad hoc output logic.

## Testing Guidelines
There is no formal test suite or coverage gate yet. For each change, run `bash -n src/*.sh src/utils/*.sh src/docker/*.sh src/ui/*.sh src/privileges/*.sh`, then `shellcheck src/*.sh src/utils/*.sh src/docker/*.sh src/ui/*.sh src/privileges/*.sh`, then a targeted smoke test by sourcing the touched module or `src/load.sh`. If a real test directory is added later, mirror module names in test files, for example `tests/helpers.bats`.

## Commit & Pull Request Guidelines
Git history currently contains only `initial commit`, so no mature convention exists yet. Use short, imperative commit subjects such as `add dotenv parsing helper` or `tighten compose detection`. Pull requests should describe affected modules, list the validation commands you ran, and include terminal screenshots only when output formatting changes in `src/ui/ui.sh`, `src/ui/spinner.sh`, or `src/ui/status.sh`.

## Security & Configuration Tips
Treat privilege escalation as opt-in. `src/privileges/sudo.sh` respects `CAN_SUDO`; new helpers should not assume elevated access by default. Do not hardcode secrets or environment-specific paths into shared modules.
