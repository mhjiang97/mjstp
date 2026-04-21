#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

if command -v zoxide &>/dev/null; then
    if [ -n "${MJSTP_UPDATE}" ]; then
        log_info "Updating zoxide..."
        # Re-run installer to get latest version
    else
        log_info "zoxide is already installed."
        exit 0
    fi
fi

log_info "Installing zoxide..."

# Download installer to temp file instead of piping to shell
tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
download "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" "${tmp_dir}/install.sh"
bash "${tmp_dir}/install.sh"

if [ -n "${MJSTP_PROFILE}" ]; then
    # shellcheck disable=SC2016
    if ! line_in_file 'eval "$(zoxide init bash)"' "${MJSTP_PROFILE}"; then
        # shellcheck disable=SC2016
        echo 'eval "$(zoxide init bash)"' >> "${MJSTP_PROFILE}"
        log_info "Added zoxide init to profile."
    fi
fi

log_success "zoxide installed."
