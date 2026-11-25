#!/usr/bin/env bash
# Dependencies: rust
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

CARGO_BIN="${CARGO_HOME}/bin/cargo"
TARGET_BIN="${MJSTP_PREFIX}/bin/dust"

if [ ! -x "${CARGO_BIN}" ]; then
    log_error "Cargo not found at ${CARGO_BIN}."
    exit 1
fi

log_info "Ensuring Dust (du-dust) is at the latest version in ${MJSTP_PREFIX}/bin..."
"${CARGO_BIN}" install du-dust --locked --root "${MJSTP_PREFIX}"
log_success "Dust is at the latest version in ${TARGET_BIN}."
