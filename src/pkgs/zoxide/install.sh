#!/usr/bin/env bash
# Dependencies:
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

TARGET_BIN="${MJSTP_PREFIX}/bin/zoxide"

ensure_zoxide_profile() {
    if [ -n "${MJSTP_PROFILE:-}" ] && ! line_in_file "zoxide init" "${MJSTP_PROFILE}"; then
        # shellcheck disable=SC2016
        cat >> "${MJSTP_PROFILE}" <<'EOF'
if command -v zoxide >/dev/null 2>&1; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(zoxide init bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(zoxide init zsh)"
    fi
fi
EOF
        log_info "Added zoxide init to profile."
    fi
}

TAG="$(github_latest_tag "ajeetdsouza/zoxide")"
VERSION="${TAG#v}"

if [ -x "${TARGET_BIN}" ]; then
    CURRENT_VER="$("${TARGET_BIN}" --version | awk '{print $2}')"
    if [ "${CURRENT_VER}" = "${VERSION}" ]; then
        ensure_zoxide_profile
        log_info "zoxide ${VERSION} is already at the latest version."
        exit 0
    fi
    log_info "Updating zoxide (${CURRENT_VER:-unknown} -> ${VERSION})..."
else
    log_info "Installing zoxide ${VERSION}..."
fi

TARBALL="zoxide-${VERSION}-x86_64-unknown-linux-musl.tar.gz"
URL="https://github.com/ajeetdsouza/zoxide/releases/download/${TAG}/${TARBALL}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

download "${URL}" "${TARBALL}"
tar -xzf "${TARBALL}"

install -m 755 zoxide "${TARGET_BIN}"
if [ -d "man/man1" ]; then
    cp -f man/man1/* "${MJSTP_PREFIX}/share/man/man1/"
fi

ensure_zoxide_profile
log_success "zoxide ${VERSION} installed to ${TARGET_BIN}."
