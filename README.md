# bashing

Small Bash helper library with utilities for logging, UI output, dotenv parsing, Docker Compose helpers, and opt-in privilege helpers.

## Install
Run the installer from the directory that should receive the local `bashing/` copy. It clones this repository, copies `src/` into `./bashing`, removes the temporary clone, and adds a managed block to `.gitignore`.

### curl
```bash
curl -fsSL https://raw.githubusercontent.com/xavier-sanna/bashing/main/install.sh | bash
```

### wget
```bash
wget -qO- https://raw.githubusercontent.com/xavier-sanna/bashing/main/install.sh | bash
```

To install into a different directory, pass the target path to Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/xavier-sanna/bashing/main/install.sh | bash -s -- /path/to/project
```

If your task scripts live in `scripts/`, install the library next to them:

```bash
curl -fsSL https://raw.githubusercontent.com/xavier-sanna/bashing/main/install.sh | bash -s -- scripts
```

Then a script at `scripts/certs` can source:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/bashing/bootstrap.sh"
```

Update an installed copy by running the updater inside that copy:

```bash
./bashing/self-update.sh
# or, when installed next to task scripts:
./scripts/bashing/self-update.sh
```

## Basic Usage
See [examples/certs](examples/certs) for a real task script based on a local certificate workflow. The important setup is:

```bash
#!/usr/bin/env bash
#MISE description="Create/update project SSL certificates"

set -euo pipefail
IFS=$'\n\t'

source "$(dirname "${BASH_SOURCE[0]}")/bashing/bootstrap.sh"

dotenv_load "$PROJECT_ROOT/.env"
PROJECT_NAME="${PROJECT_NAME:-${PROJECT_ROOT##*/}}"

title "Local SSL Certificates" "$PROJECT_NAME"
with_status "Installing local CA" mkcert -install
```

The example uses helpers from multiple modules: `dotenv_load` from `utils/helpers.sh`, `title`, `color_box`, `indent`, and `with_status` from `ui/`, `log_*` output helpers, and `sudo_run`/`can_sudo` for optional `/etc/hosts` updates.

## Task Runner Compatibility
`bootstrap.sh` is the compatibility layer for scripts that may be run directly, from make, or as mise tasks. When sourced, it sets:

- `BASHLIB_ROOT`: the installed `bashing/` directory.
- `TASKS_ROOT`: the parent directory containing the installed `bashing/` copy.
- `TASK_DIR` and `TASK_FILE`: the calling script location.
- `PROJECT_ROOT`: the nearest parent containing `.git`, `mise.toml`, or `docker-compose.yaml`.

Use `detect_task_runner "$TASK_FILE"` when behavior needs to vary by launcher. It returns `mise` when `MISE_TASK_FILE` matches the current script, `make` when `MAKELEVEL` or `MAKEFLAGS` are present, and `direct` otherwise.

## Development
Library sources live under `src/`. The installer copies those files into the consumer project's `bashing/` directory.

Validate the shell scripts with:

```bash
bash -n install.sh src/*.sh src/utils/*.sh src/docker/*.sh src/ui/*.sh src/privileges/*.sh examples/* tests/test_helper/*.bash
```

Run the Bats test suite with:

```bash
mise run test
```
