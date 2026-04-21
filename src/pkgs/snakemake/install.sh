#!/usr/bin/env bash
# Dependencies: pipx
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

if command -v snakemake &>/dev/null; then
    log_info "Snakemake is already installed."
    exit 0
fi

log_info "Installing Snakemake..."

pipx install snakemake

log_success "Snakemake installed."
