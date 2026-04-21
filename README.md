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

### Install Specific Packages

```bash
# Via argument
bin/install.sh neovim starship

# Via make
make install INCLUDE="neovim starship"
```

### Exclude Packages

```bash
# Single package
make install EXCLUDE=apptainer

# Multiple packages
make install EXCLUDE="apptainer rust"

# Via bin/install.sh directly
bin/install.sh --exclude apptainer --exclude rust
```

### Update Installed Packages

```bash
make update
```

### Dry Run (preview install order)

```bash
make dry-run

# Or directly
bin/install.sh --dry-run
bin/install.sh --dry-run neovim starship
```

### Log Output to File

```bash
bin/install.sh --log
```

Output is logged to `~/.mjstp_install.log`.

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
- **Shell Tools**: `tmux`, `starship`, `duf`, `dust`, `apptainer`, `git`, `lsd`, `bzip2`, `zoxide`, `fzf`
- **Bioinformatics**: `snakemake`, `htslib`, `samtools`, `bcftools`
- **R Tools**: `radian`
