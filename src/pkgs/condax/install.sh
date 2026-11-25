#!/usr/bin/env bash
# Dependencies: micromamba
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

MAMBA_BIN="${MJSTP_PREFIX}/bin/micromamba"
CONDAX_BIN="${MJSTP_PREFIX}/bin/condax"

if [ ! -x "${MAMBA_BIN}" ]; then
    log_error "Could not find micromamba at ${MAMBA_BIN}."
    exit 1
fi

ensure_dir "${MJSTP_PREFIX}/etc"
ensure_dir "${MJSTP_PREFIX}/opt/condax"
cat > "${CONDAXRC}" <<EOF
prefix_path: ${MJSTP_PREFIX}/opt/condax
link_destination: ${MJSTP_PREFIX}/bin
conda_executable: ${MAMBA_BIN}
channels:
  - conda-forge
EOF

if [ -x "${MAMBA_ROOT_PREFIX}/bin/condax" ]; then
    log_info "Ensuring Condax is at the latest version..."
    "${MAMBA_BIN}" update -y -r "${MAMBA_ROOT_PREFIX}" -n base -c conda-forge condax
    ln -sf "${MAMBA_ROOT_PREFIX}/bin/condax" "${CONDAX_BIN}"
    log_success "Condax is up to date."
    exit 0
fi

log_info "Installing Condax..."
"${MAMBA_BIN}" install -y -r "${MAMBA_ROOT_PREFIX}" -n base -c conda-forge condax
ln -sf "${MAMBA_ROOT_PREFIX}/bin/condax" "${CONDAX_BIN}"
log_success "Condax installed to ${CONDAX_BIN}."
