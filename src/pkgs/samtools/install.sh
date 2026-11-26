#!/usr/bin/env bash
# Dependencies: htslib, ncurses, zlib, bzip2, xz
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

INSTALL_DIR="${MJSTP_PREFIX}"

TAG="$(github_latest_tag "samtools/samtools")"
VERSION="${TAG#v}"

if [ -x "${INSTALL_DIR}/bin/samtools" ]; then
    CURRENT_VER="$("${INSTALL_DIR}/bin/samtools" --version | head -n 1 | awk '{print $2}')"
    if [ "${CURRENT_VER}" = "${VERSION}" ]; then
        log_info "samtools ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating samtools (${CURRENT_VER:-unknown} -> ${VERSION})..."
else
    log_info "Installing samtools ${VERSION}..."
fi

TARBALL="samtools-${VERSION}.tar.bz2"
URL="https://github.com/samtools/samtools/releases/download/${TAG}/${TARBALL}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading ${URL}..."
download "${URL}"

log_info "Extracting..."
tar xjf "${TARBALL}"
cd "samtools-${VERSION}" || exit 1

log_info "Configuring and building..."
./configure --prefix="${INSTALL_DIR}" --with-htslib=system
make -j"$(cpu_jobs)"
make install

log_success "samtools ${VERSION} installed to ${INSTALL_DIR}."
