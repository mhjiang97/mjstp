#!/usr/bin/env bash
# Dependencies:
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

MAMBA_BIN="${MJSTP_PREFIX}/bin/micromamba"
MAMBA_RC="${MAMBA_ROOT_PREFIX}/.mambarc"

ensure_mamba_config() {
    ensure_dir "${MAMBA_ROOT_PREFIX}"
    if [ ! -f "${MAMBA_RC}" ]; then
        cat > "${MAMBA_RC}" <<EOF
channels:
  - conda-forge
  - nodefaults
channel_priority: strict
EOF
    fi
    if [ -n "${MJSTP_PROFILE:-}" ] && ! line_in_file "shell hook --shell bash --root-prefix" "${MJSTP_PROFILE}"; then
        # shellcheck disable=SC2016
        cat >> "${MJSTP_PROFILE}" <<'EOF'
if [ -x "${MJSTP_PREFIX}/bin/micromamba" ]; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$("${MJSTP_PREFIX}/bin/micromamba" shell hook --shell bash --root-prefix "${MAMBA_ROOT_PREFIX}" 2>/dev/null)" || true
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$("${MJSTP_PREFIX}/bin/micromamba" shell hook --shell zsh --root-prefix "${MAMBA_ROOT_PREFIX}" 2>/dev/null)" || true
    fi
fi
EOF
        log_info "Added micromamba shell hook to profile."
    fi
}

TAG="$(github_latest_tag "mamba-org/micromamba-releases")"
# Tag format is e.g. "2.10.0-0"; binary --version outputs "2.10.0"
LATEST_VER="${TAG%-*}"

if [ -x "${MAMBA_BIN}" ]; then
    CURRENT_VER="$("${MAMBA_BIN}" --version | head -n 1 | tr -d '[:space:]')"
    if [ "${CURRENT_VER}" = "${LATEST_VER}" ]; then
        ensure_mamba_config
        log_info "Micromamba ${CURRENT_VER} is already at the latest version."
        exit 0
    fi
    log_info "Updating Micromamba (${CURRENT_VER:-unknown} -> ${LATEST_VER})..."
else
    log_info "Installing Micromamba ${LATEST_VER}..."
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT

URL="https://github.com/mamba-org/micromamba-releases/releases/download/${TAG}/micromamba-linux-64"
download "${URL}" "${tmp_dir}/micromamba"
chmod 755 "${tmp_dir}/micromamba"
mv "${tmp_dir}/micromamba" "${MAMBA_BIN}"

ensure_mamba_config
log_success "Micromamba ${LATEST_VER} installed to ${MAMBA_BIN}."
