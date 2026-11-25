#!/usr/bin/env bash
# Dependencies: condax
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

CONDAX_BIN="${MJSTP_PREFIX}/bin/condax"
TARGET_BIN="${MJSTP_PREFIX}/bin/R"

if [ ! -x "${CONDAX_BIN}" ]; then
    log_error "Condax not found at ${CONDAX_BIN}."
    exit 1
fi

if [ -x "${TARGET_BIN}" ] && [ -d "${MJSTP_PREFIX}/opt/condax/r-base" ]; then
    log_info "Ensuring R Base is at the latest version..."
    "${CONDAX_BIN}" update r-base
    log_success "R Base is up to date."
    exit 0
fi

log_info "Installing R Base via Condax..."
"${CONDAX_BIN}" install --force -c conda-forge r-base
log_success "R Base installed to ${TARGET_BIN}."
