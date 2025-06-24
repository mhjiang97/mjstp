#!/usr/bin/env bash
# shellcheck disable=SC1091
# Dependencies: cargo (rust)
set -eou pipefail


if [ -f "${HOME}"/.cargo/env ]; then
    source "${HOME}"/.cargo/env
else
    echo "Cargo environment not found. Please ensure Rust is installed."
    exit 1
fi

cargo install starship --locked

# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> "${HOME}"/.bashrc
eval "$(starship init bash)"
