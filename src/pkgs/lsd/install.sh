#!/usr/bin/env bash
# Dependencies: rust
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

if command -v lsd &>/dev/null; then
    log_info "lsd is already installed."
    exit 0
fi

log_info "Installing lsd..."

if [ -f "${HOME}/.cargo/env" ]; then
    # shellcheck disable=SC1091
    source "${HOME}/.cargo/env"
fi

if ! command -v cargo &>/dev/null; then
    log_error "Cargo not found. Rust installation might have failed."
    exit 1
fi

cargo install lsd --locked

log_success "lsd installed."
