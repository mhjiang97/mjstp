#!/usr/bin/env bash
# Dependencies: rust
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

CARGO_BIN="${CARGO_HOME}/bin/cargo"
MANIFEST="${SCRIPT_DIR}/packages.txt"

if [ ! -x "${CARGO_BIN}" ]; then
    log_error "Cargo not found at ${CARGO_BIN}."
    exit 1
fi

if [ ! -f "${MANIFEST}" ]; then
    log_error "Cargo manifest not found at ${MANIFEST}."
    exit 1
fi

while IFS= read -r line || [ -n "${line}" ]; do
    line="${line%%#*}"
    crate="$(echo "${line}" | xargs)"
    [ -z "${crate}" ] && continue

    log_info "Ensuring ${crate} is at the latest version in ${MJSTP_PREFIX}/bin..."
    "${CARGO_BIN}" install "${crate}" --locked --force --root "${MJSTP_PREFIX}"
done < "${MANIFEST}"

log_success "All Cargo manifest crates processed."
