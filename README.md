# bashing

Small Bash helper library with utilities for logging, UI output, dotenv parsing, Docker Compose helpers, and opt-in privilege helpers.

## Install
Run the installer from the root of the project that should receive the library. It clones this repository, copies `src/` into `./bashing`, removes the temporary clone, and adds a managed block to `.gitignore`.

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

After installation, source the loader from your project:

```bash
source "./bashing/load.sh"
```

## Development
Library sources live under `src/`. The installer copies those files into the consumer project's `bashing/` directory.

Validate the shell scripts with:

```bash
bash -n install.sh src/*.sh src/utils/*.sh src/docker/*.sh src/ui/*.sh src/privileges/*.sh tests/*.sh
```

Run the installer test with:

```bash
bash tests/install.sh
```
