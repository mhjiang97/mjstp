#!/usr/bin/env bash
# Dependencies: micromamba
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Condax..."

# Check if condax is installed via micromamba (which usually links to ~/.local/bin)
# But strictly, it's inside micromamba's base env.
if [ -x "${HOME}/.local/bin/condax" ]; then
    log_info "Condax is already installed (found ~/.local/bin/condax)."
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
    log_success "Condax installed."
else
    log_error "Could not find micromamba executable. Check previous install steps."
    exit 1
fi
