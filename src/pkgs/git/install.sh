#!/usr/bin/env bash
# Dependencies: condax
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

if command -v git &>/dev/null; then
    log_info "Git is already installed."
    exit 0
fi

log_info "Installing Git..."

condax install -c conda-forge git

log_success "Git installed."
