#!/usr/bin/env bash
# Dependencies: conda (micromamba)
set -eou pipefail


conda install -c conda-forge condax

condax install -c conda-forge condax
