#!/usr/bin/env bash
# Dependencies:
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

link_rust_bins() {
    local bin
    for bin in "${CARGO_HOME}/bin/"*; do
        [ -x "${bin}" ] || continue
        ln -sf "${bin}" "${MJSTP_PREFIX}/bin/$(basename "${bin}")"
    done
}

if [ -x "${CARGO_HOME}/bin/cargo" ] && [ -x "${CARGO_HOME}/bin/rustup" ]; then
    log_info "Ensuring Rust stable toolchain is at the latest version..."
    "${CARGO_HOME}/bin/rustup" update stable
    link_rust_bins
    log_success "Rust is up to date."
    exit 0
fi

log_info "Installing latest stable Rust into ${MJSTP_PREFIX}/opt/{rustup,cargo}..."

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT

curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs -o "${tmp_dir}/rustup-init.sh"
bash "${tmp_dir}/rustup-init.sh" -y --no-modify-path --default-toolchain stable

link_rust_bins
log_success "Rust installed to ${CARGO_HOME}."
