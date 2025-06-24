#!/usr/bin/env bash
# Dependencies: conda (micromamba) condax
set -eou pipefail


condax install -c conda-forge pipx

pipx install argcomplete

# shellcheck disable=SC2016
echo 'eval "$(register-python-argcomplete pipx)"' >> "${HOME}"/.bashrc
