#!/usr/bin/env bash
# Dependencies:
# Platforms: darwin
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

INSTALL_DIR="${MJSTP_PREFIX}"
SRC="${SCRIPT_DIR}/sshfwd"
DEST="${INSTALL_DIR}/bin/sshfwd"

# sshfwd drives launchd LaunchAgents and Homebrew's autossh — macOS only.
# The "# Platforms: darwin" header above exempts it from the Linux x86_64 system check.
if [[ "$(uname -s)" != "Darwin" ]]; then
    log_warn "sshfwd requires macOS (launchd + autossh). Skipping."
    exit 0
fi

if [ -x "${DEST}" ] && cmp -s "${SRC}" "${DEST}"; then
    log_info "sshfwd is already at the latest version."
    exit 0
fi

if ! command -v autossh >/dev/null 2>&1; then
    log_warn "autossh not found; install it with: brew install autossh"
fi

ensure_dir "${INSTALL_DIR}/bin"
install -m 755 "${SRC}" "${DEST}"

log_success "sshfwd installed to ${DEST}."
