#!/usr/bin/env bash
# Dependencies: pipx
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

PIPX_BIN="${MJSTP_PREFIX}/bin/pipx"
TARGET_BIN="${MJSTP_PREFIX}/bin/radian"

if [ ! -x "${PIPX_BIN}" ]; then
    log_error "pipx not found at ${PIPX_BIN}."
    exit 1
fi

if [ -x "${TARGET_BIN}" ] && [ -d "${PIPX_HOME}/venvs/radian" ]; then
    log_info "Ensuring Radian is at the latest version..."
    "${PIPX_BIN}" upgrade radian
    log_success "Radian is up to date."
    exit 0
fi

log_info "Installing Radian..."
"${PIPX_BIN}" install --force radian
log_success "Radian installed to ${TARGET_BIN}."
