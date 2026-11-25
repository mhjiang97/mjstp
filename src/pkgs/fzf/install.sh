#!/usr/bin/env bash
# Dependencies:
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

FZF_ROOT="${MJSTP_PREFIX}/opt/fzf"
TARGET_BIN="${MJSTP_PREFIX}/bin/fzf"

link_fzf_assets() {
    ln -sf "${FZF_ROOT}/bin/fzf" "${TARGET_BIN}"
    if [ -x "${FZF_ROOT}/bin/fzf-tmux" ]; then
        ln -sf "${FZF_ROOT}/bin/fzf-tmux" "${MJSTP_PREFIX}/bin/fzf-tmux"
    fi
    if [ -d "${FZF_ROOT}/man/man1" ]; then
        cp -f "${FZF_ROOT}/man/man1/"*.1 "${MJSTP_PREFIX}/share/man/man1/" 2>/dev/null || true
    fi
    if [ -n "${MJSTP_PROFILE:-}" ] && ! line_in_file "fzf --bash" "${MJSTP_PROFILE}"; then
        # shellcheck disable=SC2016
        cat >> "${MJSTP_PROFILE}" <<'EOF'
if command -v fzf >/dev/null 2>&1; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(fzf --bash)" 2>/dev/null || true
    elif [ -n "${ZSH_VERSION:-}" ]; then
        source <(fzf --zsh) 2>/dev/null || true
    fi
fi
EOF
        log_info "Added fzf shell integration to profile."
    fi
}

TAG="$(github_latest_tag "junegunn/fzf")"
VERSION="${TAG#v}"

if [ -x "${FZF_ROOT}/bin/fzf" ] && [ -d "${FZF_ROOT}/.git" ]; then
    CURRENT_VER="$("${FZF_ROOT}/bin/fzf" --version | awk '{print $1}')"
    if [ "${CURRENT_VER}" = "${VERSION}" ]; then
        link_fzf_assets
        log_info "fzf ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating fzf (${CURRENT_VER:-unknown} -> ${VERSION})..."
    git -C "${FZF_ROOT}" pull --ff-only
    "${FZF_ROOT}/install" --bin --no-update-rc
    link_fzf_assets
    log_success "fzf ${VERSION} updated."
    exit 0
fi

log_info "Installing fzf ${VERSION} into ${FZF_ROOT}..."
rm -rf "${FZF_ROOT}"
git clone --depth 1 https://github.com/junegunn/fzf.git "${FZF_ROOT}"
"${FZF_ROOT}/install" --bin --no-update-rc
link_fzf_assets

log_success "fzf ${VERSION} installed to ${TARGET_BIN}."
