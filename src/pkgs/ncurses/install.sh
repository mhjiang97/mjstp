#!/usr/bin/env bash
# Dependencies:
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

INSTALL_DIR="${MJSTP_PREFIX}"

VERSION="$(gnu_latest_version "ncurses")"

if [ -x "${INSTALL_DIR}/bin/ncursesw6-config" ]; then
    CURRENT_VER="$("${INSTALL_DIR}/bin/ncursesw6-config" --version | cut -d. -f1,2)"
    if [ "${CURRENT_VER}" = "${VERSION}" ]; then
        log_info "ncurses ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating ncurses (${CURRENT_VER:-unknown} -> ${VERSION})..."
else
    log_info "Installing ncurses ${VERSION}..."
fi

TARBALL="ncurses-${VERSION}.tar.gz"
URL="https://ftpmirror.gnu.org/ncurses/${TARBALL}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading ${URL}..."
if ! download "${URL}"; then
    download "https://ftp.gnu.org/pub/gnu/ncurses/${TARBALL}"
fi

log_info "Extracting..."
tar -xzf "${TARBALL}"
cd "ncurses-${VERSION}" || exit 1

log_info "Configuring and building..."
./configure \
    --prefix="${INSTALL_DIR}" \
    --with-shared \
    --without-debug \
    --enable-widec \
    --enable-overwrite \
    --enable-pc-files \
    --with-pkg-config-libdir="${INSTALL_DIR}/lib/pkgconfig"
make -j"$(cpu_jobs)"
make install

# Provide non-wide symlinks expected by software linking -lncurses / -ltinfo
for lib in ncurses form panel menu; do
    if [ -e "${INSTALL_DIR}/lib/lib${lib}w.so" ] && [ ! -e "${INSTALL_DIR}/lib/lib${lib}.so" ]; then
        ln -sf "lib${lib}w.so" "${INSTALL_DIR}/lib/lib${lib}.so"
    fi
done

log_success "ncurses ${VERSION} installed to ${INSTALL_DIR}."
