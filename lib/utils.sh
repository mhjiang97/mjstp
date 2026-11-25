#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Root-like user prefix (no sudo required)
export MJSTP_PREFIX="${MJSTP_PREFIX:-${HOME}/local}"

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

ensure_dir() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
        log_info "Created directory: $1"
    fi
}

# Initialize ~/local FHS directory tree and export build/tool environment
init_local_env() {
    local p="${MJSTP_PREFIX}"
    mkdir -p \
        "${p}/bin" \
        "${p}/lib/pkgconfig" \
        "${p}/lib64/pkgconfig" \
        "${p}/include" \
        "${p}/share/man/man1" \
        "${p}/etc" \
        "${p}/opt"

    export MAMBA_ROOT_PREFIX="${p}/opt/micromamba"
    export CONDAXRC="${p}/etc/condaxrc"
    export PIPX_HOME="${p}/opt/pipx"
    export PIPX_BIN_DIR="${p}/bin"
    export PIPX_MAN_DIR="${p}/share/man"
    export GOPATH="${p}/opt/gopath"
    export GOBIN="${p}/bin"
    export CARGO_HOME="${p}/opt/cargo"
    export RUSTUP_HOME="${p}/opt/rustup"

    export PATH="${p}/bin:${p}/opt/go/bin:${p}/opt/cargo/bin:${p}/opt/micromamba/bin:${PATH}"
    export MANPATH="${p}/share/man:${MANPATH:-}"
    export CPPFLAGS="-I${p}/include -I${p}/include/ncursesw"
    export CFLAGS="-O2 -I${p}/include -I${p}/include/ncursesw"
    export LDFLAGS="-L${p}/lib64 -L${p}/lib -Wl,-rpath,${p}/lib64 -Wl,-rpath,${p}/lib"
    export PKG_CONFIG_PATH="${p}/lib/pkgconfig:${p}/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
}

# Portable parallel job count
cpu_jobs() {
    nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1
}

# True when an install script opts out of the default Linux x86_64 requirement.
# Opt out with a header the package enforces itself, for example:
#   # Platforms: darwin
# Missing header, or an explicit linux-x86_64 tag, keeps the default requirement.
_pkg_requires_linux_x86_64() {
    local script="$1"
    local line tags tag

    line=$(grep -i -m1 "^# Platforms:" "$script" 2>/dev/null || true)
    if [[ -z "$line" ]]; then
        return 0
    fi

    line=${line#*:}
    line=${line// /}
    IFS=',' read -ra tags <<< "$line"
    for tag in "${tags[@]}"; do
        if [[ "$tag" == "linux-x86_64" ]]; then
            return 0
        fi
    done
    return 1
}

# System & Prerequisite Check
# Usage: check_system [install.sh ...]
check_system() {
    local os arch script pkg needs_c_toolchain=0
    local -a required=()
    os=$(uname -s)
    arch=$(uname -m)

    for cmd in curl tar; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required system tool '$cmd' not found."
            return 1
        fi
    done

    if [[ $# -eq 0 ]]; then
        required+=("default toolchain")
    else
        for script in "$@"; do
            pkg="$(basename "$(dirname "$script")")"
            if _pkg_requires_linux_x86_64 "$script"; then
                required+=("$pkg")
            fi
            case "$pkg" in
                zlib|bzip2|xz|ncurses|htslib|samtools|bcftools|dust|lsd|starship)
                    needs_c_toolchain=1
                    ;;
            esac
        done
    fi

    if [[ "$needs_c_toolchain" -eq 1 ]]; then
        if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1; then
            log_error "A C compiler (gcc/cc) is required to build source packages."
            return 1
        fi
        if ! command -v make >/dev/null 2>&1; then
            log_error "'make' is required to build source packages."
            return 1
        fi
    fi

    # Every requested package enforces its own platform.
    if [[ ${#required[@]} -eq 0 ]]; then
        return 0
    fi

    if [[ "$os" != "Linux" ]]; then
        log_warn "This script is intended for Linux. Current OS: $os"
    fi

    if [[ "$arch" != "x86_64" ]]; then
        log_error "This setup strictly requires x86_64 architecture. Current Arch: $arch"
        log_error "Affected packages: ${required[*]}"
        return 1
    fi
}

# Idempotency helper — checks if a string appears anywhere in a file
line_in_file() {
    grep -qF "$1" "$2" 2>/dev/null
}

# Download helper — wraps curl with -f (fail on HTTP errors) and retries
# Usage: download "https://example.com/file.tar.gz" [output_file]
download() {
    local url="$1"
    local output="${2:-}"

    if [[ -n "$output" ]]; then
        curl -fSL --retry 3 --retry-delay 2 -o "$output" "$url"
    else
        curl -fSLO --retry 3 --retry-delay 2 "$url"
    fi
}

# Resolve latest release tag for a GitHub repository (e.g. "samtools/samtools").
# Uses HTTP redirect first to avoid unauthenticated GitHub API rate limits on shared servers,
# falling back to the REST API if needed.
github_latest_tag() {
    local repo="$1"
    local effective_url tag api_url
    local -a auth_args=()

    effective_url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${repo}/releases/latest" 2>/dev/null || true)
    if [[ "$effective_url" == *"/releases/tag/"* ]]; then
        tag="${effective_url##*/releases/tag/}"
        tag="${tag%%\?*}"
        tag="${tag%%/}"
        if [[ -n "$tag" ]]; then
            printf '%s\n' "$tag"
            return 0
        fi
    fi

    api_url="https://api.github.com/repos/${repo}/releases/latest"
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        auth_args=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
    fi
    tag=$(curl -fsSL "${auth_args[@]}" "$api_url" 2>/dev/null | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
    if [[ -n "$tag" ]]; then
        printf '%s\n' "$tag"
        return 0
    fi

    log_error "Failed to resolve latest GitHub release tag for ${repo}."
    return 1
}

# Resolve latest GNU tarball version (e.g. gnu_latest_version "ncurses" -> "6.6")
gnu_latest_version() {
    local pkg="$1"
    local html ver
    for base in "https://ftpmirror.gnu.org/${pkg}/" "https://ftp.gnu.org/pub/gnu/${pkg}/"; do
        html=$(curl -fsSL --max-time 20 "$base" 2>/dev/null || true)
        if [[ -n "$html" ]]; then
            ver=$(printf '%s\n' "$html" \
                | grep -oE "${pkg}-[0-9]+\.[0-9]+(\.[0-9]+)?\.tar\.gz" \
                | sed -E "s/^${pkg}-//; s/\.tar\.gz$//" \
                | sort -t. -k1,1n -k2,2n -k3,3n \
                | tail -n 1)
            if [[ -n "$ver" ]]; then
                printf '%s\n' "$ver"
                return 0
            fi
        fi
    done
    log_error "Failed to resolve latest GNU version for ${pkg}."
    return 1
}
