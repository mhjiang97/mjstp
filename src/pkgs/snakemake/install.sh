#!/usr/bin/env bash
# Dependencies: pipx
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

export PATH="${HOME}/local/bin:${HOME}/local/opt/micromamba/bin:${HOME}/.local/bin:${PATH}"

if command -v snakemake &>/dev/null; then
    if [ -n "${MJSTP_UPDATE}" ]; then
        log_info "Updating Snakemake..."
        pipx upgrade snakemake || true
        exit 0
    else
        log_info "Snakemake is already installed."
        exit 0
    fi
fi

log_info "Installing Snakemake..."

if ! command -v pipx &> /dev/null; then
    log_error "pipx is required to install snakemake."
    exit 1
fi

pipx install snakemake

log_success "Snakemake installed."
