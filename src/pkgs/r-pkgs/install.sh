#!/usr/bin/env bash
# Dependencies: r
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${LIB_DIR:-${SCRIPT_DIR}/../../../lib}/utils.sh"
init_local_env

RSCRIPT_BIN="${MJSTP_PREFIX}/bin/Rscript"
MANIFEST="${SCRIPT_DIR}/packages.txt"

if [ ! -x "${RSCRIPT_BIN}" ]; then
    log_error "Rscript not found at ${RSCRIPT_BIN}."
    exit 1
fi

if [ ! -f "${MANIFEST}" ]; then
    log_error "R package manifest not found at ${MANIFEST}."
    exit 1
fi

pkgs=()
while IFS= read -r line || [ -n "${line}" ]; do
    line="${line%%#*}"
    pkg="$(echo "${line}" | xargs)"
    [ -n "${pkg}" ] && pkgs+=("${pkg}")
done < "${MANIFEST}"

if [ ${#pkgs[@]} -eq 0 ]; then
    log_info "No R packages listed in ${MANIFEST}."
    exit 0
fi

log_info "Ensuring R packages are installed (${pkgs[*]})..."
"${RSCRIPT_BIN}" -e '
args <- commandArgs(trailingOnly = TRUE)
repos <- "https://cloud.r-project.org"
ncpus <- max(1L, parallel::detectCores(logical = TRUE) %||% 1L)
installed <- rownames(installed.packages())
missing <- setdiff(args, installed)
if (length(missing) > 0) {
    install.packages(missing, repos = repos, Ncpus = ncpus)
}
update.packages(oldPkgs = intersect(args, installed), repos = repos, ask = FALSE, Ncpus = ncpus)
' "${pkgs[@]}"

log_success "All R manifest packages processed."
