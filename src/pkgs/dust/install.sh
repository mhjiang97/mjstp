#!/usr/bin/env bash
# Dependencies: rust
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Dust..."

# Load Cargo
if [ -f "${HOME}/.cargo/env" ]; then
    # shellcheck disable=SC1091
    source "${HOME}/.cargo/env"
elif [ -f "${HOME}/.profile" ]; then
    # shellcheck disable=SC1091
    source "${HOME}/.profile"
fi

if ! command -v cargo &> /dev/null; then
    log_error "Cargo not found. Rust installation might have failed."
    exit 1
fi

if [ -x "${HOME}/.cargo/bin/dust" ]; then
    if [ -n "$MJSTP_UPDATE" ]; then
        log_info "Updating Dust..."
        cargo install du-dust --locked --force
    else
        log_info "Dust is already installed (found ~/.cargo/bin/dust)."
    fi
    exit 0
fi

log_info "Building Dust from source (via Cargo)..."
cargo install du-dust --locked
log_success "Dust installed."
