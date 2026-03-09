#!/usr/bin/env bash
# Dependencies: condax
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing R Base..."

export PATH="${HOME}/local/bin:${HOME}/local/opt/micromamba/bin:${PATH}"

if [ -x "${HOME}/local/opt/micromamba/bin/R" ]; then
    log_info "R Base is already installed."
    exit 0
fi

if command -v condax &> /dev/null; then
    condax install -c conda-forge r-base
    log_success "R Base installed."
else
    log_error "Condax not found."
    exit 1
fi
