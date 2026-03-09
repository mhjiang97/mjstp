#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

VERSION="1.0.8"
INSTALL_DIR="${HOME}/local"

if [ -x "${INSTALL_DIR}/bin/bzip2" ]; then
    if [ -n "${MJSTP_UPDATE}" ]; then
        log_info "Reinstalling bzip2 ${VERSION}..."
    else
        log_info "bzip2 ${VERSION} is already installed at ${INSTALL_DIR}."
        exit 0
    fi
fi

log_info "Installing bzip2 ${VERSION}..."

tmp_dir=$(mktemp -d)
cd "${tmp_dir}" || exit 1

log_info "Cloning bzip2 ${VERSION}..."
git clone --depth 1 --branch bzip2-${VERSION} https://gitlab.com/bzip2/bzip2.git
cd bzip2

log_info "Building with CMake..."
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE="Release" -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
cmake --build .
ctest -V
cmake --build . --target install

cd -
rm -rf "${tmp_dir}"

log_success "bzip2 ${VERSION} installed to ${INSTALL_DIR}."
