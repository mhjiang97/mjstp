#!/usr/bin/env bash
# Dependencies:
set -e

# shellcheck disable=SC1091
[ -n "${LIB_DIR}" ] && source "${LIB_DIR}/utils.sh"

# Ensure local directories exist
ensure_dir "${HOME}/local/bin"
ensure_dir "${HOME}/local/opt"

# Check if micromamba binary exists (standard install location or our custom one if we had one)
if [ -x "${HOME}/local/bin/micromamba" ] || [ -d "${HOME}/local/opt/micromamba" ]; then
    log_info "Micromamba appears to be installed."
    exit 0
fi

log_info "Installing Micromamba..."

tmp_dir=$(mktemp -d)
cd "${tmp_dir}" || exit 1

# Run installer non-interactively
# INIT_YES=yes runs 'micromamba shell init'
# CONDA_FORGE_YES=yes adds conda-forge
export INIT_YES=yes
export CONDA_FORGE_YES=yes
export PREFIX_LOCATION="${HOME}/local/opt/micromamba"
export BIN_FOLDER="${HOME}/local/bin"

curl -Ls https://micro.mamba.pm/install.sh | bash

cd -
rm -rf "${tmp_dir}"

log_success "Micromamba installed."
