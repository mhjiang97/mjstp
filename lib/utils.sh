#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# System Check
# Usage: check_system [install.sh ...]
# With no scripts, the default Linux x86_64 requirement applies.
# Scripts tagged with a non-default "# Platforms:" header are skipped here;
# those packages decide for themselves whether to install or skip.
check_system() {
    local os arch script
    local -a required=()
    os=$(uname -s)
    arch=$(uname -m)

    if [[ $# -eq 0 ]]; then
        required+=("default toolchain")
    else
        for script in "$@"; do
            if _pkg_requires_linux_x86_64 "$script"; then
                required+=("$(basename "$(dirname "$script")")")
            fi
        done
    fi

    # Every requested package enforces its own platform.
    if [[ ${#required[@]} -eq 0 ]]; then
        return 0
    fi

    if [[ "$os" != "Linux" ]]; then
        log_warn "This script is intended for Linux. Current OS: $os"
        # We allow continuation but warn heavily
    fi

    if [[ "$arch" != "x86_64" ]]; then
        log_error "This setup strictly requires x86_64 structure. Current Arch: $arch"
        log_error "Affected packages: ${required[*]}"
        return 1
    fi
}

# Idempotency helper — checks if a string appears anywhere in a file
# Usage: line_in_file "export PATH=..." ~/.bashrc || echo "..." >> ~/.bashrc
line_in_file() {
    grep -qF "$1" "$2" 2>/dev/null
}

ensure_dir() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
        log_info "Created directory: $1"
    fi
}

# Download helper — wraps curl with -f (fail on HTTP errors) and retries
# Usage: download "https://example.com/file.tar.gz" [output_file]
download() {
    local url="$1"
    local output="$2"

    if [[ -n "$output" ]]; then
        curl -fSL --retry 3 --retry-delay 2 -o "$output" "$url"
    else
        curl -fSLO --retry 3 --retry-delay 2 "$url"
    fi
}
