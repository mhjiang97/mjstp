#!/usr/bin/env bash
# Dependencies: htslib
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

VERSION="1.23"
INSTALL_DIR="${HOME}/local"

if [ -x "${INSTALL_DIR}/bin/bcftools" ]; then
    if [ -n "${MJSTP_UPDATE}" ]; then
        log_info "Reinstalling bcftools ${VERSION}..."
    else
        log_info "bcftools ${VERSION} is already installed."
        exit 0
    fi
fi

log_info "Installing bcftools ${VERSION}..."

TARBALL="bcftools-${VERSION}.tar.bz2"
URL="https://github.com/samtools/bcftools/releases/download/${VERSION}/${TARBALL}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading ${URL}..."
download "${URL}"

log_info "Extracting..."
tar xjf "${TARBALL}"
cd "bcftools-${VERSION}" || exit 1

log_info "Configuring and building..."
./configure --prefix="${INSTALL_DIR}"
make -j"$(nproc 2>/dev/null || echo 1)"
make install

log_success "bcftools ${VERSION} installed to ${INSTALL_DIR}."
