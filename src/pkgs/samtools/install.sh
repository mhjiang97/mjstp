#!/usr/bin/env bash
# Dependencies: htslib
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

VERSION="1.23"
INSTALL_DIR="${HOME}/local"

if [ -x "${INSTALL_DIR}/bin/samtools" ]; then
    if [ -n "${MJSTP_UPDATE}" ]; then
        log_info "Reinstalling samtools ${VERSION}..."
    else
        log_info "samtools ${VERSION} is already installed."
        exit 0
    fi
fi

log_info "Installing samtools ${VERSION}..."

TARBALL="samtools-${VERSION}.tar.bz2"
URL="https://github.com/samtools/samtools/releases/download/${VERSION}/${TARBALL}"

tmp_dir=$(mktemp -d)
cd "${tmp_dir}" || exit 1

log_info "Downloading ${URL}..."
curl -LO "${URL}"

log_info "Extracting..."
tar xjf "${TARBALL}"
cd "samtools-${VERSION}" || exit 1

log_info "Configuring and building..."
./configure --prefix="${INSTALL_DIR}"
make -j"$(nproc 2>/dev/null || echo 1)"
make install

cd -
rm -rf "${tmp_dir}"

log_success "samtools ${VERSION} installed to ${INSTALL_DIR}."
