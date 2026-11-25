#!/usr/bin/env bash
# Dependencies: pipx
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

PIPX_BIN="${MJSTP_PREFIX}/bin/pipx"
TARGET_BIN="${MJSTP_PREFIX}/bin/csvcut"

if [ ! -x "${PIPX_BIN}" ]; then
    log_error "pipx not found at ${PIPX_BIN}."
    exit 1
fi

if [ -x "${TARGET_BIN}" ] && [ -d "${PIPX_HOME}/venvs/csvkit" ]; then
    log_info "Ensuring csvkit is at the latest version..."
    "${PIPX_BIN}" upgrade csvkit
    log_success "csvkit is up to date."
    exit 0
fi

log_info "Installing csvkit..."
"${PIPX_BIN}" install --force csvkit
log_success "csvkit installed to ${MJSTP_PREFIX}/bin."
