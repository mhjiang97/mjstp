#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

if command -v zoxide &>/dev/null; then
    log_info "zoxide is already installed."
    exit 0
fi

log_info "Installing zoxide..."

curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

if [ -n "${MJSTP_PROFILE}" ]; then
    # shellcheck disable=SC2016
    if ! line_in_file 'eval "$(zoxide init bash)"' "${MJSTP_PROFILE}"; then
        # shellcheck disable=SC2016
        echo 'eval "$(zoxide init bash)"' >> "${MJSTP_PROFILE}"
        log_info "Added zoxide init to profile."
    fi
fi

log_success "zoxide installed."
