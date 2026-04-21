#!/usr/bin/env bash
# Dependencies: pipx
set -e

# shellcheck disable=SC1091
[ -n "$LIB_DIR" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing csvkit..."

export PATH="${HOME}/local/bin:${HOME}/local/opt/micromamba/bin:${HOME}/.local/bin:${PATH}"

if command -v csvcut &> /dev/null || [ -x "$HOME/.local/bin/csvcut" ]; then
    if [ -n "$MJSTP_UPDATE" ]; then
        log_info "Updating csvkit..."
        pipx upgrade csvkit || true
        exit 0
    else
        log_info "csvkit is already installed."
        exit 0
    fi
fi

if ! command -v pipx &> /dev/null; then
    log_error "pipx is required to install csvkit."
    exit 1
fi

pipx install csvkit

log_success "csvkit installed."
