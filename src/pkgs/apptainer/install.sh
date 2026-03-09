#!/usr/bin/env bash
# Dependencies: condax
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Apptainer via Condax..."

export PATH="${HOME}/local/bin:${HOME}/local/opt/micromamba/bin:${PATH}"

if [ -x "${HOME}/local/opt/micromamba/bin/apptainer" ]; then
    log_info "Apptainer is already installed."
    exit 0
fi

if command -v condax &> /dev/null; then
    condax install apptainer
    log_success "Apptainer installed."
else
    log_error "Condax not found."
    exit 1
fi
