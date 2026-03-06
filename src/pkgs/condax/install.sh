#!/usr/bin/env bash
# Dependencies: pipx
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

if command -v condax &>/dev/null; then
    log_info "Condax is already installed."
    exit 0
fi

log_info "Installing Condax..."

pipx install condax

log_success "Condax installed."
