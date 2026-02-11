#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

log_info "Installing Go..."

VERSION="1.22.0"
OS="linux"
ARCH="amd64"

# Check execution path first
if [ -d "$HOME/local/opt/go" ] && [ -x "$HOME/local/opt/go/bin/go" ]; then
    log_info "Go is already installed at $HOME/local/opt/go."
    exit 0
fi

tmp_dir=$(mktemp -d)
cd "${tmp_dir}" || exit 1

log_info "Downloading Go ${VERSION}..."
curl -LO "https://go.dev/dl/go${VERSION}.${OS}-${ARCH}.tar.gz"

ensure_dir "${HOME}/local/opt"
rm -rf "${HOME}/local/opt/go"
ensure_dir "${HOME}/local/bin"

if tar -C "${HOME}/local/opt" -xzf "go${VERSION}.${OS}-${ARCH}.tar.gz"; then
    ln -sf "${HOME}/local/opt/go/bin/go" "${HOME}/local/bin/go"
    ln -sf "${HOME}/local/opt/go/bin/gofmt" "${HOME}/local/bin/gofmt"
    log_success "Go installed."
else
    log_error "Failed to extract Go."
    exit 1
fi

rm -rf "${tmp_dir}"

if [ -n "${MJSTP_PROFILE}" ]; then
    if ! line_in_file "export PATH=\$HOME/local/opt/go/bin:\$PATH" "${MJSTP_PROFILE}"; then
        echo "export PATH=\$HOME/local/opt/go/bin:\$PATH" >> "${MJSTP_PROFILE}"
        log_info "Added Go path to profile."
    fi
fi
