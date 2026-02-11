#!/usr/bin/env bash
# Dependencies: pipx
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Radian..."

export PATH="${HOME}/.local/bin:${PATH}"

# Radian is installed via pipx, so it should be in ~/.custom path or linked to ~/.local/bin
if [ -x "${HOME}/.local/bin/radian" ]; then
    log_info "Radian is already installed (found ~/.local/bin/radian)."
    exit 0
fi

if command -v pipx &> /dev/null; then
    pipx install radian
    log_success "Radian installed."
else
    log_error "Pipx not found."
    exit 1
fi
