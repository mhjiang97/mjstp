#!/usr/bin/env bash
# Dependencies: condax
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

CONDAX_BIN="${MJSTP_PREFIX}/bin/condax"
TARGET_BIN="${MJSTP_PREFIX}/bin/tmux"

if [ ! -x "${CONDAX_BIN}" ]; then
    log_error "Condax not found at ${CONDAX_BIN}."
    exit 1
fi

if [ -x "${TARGET_BIN}" ] && [ -d "${MJSTP_PREFIX}/opt/condax/tmux" ]; then
    log_info "Ensuring Tmux is at the latest version..."
    "${CONDAX_BIN}" update tmux
    log_success "Tmux is up to date."
    exit 0
fi

log_info "Installing Tmux via Condax..."
"${CONDAX_BIN}" install --link-conflict overwrite -c conda-forge tmux
log_success "Tmux installed to ${TARGET_BIN}."
