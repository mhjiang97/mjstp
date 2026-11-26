#!/usr/bin/env bash
# Dependencies: htslib, zlib, bzip2, xz
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

INSTALL_DIR="${MJSTP_PREFIX}"

TAG="$(github_latest_tag "samtools/bcftools")"
VERSION="${TAG#v}"

if [ -x "${INSTALL_DIR}/bin/bcftools" ]; then
    CURRENT_VER="$("${INSTALL_DIR}/bin/bcftools" --version | head -n 1 | awk '{print $2}')"
    if [ "${CURRENT_VER}" = "${VERSION}" ]; then
        log_info "bcftools ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating bcftools (${CURRENT_VER:-unknown} -> ${VERSION})..."
else
    log_info "Installing bcftools ${VERSION}..."
fi

TARBALL="bcftools-${VERSION}.tar.bz2"
URL="https://github.com/samtools/bcftools/releases/download/${TAG}/${TARBALL}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading ${URL}..."
download "${URL}"

log_info "Extracting..."
tar xjf "${TARBALL}"
cd "bcftools-${VERSION}" || exit 1

log_info "Configuring and building..."
./configure --prefix="${INSTALL_DIR}" --with-htslib=system
make -j"$(cpu_jobs)"
make install

log_success "bcftools ${VERSION} installed to ${INSTALL_DIR}."
