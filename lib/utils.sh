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

# System Check
check_system() {
    local os
    os=$(uname -s)
    local arch
    arch=$(uname -m)

    if [[ "$os" != "Linux" ]]; then
        log_warn "This script is intended for Linux. Current OS: $os"
        # We allow continuation but warn heavily
    fi

    if [[ "$arch" != "x86_64" ]]; then
        log_error "This setup strictly requires x86_64 structure. Current Arch: $arch"
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
