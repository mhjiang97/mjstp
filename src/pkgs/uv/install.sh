#!/usr/bin/env bash
# Dependencies: pipx
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

PIPX_BIN="${MJSTP_PREFIX}/bin/pipx"
TARGET_BIN="${MJSTP_PREFIX}/bin/uv"

if [ ! -x "${PIPX_BIN}" ]; then
    log_error "pipx not found at ${PIPX_BIN}."
    exit 1
fi

if [ -x "${TARGET_BIN}" ] && [ -d "${PIPX_HOME}/venvs/uv" ]; then
    log_info "Ensuring uv is at the latest version..."
    "${PIPX_BIN}" upgrade uv
    log_success "uv is up to date."
    exit 0
fi

log_info "Installing uv..."
"${PIPX_BIN}" install --force uv
log_success "uv installed to ${TARGET_BIN}."
