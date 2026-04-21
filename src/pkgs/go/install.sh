#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

VERSION="1.24.2"
OS="linux"
ARCH="amd64"
TARBALL="go${VERSION}.${OS}-${ARCH}.tar.gz"

if [ -d "$HOME/local/opt/go" ] && [ -x "$HOME/local/opt/go/bin/go" ]; then
    if [ -n "${MJSTP_UPDATE}" ]; then
        log_info "Updating Go to ${VERSION}..."
        rm -rf "${HOME}/local/opt/go"
    else
        log_info "Go is already installed at $HOME/local/opt/go."
        exit 0
    fi
fi

log_info "Installing Go ${VERSION}..."

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
cd "${tmp_dir}" || exit 1

log_info "Downloading Go ${VERSION}..."
download "https://go.dev/dl/${TARBALL}"

ensure_dir "${HOME}/local/opt"
rm -rf "${HOME}/local/opt/go"
ensure_dir "${HOME}/local/bin"

if tar -C "${HOME}/local/opt" -xzf "${TARBALL}"; then
    ln -sf "${HOME}/local/opt/go/bin/go" "${HOME}/local/bin/go"
    ln -sf "${HOME}/local/opt/go/bin/gofmt" "${HOME}/local/bin/gofmt"
    log_success "Go ${VERSION} installed."
else
    log_error "Failed to extract Go."
    exit 1
fi

if [ -n "${MJSTP_PROFILE}" ]; then
    if ! line_in_file "export PATH=\$HOME/local/opt/go/bin:\$PATH" "${MJSTP_PROFILE}"; then
        echo "export PATH=\$HOME/local/opt/go/bin:\$PATH" >> "${MJSTP_PROFILE}"
        log_info "Added Go path to profile."
    fi
fi
