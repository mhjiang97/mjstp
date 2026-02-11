#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Rust..."

if [ -d "$HOME/.cargo" ] && [ -x "$HOME/.cargo/bin/cargo" ]; then
    log_warn "Rust is already installed (found ~/.cargo/bin/cargo)."
else
    # -y disables confirmation prompts
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    log_success "Rust installed."
fi
