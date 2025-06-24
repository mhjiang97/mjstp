#!/usr/bin/env bash
# shellcheck disable=SC1091
set -eou pipefail


tmp_dir=$(mktemp -d)
cd "${tmp_dir}" || exit 1

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar -C "${HOME}"/local/opt -xzf nvim-linux-x86_64.tar.gz

cd -

rm -rf "${tmp_dir}"

ln -s "${HOME}"/local/opt/nvim-linux-x86_64/bin/nvim "${HOME}"/local/bin/nvim
