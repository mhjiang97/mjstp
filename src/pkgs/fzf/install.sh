#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

if [ -x "${HOME}/.fzf/bin/fzf" ]; then
    log_info "fzf is already installed."
    exit 0
fi

log_info "Installing fzf..."

git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
"${HOME}/.fzf/install" --all --no-update-rc

if [ -n "${MJSTP_PROFILE}" ]; then
    if ! line_in_file "source \"\${HOME}/.fzf.bash\"" "${MJSTP_PROFILE}"; then
        echo "[ -f \"\${HOME}/.fzf.bash\" ] && source \"\${HOME}/.fzf.bash\"" >> "${MJSTP_PROFILE}"
        log_info "Added fzf shell integration to profile."
    fi
fi

log_success "fzf installed."
