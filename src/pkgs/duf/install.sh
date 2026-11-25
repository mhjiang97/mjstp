#!/usr/bin/env bash
# Dependencies: go
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

GO_BIN="${MJSTP_PREFIX}/bin/go"
TARGET_BIN="${MJSTP_PREFIX}/bin/duf"

if [ ! -x "${GO_BIN}" ]; then
    log_error "Go not found at ${GO_BIN}."
    exit 1
fi

TAG="$(github_latest_tag "muesli/duf")"
VERSION="${TAG#v}"

if [ -x "${TARGET_BIN}" ]; then
    CURRENT_VER="$("${TARGET_BIN}" --version 2>/dev/null | awk '{print $2}' | sed 's/^v//')"
    if [ "${CURRENT_VER}" = "${VERSION}" ]; then
        log_info "Duf ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating Duf (${CURRENT_VER:-unknown} -> ${VERSION})..."
else
    log_info "Installing Duf ${VERSION}..."
fi

GOBIN="${MJSTP_PREFIX}/bin" "${GO_BIN}" install "github.com/muesli/duf@${TAG}"

log_success "Duf ${VERSION} installed to ${TARGET_BIN}."
