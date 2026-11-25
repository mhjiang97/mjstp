#!/usr/bin/env bash
# Dependencies:
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

NVIM_ROOT="${MJSTP_PREFIX}/opt/nvim"
TARGET_BIN="${MJSTP_PREFIX}/bin/nvim"

TAG="$(github_latest_tag "neovim/neovim")"

if [ -x "${NVIM_ROOT}/bin/nvim" ]; then
    ln -sf "${NVIM_ROOT}/bin/nvim" "${TARGET_BIN}"
    if [ -f "${NVIM_ROOT}/share/man/man1/nvim.1" ]; then
        ln -sf "${NVIM_ROOT}/share/man/man1/nvim.1" "${MJSTP_PREFIX}/share/man/man1/nvim.1"
    fi
    CURRENT_TAG="$("${TARGET_BIN}" --version | head -n 1 | awk '{print $2}')"
    if [ "${CURRENT_TAG}" = "${TAG}" ]; then
        log_info "Neovim ${TAG} is already at the latest version."
        exit 0
    fi
    log_info "Updating Neovim (${CURRENT_TAG:-unknown} -> ${TAG})..."
else
    log_info "Installing Neovim ${TAG}..."
fi

TARBALL="nvim-linux-x86_64.tar.gz"
URL="https://github.com/neovim/neovim/releases/download/${TAG}/${TARBALL}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading ${URL}..."
download "${URL}"

tar -xzf "${TARBALL}"
rm -rf "${NVIM_ROOT}"
mv "${tmp_dir}/nvim-linux-x86_64" "${NVIM_ROOT}"

ln -sf "${NVIM_ROOT}/bin/nvim" "${TARGET_BIN}"
if [ -f "${NVIM_ROOT}/share/man/man1/nvim.1" ]; then
    ln -sf "${NVIM_ROOT}/share/man/man1/nvim.1" "${MJSTP_PREFIX}/share/man/man1/nvim.1"
fi

log_success "Neovim ${TAG} installed to ${NVIM_ROOT}."
