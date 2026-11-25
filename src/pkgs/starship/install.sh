#!/usr/bin/env bash
# Dependencies: rust
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

CARGO_BIN="${CARGO_HOME}/bin/cargo"
TARGET_BIN="${MJSTP_PREFIX}/bin/starship"

ensure_starship_profile() {
    if [ -n "${MJSTP_PROFILE:-}" ] && ! line_in_file "starship init" "${MJSTP_PROFILE}"; then
        # shellcheck disable=SC2016
        cat >> "${MJSTP_PROFILE}" <<'EOF'
if command -v starship >/dev/null 2>&1; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(starship init bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(starship init zsh)"
    fi
fi
EOF
        log_info "Added Starship init to profile."
    fi
}

if [ ! -x "${CARGO_BIN}" ]; then
    log_error "Cargo not found at ${CARGO_BIN}."
    exit 1
fi

log_info "Ensuring Starship is at the latest version in ${MJSTP_PREFIX}/bin..."
"${CARGO_BIN}" install starship --locked --root "${MJSTP_PREFIX}"
ensure_starship_profile
log_success "Starship is at the latest version in ${TARGET_BIN}."
