#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

VERSION="5.8.3"
INSTALL_DIR="${HOME}/local"

if [ -x "${INSTALL_DIR}/bin/xz" ]; then
    if [ -n "${MJSTP_UPDATE}" ]; then
        log_info "Reinstalling xz ${VERSION}..."
    else
        log_info "xz ${VERSION} is already installed at ${INSTALL_DIR}."
        exit 0
    fi
fi

log_info "Installing xz ${VERSION}..."

TARBALL="xz-${VERSION}.tar.gz"
URL="https://github.com/tukaani-project/xz/releases/download/v${VERSION}/${TARBALL}"

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
make -j"$(nproc 2>/dev/null || echo 1)"
make install

log_success "xz ${VERSION} installed to ${INSTALL_DIR}."
