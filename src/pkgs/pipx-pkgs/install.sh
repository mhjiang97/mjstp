#!/usr/bin/env bash
# Dependencies: pipx
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

PIPX_BIN="${MJSTP_PREFIX}/bin/pipx"
MANIFEST="${SCRIPT_DIR}/packages.txt"

if [ ! -x "${PIPX_BIN}" ]; then
    log_error "pipx not found at ${PIPX_BIN}."
    exit 1
fi

if [ ! -f "${MANIFEST}" ]; then
    log_error "pipx manifest not found at ${MANIFEST}."
    exit 1
fi

while IFS= read -r line || [ -n "${line}" ]; do
    line="${line%%#*}"
    pkg="$(echo "${line}" | xargs)"
    [ -z "${pkg}" ] && continue

    if [ -d "${PIPX_HOME}/venvs/${pkg}" ]; then
        log_info "Ensuring ${pkg} is at the latest version via pipx..."
        "${PIPX_BIN}" upgrade "${pkg}"
    else
        log_info "Installing ${pkg} via pipx..."
        "${PIPX_BIN}" install --force "${pkg}"
    fi
done < "${MANIFEST}"

log_success "All pipx manifest packages processed."
