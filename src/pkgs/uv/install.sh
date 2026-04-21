#!/usr/bin/env bash
# Dependencies: pipx
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing uv..."

export PATH="${HOME}/local/bin:${HOME}/local/opt/micromamba/bin:${HOME}/.local/bin:${PATH}"

if command -v uv &> /dev/null || [ -x "$HOME/.local/bin/uv" ]; then
    if [ -n "$MJSTP_UPDATE" ]; then
        log_info "Updating uv..."
        pipx upgrade uv || true
        exit 0
    else
        log_info "uv is already installed."
        exit 0
    fi
fi

if ! command -v pipx &> /dev/null; then
    log_error "pipx is required to install uv."
    exit 1
fi

pipx install uv

log_success "uv installed."
