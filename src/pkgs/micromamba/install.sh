#!/usr/bin/env bash
# shellcheck disable=SC1091
set -eou pipefail


tmp_dir=$(mktemp -d)
cd "${tmp_dir}" || exit 1

curl -o installer.sh -L https://micro.mamba.pm/install.sh
bash installer.sh

cd -

rm -rf "${tmp_dir}"

source "${HOME}"/.bashrc
micromamba install conda
