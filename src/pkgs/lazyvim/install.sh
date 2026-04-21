#!/usr/bin/env bash
# Dependencies: neovim, git
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

if [ -f "${HOME}/.config/nvim/lua/config/lazy.lua" ]; then
    log_info "LazyVim is already installed."
    exit 0
fi

log_info "Installing LazyVim..."

# Backup existing config if present
if [ -d "${HOME}/.config/nvim" ]; then
    mv "${HOME}/.config/nvim" "${HOME}/.config/nvim.bak"
    log_info "Existing Neovim config backed up to ~/.config/nvim.bak"
fi
[ -d "${HOME}/.local/share/nvim" ] && mv "${HOME}/.local/share/nvim" "${HOME}/.local/share/nvim.bak"
[ -d "${HOME}/.local/state/nvim" ] && mv "${HOME}/.local/state/nvim" "${HOME}/.local/state/nvim.bak"
[ -d "${HOME}/.cache/nvim"       ] && mv "${HOME}/.cache/nvim"       "${HOME}/.cache/nvim.bak"

git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"
rm -rf "${HOME}/.config/nvim/.git"

log_success "LazyVim installed."
