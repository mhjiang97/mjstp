#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Neovim..."

if [ -x "$HOME/local/bin/nvim" ]; then
    log_info "Neovim is already installed at $HOME/local/bin/nvim."
    exit 0
fi

tmp_dir=$(mktemp -d)
cd "${tmp_dir}" || exit 1

log_info "Downloading Neovim..."
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz

ensure_dir "${HOME}/local"

if tar -xzf nvim-linux-x86_64.tar.gz; then
    cp -r nvim-linux-x86_64/bin nvim-linux-x86_64/lib nvim-linux-x86_64/share "${HOME}/local/"
    log_success "Neovim installed."
else
    log_error "Failed to extract Neovim."
    exit 1
fi

cd -
rm -rf "${tmp_dir}"
