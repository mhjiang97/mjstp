#!/usr/bin/env bash
# Dependencies: go
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Duf..."

if [ -x "$HOME/local/bin/duf" ]; then
    if [ -n "$MJSTP_UPDATE" ]; then
        log_info "Updating Duf..."
        # fall through to build
    else
        log_info "Duf is already installed at $HOME/local/bin/duf."
        exit 0
    fi
fi

# Ensure Go is available
export PATH="${HOME}/local/opt/go/bin:${PATH}"
if ! command -v go &> /dev/null; then
    log_warn "Go not found in path, trying to source profile."
    # shellcheck disable=SC1090
    [ -f "${MJSTP_PROFILE}" ] && source "${MJSTP_PROFILE}"
fi

if ! command -v go &> /dev/null; then
    log_error "Go is required to build duf."
    exit 1
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Cloning and building Duf..."
git clone https://github.com/muesli/duf.git
cd duf || exit 1
go build

ensure_dir "$HOME/local/bin"
mv duf "$HOME/local/bin/duf"
log_success "Duf installed/updated."
