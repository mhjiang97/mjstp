#!/usr/bin/env bash
# Dependencies: pipx
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

PIPX_BIN="${MJSTP_PREFIX}/bin/pipx"
TARGET_BIN="${MJSTP_PREFIX}/bin/snakemake"

if [ ! -x "${PIPX_BIN}" ]; then
    log_error "pipx not found at ${PIPX_BIN}."
    exit 1
fi

if [ -x "${TARGET_BIN}" ] && [ -d "${PIPX_HOME}/venvs/snakemake" ]; then
    log_info "Ensuring Snakemake is at the latest version..."
    "${PIPX_BIN}" upgrade snakemake
    log_success "Snakemake is up to date."
    exit 0
fi

log_info "Installing Snakemake..."
"${PIPX_BIN}" install --force snakemake
log_success "Snakemake installed to ${TARGET_BIN}."
