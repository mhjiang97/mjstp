#!/usr/bin/env bash
# Dependencies: condax
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

CONDAX_BIN="${MJSTP_PREFIX}/bin/condax"
PIPX_BIN="${MJSTP_PREFIX}/bin/pipx"

if [ ! -x "${CONDAX_BIN}" ]; then
    log_error "Condax not found at ${CONDAX_BIN}."
    exit 1
fi

ensure_pipx_profile() {
    if [ -n "${MJSTP_PROFILE:-}" ] && ! line_in_file "register-python-argcomplete pipx" "${MJSTP_PROFILE}"; then
        # shellcheck disable=SC2016
        cat >> "${MJSTP_PROFILE}" <<'EOF'
if command -v register-python-argcomplete >/dev/null 2>&1 && command -v pipx >/dev/null 2>&1; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(register-python-argcomplete pipx)"
    fi
fi
EOF
        log_info "Added pipx completion to profile."
    fi
}

if [ -x "${PIPX_BIN}" ] && [ -d "${MJSTP_PREFIX}/opt/condax/pipx" ]; then
    log_info "Ensuring Pipx is at the latest version..."
    "${CONDAX_BIN}" update pipx
    "${PIPX_BIN}" upgrade argcomplete || true
    ensure_pipx_profile
    log_success "Pipx is up to date."
    exit 0
fi

log_info "Installing Pipx via Condax..."
"${CONDAX_BIN}" install --force -c conda-forge pipx

if [ ! -x "${PIPX_BIN}" ]; then
    log_error "Pipx installed via condax but not found at ${PIPX_BIN}."
    exit 1
fi

log_info "Installing argcomplete via pipx..."
"${PIPX_BIN}" install --force argcomplete || true
ensure_pipx_profile

log_success "Pipx installed to ${PIPX_BIN}."
