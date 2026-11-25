#!/usr/bin/env bash
# Dependencies:
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

GO_ROOT="${MJSTP_PREFIX}/opt/go"

GO_TAG="$(curl -fsSL "https://go.dev/VERSION?m=text" | head -n 1 | tr -d '[:space:]')"
if [[ -z "${GO_TAG}" || "${GO_TAG}" != go* ]]; then
    log_error "Failed to resolve latest Go version from go.dev."
    exit 1
fi
VERSION="${GO_TAG#go}"

if [ -x "${GO_ROOT}/bin/go" ]; then
    ln -sf "${GO_ROOT}/bin/go" "${MJSTP_PREFIX}/bin/go"
    ln -sf "${GO_ROOT}/bin/gofmt" "${MJSTP_PREFIX}/bin/gofmt"
    CURRENT_TAG="$("${GO_ROOT}/bin/go" version | awk '{print $3}')"
    if [ "${CURRENT_TAG}" = "${GO_TAG}" ]; then
        log_info "Go ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating Go (${CURRENT_TAG#go} -> ${VERSION})..."
else
    log_info "Installing Go ${VERSION}..."
fi

TARBALL="${GO_TAG}.linux-amd64.tar.gz"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading ${TARBALL}..."
download "https://go.dev/dl/${TARBALL}"

mkdir -p "${tmp_dir}/extract"
tar -C "${tmp_dir}/extract" -xzf "${TARBALL}"

rm -rf "${GO_ROOT}"
mv "${tmp_dir}/extract/go" "${GO_ROOT}"

ln -sf "${GO_ROOT}/bin/go" "${MJSTP_PREFIX}/bin/go"
ln -sf "${GO_ROOT}/bin/gofmt" "${MJSTP_PREFIX}/bin/gofmt"

log_success "Go ${VERSION} installed to ${GO_ROOT}."
