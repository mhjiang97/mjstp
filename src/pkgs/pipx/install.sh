#!/usr/bin/env bash
# Dependencies: condax
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Pipx..."

export PATH="${HOME}/local/bin:${HOME}/local/opt/micromamba/bin:${HOME}/.local/bin:${PATH}"

if [ -x "${HOME}/.local/bin/pipx" ]; then
    log_info "Pipx is already installed."
    exit 0
fi

if ! command -v condax &>/dev/null; then
    log_error "Condax not found."
    exit 1
fi

condax install -c conda-forge pipx

if ! command -v pipx &>/dev/null; then
    log_error "Pipx installed via condax but not found in PATH."
    exit 1
fi

log_info "Installing argcomplete via pipx..."
pipx install argcomplete || true

if [ -n "${MJSTP_PROFILE}" ]; then
    # shellcheck disable=SC2016
    if ! line_in_file 'eval "$(register-python-argcomplete pipx)"' "${MJSTP_PROFILE}"; then
        # shellcheck disable=SC2016
        echo 'eval "$(register-python-argcomplete pipx)"' >> "${MJSTP_PROFILE}"
    fi
fi

log_success "Pipx installed."
