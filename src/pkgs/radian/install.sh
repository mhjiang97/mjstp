#!/usr/bin/env bash
# Dependencies: pipx
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Radian..."

export PATH="${HOME}/local/bin:${HOME}/local/opt/micromamba/bin:${HOME}/.local/bin:${PATH}"

if [ -x "${HOME}/.local/bin/radian" ] || command -v radian &>/dev/null; then
    if [ -n "${MJSTP_UPDATE}" ]; then
        log_info "Updating Radian..."
        pipx upgrade radian || true
        exit 0
    else
        log_info "Radian is already installed."
        exit 0
    fi
fi

if command -v pipx &> /dev/null; then
    pipx install radian
    log_success "Radian installed."
else
    log_error "Pipx not found."
    exit 1
fi
