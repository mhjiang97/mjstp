#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

VERSION="6.6"
INSTALL_DIR="${HOME}/local"

# Check existing installation (ncurses6-config is installed by default)
if [ -x "${INSTALL_DIR}/bin/ncursesw6-config" ]; then
    if [ -n "${MJSTP_UPDATE}" ]; then
        log_info "Reinstalling ncurses ${VERSION}..."
    else
        log_info "ncurses ${VERSION} is already installed at ${INSTALL_DIR}."
        exit 0
    fi
fi

log_info "Installing ncurses ${VERSION}..."

TARBALL="ncurses-${VERSION}.tar.gz"
URL="https://ftp.gnu.org/pub/gnu/ncurses/${TARBALL}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading ${URL}..."
download "${URL}"

log_info "Extracting..."
tar -xzf "${TARBALL}"
cd "ncurses-${VERSION}" || exit 1

log_info "Configuring and building..."
./configure \
    --prefix="${INSTALL_DIR}" \
    --with-shared \
    --without-debug \
    --enable-widec
make -j"$(nproc 2>/dev/null || echo 1)"
make install

log_success "ncurses ${VERSION} installed to ${INSTALL_DIR}."
