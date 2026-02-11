#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Neovim..."

if [ -d "$HOME/local/opt/nvim-linux-x86_64" ] && [ -x "$HOME/local/opt/nvim-linux-x86_64/bin/nvim" ]; then
    log_info "Neovim is already installed at $HOME/local/opt/nvim-linux-x86_64."
    exit 0
fi

tmp_dir=$(mktemp -d)
cd "${tmp_dir}" || exit 1

log_info "Downloading Neovim..."
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz

ensure_dir "${HOME}/local/opt"
rm -rf "${HOME}/local/opt/nvim-linux-x86_64"

if tar -C "${HOME}/local/opt" -xzf nvim-linux-x86_64.tar.gz; then
    ensure_dir "${HOME}/local/bin"
    ln -sf "${HOME}/local/opt/nvim-linux-x86_64/bin/nvim" "${HOME}/local/bin/nvim"
    log_success "Neovim installed."
else
    log_error "Failed to extract Neovim."
    exit 1
fi

cd -
rm -rf "${tmp_dir}"
