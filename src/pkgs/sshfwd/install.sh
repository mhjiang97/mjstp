#!/usr/bin/env bash
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

INSTALL_DIR="${HOME}/local"
PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${PKG_DIR}/sshfwd"
DEST="${INSTALL_DIR}/bin/sshfwd"

# sshfwd drives launchd LaunchAgents and Homebrew's autossh — macOS only
if [[ "$(uname -s)" != "Darwin" ]]; then
    log_warn "sshfwd requires macOS (launchd + autossh). Skipping."
    exit 0
fi

if [ -x "${DEST}" ]; then
    if cmp -s "${SRC}" "${DEST}"; then
        log_info "sshfwd is already installed and up to date."
        exit 0
    elif [ -z "${MJSTP_UPDATE}" ]; then
        log_warn "${DEST} differs from ${SRC}; run with --update to overwrite."
        exit 0
    fi
    log_info "Reinstalling sshfwd..."
fi

if ! command -v autossh >/dev/null 2>&1; then
    log_warn "autossh not found; install it with: brew install autossh"
fi

ensure_dir "${INSTALL_DIR}/bin"
install -m 755 "${SRC}" "${DEST}"

log_success "sshfwd installed to ${DEST}."
