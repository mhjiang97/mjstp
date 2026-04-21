#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Rust..."

if [ -d "$HOME/.cargo" ] && [ -x "$HOME/.cargo/bin/cargo" ]; then
    if [ -n "$MJSTP_UPDATE" ]; then
        log_info "Updating Rust..."
        rustup update
    else
        log_warn "Rust is already installed (found ~/.cargo/bin/cargo). Use --update to upgrade."
    fi
else
    # -y disables confirmation prompts
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    log_success "Rust installed."
fi

if [ -n "${MJSTP_PROFILE}" ]; then
    # shellcheck disable=SC2016
    if ! line_in_file 'export PATH="$HOME/.cargo/bin:$PATH"' "${MJSTP_PROFILE}"; then
        # shellcheck disable=SC2016
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "${MJSTP_PROFILE}"
        log_info "Added ~/.cargo/bin to PATH in profile."
    fi
fi
