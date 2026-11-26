#!/usr/bin/env bash
# Dependencies: condax
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

CONDAX_BIN="${MJSTP_PREFIX}/bin/condax"
MANIFEST="${SCRIPT_DIR}/packages.txt"

if [ ! -x "${CONDAX_BIN}" ]; then
    log_error "Condax not found at ${CONDAX_BIN}."
    exit 1
fi

if [ ! -f "${MANIFEST}" ]; then
    log_error "Condax manifest not found at ${MANIFEST}."
    exit 1
fi

while IFS= read -r line || [ -n "${line}" ]; do
    # Strip comments and leading/trailing whitespace
    line="${line%%#*}"
    line="$(echo "${line}" | xargs)"
    [ -z "${line}" ] && continue

    pkg="${line%% *}"
    channels="${line#* }"
    if [ "${channels}" = "${pkg}" ] || [ -z "${channels}" ]; then
        channels="conda-forge"
    fi

    if [ -d "${MJSTP_PREFIX}/opt/condax/${pkg}" ]; then
        log_info "Updating ${pkg} via Condax..."
        "${CONDAX_BIN}" update --link-conflict overwrite "${pkg}"
    else
        log_info "Installing ${pkg} (${channels}) via Condax..."
        channel_args=()
        IFS=',' read -ra ch_list <<< "${channels}"
        for ch in "${ch_list[@]}"; do
            ch="$(echo "${ch}" | xargs)"
            [ -n "${ch}" ] && channel_args+=(-c "${ch}")
        done
        "${CONDAX_BIN}" install --link-conflict overwrite "${channel_args[@]}" "${pkg}"
    fi
done < "${MANIFEST}"

log_success "All Condax manifest packages processed."
