#!/usr/bin/env bash
set -eou pipefail


tmp_dir=$(mktemp -d)
cd "${tmp_dir}" || exit 1

curl -o installer.sh -L https://sh.rustup.rs
bash installer.sh

cd -

rm -rf "${tmp_dir}"
