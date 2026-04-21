#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

VERSION="1.23"
INSTALL_DIR="${HOME}/local"

# Check existing installation
if [ -x "${INSTALL_DIR}/bin/htsfile" ]; then
    if [ -n "${MJSTP_UPDATE}" ]; then
        log_info "Reinstalling htslib ${VERSION}..."
    else
        log_info "htslib ${VERSION} is already installed at ${INSTALL_DIR}."
        exit 0
    fi
fi

log_info "Installing htslib ${VERSION}..."

TARBALL="htslib-${VERSION}.tar.bz2"
URL="https://github.com/samtools/htslib/releases/download/${VERSION}/${TARBALL}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading ${URL}..."
download "${URL}"

log_info "Extracting..."
tar xjf "${TARBALL}"
cd "htslib-${VERSION}" || exit 1

log_info "Configuring and building..."
./configure --prefix="${INSTALL_DIR}"
make -j"$(nproc 2>/dev/null || echo 1)"
make install

log_success "htslib ${VERSION} installed to ${INSTALL_DIR}."

if [ -n "${MJSTP_PROFILE}" ]; then
    if ! line_in_file "export PATH=\$HOME/local/bin:\$PATH" "${MJSTP_PROFILE}"; then
        echo "export PATH=\$HOME/local/bin:\$PATH" >> "${MJSTP_PROFILE}"
        log_info "Added ~/local/bin to PATH in profile."
    fi
fi
