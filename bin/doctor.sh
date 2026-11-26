#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
LIB_DIR="${ROOT_DIR}/lib"

# shellcheck disable=SC1091
source "${LIB_DIR}/utils.sh"
init_local_env

ISSUES=0

echo "=== MJSTP Doctor ==="
echo "Prefix:    ${MJSTP_PREFIX}"
echo "Cache dir: ${MJSTP_CACHE_DIR}"
echo "Data dir:  ${MJSTP_DATA_DIR}"
echo ""

# 1. Disk usage
log_info "Disk usage:"
for d in "${MJSTP_PREFIX}" "${MJSTP_CACHE_DIR}" "${MJSTP_DATA_DIR}"; do
    if [ -d "$d" ]; then
        printf "  %-45s %s\n" "$d" "$(du -sh "$d" 2>/dev/null | awk '{print $1}')"
    else
        printf "  %-45s (not created)\n" "$d"
    fi
done
echo ""

# 2. Broken symlinks in bin/
log_info "Checking for broken symlinks in ${MJSTP_PREFIX}/bin..."
broken_links=()
while IFS= read -r -d '' link; do
    broken_links+=("$link")
done < <(find "${MJSTP_PREFIX}/bin" -maxdepth 1 -type l ! -exec test -e {} \; -print0 2>/dev/null)

if [ ${#broken_links[@]} -eq 0 ]; then
    log_success "No broken symlinks found."
else
    log_warn "Found ${#broken_links[@]} broken symlink(s):"
    for l in "${broken_links[@]}"; do
        printf "  %s -> %s\n" "$l" "$(readlink "$l")"
    done
    ISSUES=$((ISSUES + 1))
fi
echo ""

# 3. Shared library check (ldd) for compiled C binaries
log_info "Checking shared libraries for compiled tools..."
ldd_missing=0
for bin_name in samtools bcftools htsfile tmux nvim; do
    bin_path="${MJSTP_PREFIX}/bin/${bin_name}"
    if [ -x "${bin_path}" ] && file "${bin_path}" 2>/dev/null | grep -q "dynamically linked"; then
        missing="$(ldd "${bin_path}" 2>/dev/null | grep "not found" || true)"
        if [ -n "${missing}" ]; then
            log_error "Missing shared libraries for ${bin_name}:"
            printf "%s\n" "${missing}"
            ldd_missing=1
            ISSUES=$((ISSUES + 1))
        fi
    fi
done
if [ "${ldd_missing}" -eq 0 ]; then
    log_success "All checked binaries have satisfied shared libraries."
fi
echo ""

# 4. Key tool versions
log_info "Key tool versions:"
check_ver() {
    local name="$1" cmd="$2"
    if command -v "$name" >/dev/null 2>&1; then
        local ver
        ver="$(eval "$cmd" 2>&1 | head -n 1 | tr -d '\r' || true)"
        printf "  %-14s %s\n" "$name" "${ver:-installed}"
    else
        printf "  %-14s (not installed)\n" "$name"
    fi
}

check_ver micromamba "micromamba --version"
check_ver condax     "condax --version"
check_ver uv         "uv --version"
check_ver pipx       "pipx --version"
check_ver git        "git --version"
check_ver tmux       "tmux -V"
check_ver nvim       "nvim --version"
check_ver samtools   "samtools --version"
check_ver bcftools   "bcftools --version"
check_ver nextflow   "nextflow -version 2>&1 | grep -m1 version"
check_ver snakemake  "snakemake --version"
check_ver R          "R --version"
check_ver rg         "rg --version"
check_ver fd         "fd --version"
echo ""

if [ "${ISSUES}" -eq 0 ]; then
    log_success "Doctor check passed with no issues."
else
    log_warn "Doctor found ${ISSUES} issue(s) to review."
fi
