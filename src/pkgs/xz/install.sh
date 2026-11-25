#!/usr/bin/env bash
# Dependencies:
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

INSTALL_DIR="${MJSTP_PREFIX}"

TAG="$(github_latest_tag "tukaani-project/xz")"
VERSION="${TAG#v}"

if [ -x "${INSTALL_DIR}/bin/xz" ] && [ -f "${INSTALL_DIR}/include/lzma.h" ]; then
    CURRENT_VER="$("${INSTALL_DIR}/bin/xz" --version | head -n 1 | awk '{print $NF}')"
    if [ "${CURRENT_VER}" = "${VERSION}" ]; then
        log_info "xz ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating xz (${CURRENT_VER:-unknown} -> ${VERSION})..."
else
    log_info "Installing xz ${VERSION}..."
fi

TARBALL="xz-${VERSION}.tar.gz"
URL="https://github.com/tukaani-project/xz/releases/download/${TAG}/${TARBALL}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading ${URL}..."
download "${URL}"

log_info "Extracting..."
tar -xzf "${TARBALL}"
cd "xz-${VERSION}" || exit 1

log_info "Configuring and building..."
./configure --prefix="${INSTALL_DIR}"
make -j"$(cpu_jobs)"
make install

log_success "xz ${VERSION} installed to ${INSTALL_DIR}."
