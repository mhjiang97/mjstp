#!/usr/bin/env bash
# Dependencies: condax
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Tmux via Condax..."

# Ensure condax is in path, usually in ~/.local/bin or via conda
export PATH="${HOME}/local/bin:${HOME}/local/opt/micromamba/bin:${PATH}"

if [ -x "${HOME}/local/opt/micromamba/bin/tmux" ]; then
    log_info "Tmux is already installed."
    exit 0
fi

if command -v condax &> /dev/null; then
    condax install -c conda-forge tmux
    log_success "Tmux installed."
else
    log_error "Condax not found."
    exit 1
fi
