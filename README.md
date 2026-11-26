# MJSTP - Minghao Jiang's Setup

Automated, rootless setup of development and bioinformatics tools on new Linux servers (`x86_64`).

All packages install into a unified user-space prefix (`${MJSTP_PREFIX:-~/local}`) that mimics `/` (`/usr/local`) — no `sudo` required.

## Directory Layout (`~/local`)

```text
~/local/
├── bin/        # Executables & symlinks (single bin directory for all tools)
├── lib/        # Shared (.so) & static (.a) libraries, pkgconfig/
├── lib64/      # 64-bit libraries & pkgconfig/
├── include/    # C/C++ headers
├── share/      # Man pages (share/man/), runtime data
├── etc/        # User-space tool configuration (e.g. condaxrc)
└── opt/        # Isolated distributions & environments (go, nvim, fzf, micromamba, condax, pipx, cargo, rustup)
```

## Features

- **Rootless FHS Prefix**: Installs everything under `~/local` with `-Wl,-rpath`, `CFLAGS`, and `PKG_CONFIG_PATH` pre-configured so source builds link cleanly without `sudo`.
- **Always Latest Releases**: Every run (`make install` or `make update`) checks upstream releases and installs or upgrades to the latest version, skipping rebuilds when already up to date.
- **Dependency Management**: Automatically resolves and installs package dependencies in topological order.
- **Shell Integration**: Configures `~/.mjstp_profile` for both `bash` and `zsh` across interactive and SSH login shells without cluttering dotfiles.

## Prerequisites

- Linux (`x86_64`)
- `curl`, `tar`, `git`
- `gcc` (or `cc`) and `make` (for compiling C libraries/tools and Rust crates)

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

Excluding a package also automatically skips any packages that depend on it.

```bash
# Single package
make install EXCLUDE=apptainer

# Multiple packages
make install EXCLUDE="apptainer rust"

# Via bin/install.sh directly
bin/install.sh --exclude apptainer --exclude rust
```

### Update Installed Packages to Latest

```bash
make update
```

### Dry Run (preview install order)

```bash
make dry-run

# Or directly
bin/install.sh --dry-run
bin/install.sh --dry-run samtools bcftools
```

### Health Check (Doctor)

```bash
make doctor
```

Checks disk usage of `MJSTP_PREFIX`/`MJSTP_CACHE_DIR`/`MJSTP_DATA_DIR`, broken symlinks in `~/local/bin`, shared library links (`ldd`), and key tool versions.

### Continue on Error

```bash
make update KEEP_GOING=1
# Or directly
bin/install.sh --keep-going
```

### Log Output to File

```bash
bin/install.sh --log
```

Output is logged to `~/.mjstp_install.log`.

## Adding a New Package

1. Create `src/pkgs/<package_name>/install.sh` (`chmod +x`).
2. Add optional metadata headers at the top:

   ```bash
   #!/usr/bin/env bash
   # Dependencies: package1, package2
   ```

3. Source `utils.sh`, call `init_local_env`, and install into `${MJSTP_PREFIX}`.

## Packages

- **Environment & Package Managers**: `micromamba`, `condax`, `pipx`, `uv`
- **Bulk Manifests**:
  - `condax-pkgs` ([packages.txt](src/pkgs/condax-pkgs/packages.txt)): `openjdk`, `nextflow`, `sra-tools`, `gdc-client`, `awscli`, `lftp`, `enabrowsertools`, `bedtools`, `bedops`, `seqkit`, `seqtk`, `pigz`, `mosdepth`, `fastp`, `fastqc`, `bwa-mem2`, `gffread`, `ucsc-bedgraphtobigwig`, `yq`, `jq`
  - `cargo-pkgs` ([packages.txt](src/pkgs/cargo-pkgs/packages.txt)): `ripgrep`, `fd-find`
  - `pipx-pkgs` ([packages.txt](src/pkgs/pipx-pkgs/packages.txt)): `multiqc`, `marimo`, `ruff`
  - `r-pkgs` ([packages.txt](src/pkgs/r-pkgs/packages.txt)): `languageserver`, `lintr`, `data.table`, `BiocManager`
- **Languages**: `go`, `rust`, `r`
- **Editors**: `neovim`, `lazyvim`
- **Shell & CLI Tools**: `tmux`, `starship`, `duf`, `dust`, `lsd`, `zoxide`, `fzf`, `git`, `csvkit`, `apptainer`
- **C Libraries & Compression**: `zlib`, `bzip2`, `xz`, `ncurses`
- **Bioinformatics**: `htslib`, `samtools`, `bcftools`, `snakemake`
- **R Tools**: `radian`
- **macOS Only**: `sshfwd` (persistent SSH port forwards via `launchd` + `autossh`; skipped on Linux)

## HPC Cache & Data Directories

To keep `$HOME` quota usage small on HPC servers, override `MJSTP_CACHE_DIR` and `MJSTP_DATA_DIR` (defaults: `${MJSTP_PREFIX}/var/cache` and `${MJSTP_PREFIX}/var/data`). `mjstp` exports:
- `APPTAINER_CACHEDIR`, `NXF_SINGULARITY_CACHEDIR`, `CONDA_PKGS_DIRS`, `UV_CACHE_DIR`, `PIP_CACHE_DIR` under `${MJSTP_CACHE_DIR}`
- `NXF_HOME` under `${MJSTP_DATA_DIR}`
