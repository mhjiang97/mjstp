#!/usr/bin/env bash
# Dependencies: condax
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Pipx..."

export PATH="${HOME}/.local/bin:${PATH}"

if [ -x "${HOME}/.local/bin/pipx" ]; then
    log_info "Pipx is already installed (found ~/.local/bin/pipx)."
    exit 0
fi

if command -v condax &> /dev/null; then
    condax install -c conda-forge pipx

    # Ensure pipx is in path now
    export PATH="$HOME/.local/pipx/bin:$PATH" # Common pipx path?
    # Condax typically exposes binaries in ~/.condax/bin/pipx or similar?
    # Actually, condax creates envs and exposes binaries in ~/.local/bin by default.

    if command -v pipx &> /dev/null; then
        log_info "Installing argcomplete via pipx..."
        pipx install argcomplete || true

        # Add to profile
        if [ -n "${MJSTP_PROFILE}" ]; then
            # shellcheck disable=SC2016
            if ! line_in_file 'eval "$(register-python-argcomplete pipx)"' "${MJSTP_PROFILE}"; then
                # shellcheck disable=SC2016
                echo 'eval "$(register-python-argcomplete pipx)"' >> "${MJSTP_PROFILE}"
            fi
        fi

        log_success "Pipx installed."
    else
        log_error "Pipx installed via Condax but not found in PATH."
    fi
else
    log_error "Condax not found."
    exit 1
fi
