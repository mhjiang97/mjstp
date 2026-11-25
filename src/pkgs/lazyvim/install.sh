#!/usr/bin/env bash
# Dependencies: neovim, git
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/nvim"
NVIM_BIN="${MJSTP_PREFIX}/bin/nvim"

if [ -f "${NVIM_CONFIG_DIR}/lua/config/lazy.lua" ]; then
    if [ -x "${NVIM_BIN}" ]; then
        log_info "Syncing LazyVim plugins to latest..."
        "${NVIM_BIN}" --headless "+Lazy! sync" +qa || true
        log_success "LazyVim plugins are up to date."
    else
        log_info "LazyVim is already installed at ${NVIM_CONFIG_DIR}."
    fi
    exit 0
fi

log_info "Installing LazyVim..."

if [ -d "${NVIM_CONFIG_DIR}" ]; then
    mv "${NVIM_CONFIG_DIR}" "${NVIM_CONFIG_DIR}.bak"
    log_info "Existing Neovim config backed up to ${NVIM_CONFIG_DIR}.bak"
fi
[ -d "${HOME}/.local/share/nvim" ] && mv "${HOME}/.local/share/nvim" "${HOME}/.local/share/nvim.bak"
[ -d "${HOME}/.local/state/nvim" ] && mv "${HOME}/.local/state/nvim" "${HOME}/.local/state/nvim.bak"
[ -d "${HOME}/.cache/nvim"       ] && mv "${HOME}/.cache/nvim"       "${HOME}/.cache/nvim.bak"

ensure_dir "$(dirname "${NVIM_CONFIG_DIR}")"
git clone --depth 1 https://github.com/LazyVim/starter "${NVIM_CONFIG_DIR}"
rm -rf "${NVIM_CONFIG_DIR}/.git"

if [ -x "${NVIM_BIN}" ]; then
    "${NVIM_BIN}" --headless "+Lazy! sync" +qa || true
fi

log_success "LazyVim installed."
