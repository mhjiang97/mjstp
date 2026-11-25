#!/usr/bin/env bash
# Dependencies:
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

INSTALL_DIR="${MJSTP_PREFIX}"
PC_FILE="${INSTALL_DIR}/lib/pkgconfig/zlib.pc"

TAG="$(github_latest_tag "madler/zlib")"
VERSION="${TAG#v}"

if [ -f "${PC_FILE}" ] && [ -f "${INSTALL_DIR}/include/zlib.h" ]; then
    CURRENT_VER="$(awk '/^Version:/ {print $2}' "${PC_FILE}" 2>/dev/null || true)"
    if [ "${CURRENT_VER}" = "${VERSION}" ]; then
        log_info "zlib ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating zlib (${CURRENT_VER:-unknown} -> ${VERSION})..."
else
    log_info "Installing zlib ${VERSION}..."
fi

TARBALL="zlib-${VERSION}.tar.gz"
URL="https://github.com/madler/zlib/releases/download/${TAG}/${TARBALL}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading ${URL}..."
download "${URL}"

log_info "Extracting..."
tar -xzf "${TARBALL}"
cd "zlib-${VERSION}" || exit 1

log_info "Configuring and building..."
./configure --prefix="${INSTALL_DIR}"
make -j"$(cpu_jobs)"
make install

log_success "zlib ${VERSION} installed to ${INSTALL_DIR}."
