#!/usr/bin/env bash
# Dependencies:
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

INSTALL_DIR="${MJSTP_PREFIX}"

VERSION="$(git ls-remote --tags --refs https://gitlab.com/bzip2/bzip2.git 'refs/tags/bzip2-*' \
    | sed 's|.*refs/tags/bzip2-||' \
    | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -n 1)"

if [ -z "${VERSION}" ]; then
    log_error "Failed to resolve latest bzip2 version tag."
    exit 1
fi

if [ -x "${INSTALL_DIR}/bin/bzip2" ] && [ -f "${INSTALL_DIR}/include/bzlib.h" ] && [ -e "${INSTALL_DIR}/lib/libbz2.so" ]; then
    CURRENT_VER="$("${INSTALL_DIR}/bin/bzip2" --help 2>&1 | sed -n 's/.*Version \([0-9.]*\),.*/\1/p' | head -n 1)"
    if [ "${CURRENT_VER}" = "${VERSION}" ]; then
        log_info "bzip2 ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating bzip2 (${CURRENT_VER:-unknown} -> ${VERSION})..."
else
    log_info "Installing bzip2 ${VERSION}..."
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Cloning bzip2-${VERSION}..."
git clone --depth 1 --branch "bzip2-${VERSION}" https://gitlab.com/bzip2/bzip2.git
cd bzip2 || exit 1

log_info "Building shared library..."
make -f Makefile-libbz2_so -j"$(cpu_jobs)"
cp -a libbz2.so* "${INSTALL_DIR}/lib/"
ln -sf "libbz2.so.1.0" "${INSTALL_DIR}/lib/libbz2.so"
make -f Makefile-libbz2_so clean

log_info "Building static library and binaries..."
sed -i.bak 's|(PREFIX)/man|(PREFIX)/share/man|g' Makefile
make -j"$(cpu_jobs)" CFLAGS="-fPIC -O2 -g -D_FILE_OFFSET_BITS=64"
make install PREFIX="${INSTALL_DIR}"

# Replace absolute symlinks created by upstream Makefile with relative symlinks
ln -sf bzgrep "${INSTALL_DIR}/bin/bzegrep"
ln -sf bzgrep "${INSTALL_DIR}/bin/bzfgrep"
ln -sf bzmore "${INSTALL_DIR}/bin/bzless"
ln -sf bzdiff "${INSTALL_DIR}/bin/bzcmp"

log_success "bzip2 ${VERSION} installed to ${INSTALL_DIR}."
