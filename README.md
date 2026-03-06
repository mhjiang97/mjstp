# MJSTP - Minghao Jiang's Setup

This project automates the setup of development tools on new Linux servers (x86_64).

## Features

- **Dependency Management**: Automatically resolves and installs dependencies in order.
- **Idempotency**: Safe to run multiple times.
- **Modular**: Each package is a self-contained script in `src/pkgs/`.
- **Environment**: Manages environment variables via `~/.mjstp_profile`.

## Prerequisites

- Linux (x86_64)
- `curl`, `tar`, `git` (usually present)

## Usage

### Install All Packages

```bash
make install
```

### Install Specific Package

```bash
bin/install.sh neovim starship
```

## Adding a New Package

1. Create a directory in `src/pkgs/<package_name>/`.
2. Create an `install.sh` file.
3. Add a dependency header if needed:

   ```bash
   # Dependencies: package1, package2
   ```

## Packages

- **Environment Managers**: `micromamba`, `pipx`, `condax`
- **Languages**: `go`, `rust`, `r`
- **Editors**: `neovim`, `lazyvim`
- **Shell Tools**: `tmux`, `starship`, `duf`, `dust`, `apptainer`, `git`
- **Bioinformatics**: `snakemake`
- **R Tools**: `radian`
