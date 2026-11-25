#!/usr/bin/env bash
# Dependencies: zlib, bzip2, xz
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

INSTALL_DIR="${MJSTP_PREFIX}"

TAG="$(github_latest_tag "samtools/htslib")"
VERSION="${TAG#v}"

if [ -x "${INSTALL_DIR}/bin/htsfile" ]; then
    CURRENT_VER="$("${INSTALL_DIR}/bin/htsfile" --version | head -n 1 | awk '{print $NF}')"
    if [ "${CURRENT_VER}" = "${VERSION}" ]; then
        log_info "htslib ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating htslib (${CURRENT_VER:-unknown} -> ${VERSION})..."
else
    log_info "Installing htslib ${VERSION}..."
fi

TARBALL="htslib-${VERSION}.tar.bz2"
URL="https://github.com/samtools/htslib/releases/download/${TAG}/${TARBALL}"

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
make -j"$(cpu_jobs)"
make install

log_success "htslib ${VERSION} installed to ${INSTALL_DIR}."
