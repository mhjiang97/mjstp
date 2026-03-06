#!/usr/bin/env bash
# Dependencies: micromamba
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Condax..."

if [ -x "${HOME}/local/opt/micromamba/bin/condax" ]; then
    log_info "Condax is already installed."
    exit 0
fi

# Load micromamba shell hook
eval "$("${HOME}/local/bin/micromamba" shell hook -s bash)" 2>/dev/null || true
# Try path
if ! command -v micromamba &> /dev/null; then
    log_error "Micromamba not found in path."
    # Try common location or source bashrc
    # shellcheck disable=SC1091
    if [ -f "${HOME}/.bashrc" ]; then source "${HOME}/.bashrc"; fi
fi

if command -v micromamba &> /dev/null; then
    micromamba install -y -n base -c conda-forge condax
    ln -sf "${HOME}/local/opt/micromamba/bin/condax" "${HOME}/local/bin/condax"
    log_success "Condax installed."
else
    log_error "Could not find micromamba executable. Check previous install steps."
    exit 1
fi
