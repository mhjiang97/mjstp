#!/usr/bin/env bash
# Dependencies: rust
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Starship..."

# Load Cargo
if [ -f "${HOME}/.cargo/env" ]; then
    # shellcheck disable=SC1091
    source "${HOME}/.cargo/env"
elif [ -f "${HOME}/.profile" ]; then
    # shellcheck disable=SC1091
    source "${HOME}/.profile"
fi

if ! command -v cargo &> /dev/null; then
    log_error "Cargo not found. Rust installation might have failed."
    exit 1
fi

if command -v starship &> /dev/null; then
    if [ -n "$MJSTP_UPDATE" ]; then
        log_info "Updating Starship..."
        cargo install starship --locked --force
    else
        log_info "Starship is already installed."
    fi
else
    cargo install starship --locked
    log_success "Starship installed."
fi

# Add to profile
if [ -n "${MJSTP_PROFILE}" ]; then
    # shellcheck disable=SC2016
    if ! line_in_file 'eval "$(starship init bash)"' "${MJSTP_PROFILE}"; then
        # shellcheck disable=SC2016
        echo 'eval "$(starship init bash)"' >> "${MJSTP_PROFILE}"
        log_info "Added Starship init to profile."
    fi
fi
