#!/usr/bin/env bash

set -e

# Get the absolute path of the workspace root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
SRC_DIR="${ROOT_DIR}/src/pkgs"
LIB_DIR="${ROOT_DIR}/lib"

# shellcheck disable=SC1091
source "${LIB_DIR}/utils.sh"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [PACKAGE...]

Install or upgrade user-space packages to their latest versions in \${MJSTP_PREFIX:-~/local} (no sudo required).

Options:
  -u, --update         Alias for default behavior (always installs/upgrades to latest)
  -e, --exclude PKG    Exclude package (and any packages depending on it)
  -n, --dry-run        Preview resolved dependency install order without installing
  -k, --keep-going     Continue installing remaining packages if one fails
  -l, --log            Tee install output to ~/.mjstp_install.log
  -h, --help           Show this help message
EOF
}

# Parse arguments early (before system check so --dry-run can skip it)
TARGETS=()
EXCLUDES=()
export MJSTP_UPDATE=""
DRY_RUN=""
KEEP_GOING=""
LOG_FILE=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -u|--update)
            export MJSTP_UPDATE="true"
            shift
            ;;
        -e|--exclude)
            if [[ $# -lt 2 || -z "$2" ]]; then
                log_error "--exclude requires a package name."
                exit 1
            fi
            EXCLUDES+=("$2")
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -k|--keep-going)
            KEEP_GOING="true"
            shift
            ;;
        -l|--log)
            LOG_FILE="${HOME}/.mjstp_install.log"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            usage >&2
            exit 1
            ;;
        *)
            TARGETS+=("$1")
            shift
            ;;
    esac
done

# Set up logging to file if requested
if [[ -n "${LOG_FILE}" ]]; then
    log_info "Logging output to ${LOG_FILE}"
    exec > >(tee -a "${LOG_FILE}") 2>&1
    echo "--- MJSTP install started at $(date) ---" >> "${LOG_FILE}"
fi

# Dependency and traversal state. Bash 3.2 (macOS /bin/bash) has no
# associative arrays, so entries live in variables named <map>__<sanitized_key>.
_map_key() {
    printf '%s__%s' "$1" "${2//[^a-zA-Z0-9_]/_}"
}

map_set() {
    local _var
    _var="$(_map_key "$1" "$2")"
    printf -v "${_var}" '%s' "$3"
}

map_get() {
    local _var
    _var="$(_map_key "$1" "$2")"
    printf '%s' "${!_var:-}"
}

map_unset() {
    local _var
    _var="$(_map_key "$1" "$2")"
    unset "${_var}"
}

is_excluded() {
    local needle="$1" ex
    for ex in "${EXCLUDES[@]}"; do
        if [[ "$needle" == "$ex" ]]; then
            return 0
        fi
    done
    return 1
}

pkg_exists() {
    local needle="$1" p
    for p in "${PACKAGES[@]}"; do
        if [[ "$p" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

# Discover packages and dependencies in deterministic alphabetical order
log_info "Discovering packages in ${SRC_DIR}..."
RAW_PKGS=()
while IFS= read -r -d '' pkg_path; do
    pkg_name=$(basename "$(dirname "${pkg_path}")")
    RAW_PKGS+=("${pkg_name}")

    # Format: # Dependencies: foo, bar
    dep_line=$(grep -i -m1 "^# Dependencies:" "${pkg_path}" | sed 's/# Dependencies://i' | tr -d ' ' || true)
    if [[ -n "${dep_line}" ]]; then
        map_set DEPS "${pkg_name}" "${dep_line}"
    fi
done < <(find "${SRC_DIR}" -mindepth 2 -maxdepth 2 -name "install.sh" -print0)

PACKAGES=()
while IFS= read -r p; do
    [[ -n "$p" ]] && PACKAGES+=("$p")
done < <(printf '%s\n' "${RAW_PKGS[@]}" | LC_ALL=C sort)

if [[ ${#EXCLUDES[@]} -gt 0 ]]; then
    log_info "Excluding: ${EXCLUDES[*]}"
fi

# Sort dependencies (DFS). Returns 1 if pkg or any dependency is excluded.
ORDERED_PKGS=()

resolve_deps() {
    local pkg="$1"

    if is_excluded "${pkg}"; then
        return 1
    fi

    if [[ "$(map_get SKIPPED "${pkg}")" == "1" ]]; then
        return 1
    fi

    if [[ "$(map_get VISITED "${pkg}")" == "1" ]]; then
        return 0
    fi

    if [[ "$(map_get INSTALLING "${pkg}")" == "1" ]]; then
        log_error "Circular dependency detected involving $pkg"
        exit 1
    fi

    map_set INSTALLING "${pkg}" 1

    local pkg_deps dep
    pkg_deps=$(map_get DEPS "${pkg}")
    if [[ -n "${pkg_deps}" ]]; then
        IFS=',' read -ra ADDR <<< "${pkg_deps}"
        for dep in "${ADDR[@]}"; do
            dep=$(echo "$dep" | xargs)
            [[ -z "$dep" ]] && continue

            if is_excluded "$dep"; then
                log_warn "Skipping '${pkg}' because dependency '${dep}' is excluded."
                map_unset INSTALLING "${pkg}"
                map_set SKIPPED "${pkg}" 1
                return 1
            fi

            if pkg_exists "$dep"; then
                if ! resolve_deps "$dep"; then
                    log_warn "Skipping '${pkg}' because dependency '${dep}' was skipped."
                    map_unset INSTALLING "${pkg}"
                    map_set SKIPPED "${pkg}" 1
                    return 1
                fi
            else
                log_warn "Package '$pkg' depends on '$dep' which was not found in src/pkgs/. Assuming pre-installed."
            fi
        done
    fi

    map_set VISITED "${pkg}" 1
    map_unset INSTALLING "${pkg}"
    ORDERED_PKGS+=("${pkg}")
    return 0
}

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    TARGETS=("${PACKAGES[@]}")
fi

log_info "Resolving dependencies..."
for target in "${TARGETS[@]}"; do
    if ! pkg_exists "$target"; then
        log_error "Package '$target' not found."
        exit 1
    fi
    resolve_deps "${target}" || true
done

log_info "Installation order: ${ORDERED_PKGS[*]}"

# Dry-run mode: just print the order and exit
if [[ -n "${DRY_RUN}" ]]; then
    log_info "Dry-run mode — no packages will be installed."
    echo ""
    echo "Resolved install order (${#ORDERED_PKGS[@]} packages):"
    for i in "${!ORDERED_PKGS[@]}"; do
        pkg="${ORDERED_PKGS[$i]}"
        deps=$(map_get DEPS "${pkg}")
        deps="${deps:-none}"
        printf "  %2d. %-15s (deps: %s)\n" "$((i+1))" "$pkg" "$deps"
    done
    exit 0
fi

# Check system compatibility against the packages that will actually run.
install_scripts=()
for pkg in "${ORDERED_PKGS[@]}"; do
    install_scripts+=("${SRC_DIR}/${pkg}/install.sh")
done
if [[ ${#install_scripts[@]} -gt 0 ]] && ! check_system "${install_scripts[@]}"; then
    log_error "System check failed. Aborting."
    exit 1
fi

# Initialize ~/local FHS structure and environment
init_local_env

# Create/update common profile file
PROFILE_FILE="${HOME}/.mjstp_profile"
if [[ ! -f "$PROFILE_FILE" ]]; then
    touch "$PROFILE_FILE"
    log_info "Created profile file at ${PROFILE_FILE}"
fi

ensure_profile_line() {
    local marker="$1" line="$2"
    if ! line_in_file "$marker" "${PROFILE_FILE}"; then
        printf '%s\n' "$line" >> "${PROFILE_FILE}"
    fi
}

# shellcheck disable=SC2016
{
    ensure_profile_line 'export MJSTP_PREFIX=' 'export MJSTP_PREFIX="${MJSTP_PREFIX:-${HOME}/local}"'
    ensure_profile_line 'export MJSTP_CACHE_DIR=' 'export MJSTP_CACHE_DIR="${MJSTP_CACHE_DIR:-${MJSTP_PREFIX}/var/cache}"'
    ensure_profile_line 'export MJSTP_DATA_DIR=' 'export MJSTP_DATA_DIR="${MJSTP_DATA_DIR:-${MJSTP_PREFIX}/var/data}"'
    ensure_profile_line 'MJSTP_PREFIX}/bin' 'export PATH="${MJSTP_PREFIX}/bin:${MJSTP_PREFIX}/opt/go/bin:${MJSTP_PREFIX}/opt/cargo/bin:${PATH}"'
    ensure_profile_line 'export MANPATH=' 'export MANPATH="${MJSTP_PREFIX}/share/man:${MANPATH:-}"'
    ensure_profile_line 'export CPPFLAGS=' 'export CPPFLAGS="-I${MJSTP_PREFIX}/include -I${MJSTP_PREFIX}/include/ncursesw"'
    ensure_profile_line 'export CFLAGS=' 'export CFLAGS="-O2 -I${MJSTP_PREFIX}/include -I${MJSTP_PREFIX}/include/ncursesw"'
    ensure_profile_line 'export LDFLAGS=' 'export LDFLAGS="-L${MJSTP_PREFIX}/lib64 -L${MJSTP_PREFIX}/lib -Wl,-rpath,${MJSTP_PREFIX}/lib64 -Wl,-rpath,${MJSTP_PREFIX}/lib -Wl,-rpath-link,${MJSTP_PREFIX}/lib64 -Wl,-rpath-link,${MJSTP_PREFIX}/lib"'
    ensure_profile_line 'export PKG_CONFIG_PATH=' 'export PKG_CONFIG_PATH="${MJSTP_PREFIX}/lib/pkgconfig:${MJSTP_PREFIX}/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"'
    ensure_profile_line 'export MAMBA_ROOT_PREFIX=' 'export MAMBA_ROOT_PREFIX="${MJSTP_PREFIX}/opt/micromamba"'
    ensure_profile_line 'export CONDAXRC=' 'export CONDAXRC="${MJSTP_PREFIX}/etc/condaxrc"'
    ensure_profile_line 'export PIPX_HOME=' 'export PIPX_HOME="${MJSTP_PREFIX}/opt/pipx"'
    ensure_profile_line 'export PIPX_BIN_DIR=' 'export PIPX_BIN_DIR="${MJSTP_PREFIX}/bin"'
    ensure_profile_line 'export PIPX_MAN_DIR=' 'export PIPX_MAN_DIR="${MJSTP_PREFIX}/share/man"'
    ensure_profile_line 'export GOPATH=' 'export GOPATH="${MJSTP_PREFIX}/opt/gopath"'
    ensure_profile_line 'export GOBIN=' 'export GOBIN="${MJSTP_PREFIX}/bin"'
    ensure_profile_line 'export CARGO_HOME=' 'export CARGO_HOME="${MJSTP_PREFIX}/opt/cargo"'
    ensure_profile_line 'export RUSTUP_HOME=' 'export RUSTUP_HOME="${MJSTP_PREFIX}/opt/rustup"'
    ensure_profile_line 'export APPTAINER_CACHEDIR=' 'export APPTAINER_CACHEDIR="${MJSTP_CACHE_DIR}/apptainer"'
    ensure_profile_line 'export NXF_SINGULARITY_CACHEDIR=' 'export NXF_SINGULARITY_CACHEDIR="${MJSTP_CACHE_DIR}/singularity"'
    ensure_profile_line 'export CONDA_PKGS_DIRS=' 'export CONDA_PKGS_DIRS="${MJSTP_CACHE_DIR}/conda/pkgs"'
    ensure_profile_line 'export UV_CACHE_DIR=' 'export UV_CACHE_DIR="${MJSTP_CACHE_DIR}/uv"'
    ensure_profile_line 'export PIP_CACHE_DIR=' 'export PIP_CACHE_DIR="${MJSTP_CACHE_DIR}/pip"'
    ensure_profile_line 'export NXF_HOME=' 'export NXF_HOME="${MJSTP_DATA_DIR}/nextflow"'
}

# Ensure ~/.bashrc exists on minimal Linux servers and source ~/.mjstp_profile
# across interactive and SSH login shells.
[[ -f "${HOME}/.bashrc" ]] || touch "${HOME}/.bashrc"

source_snippet="if [ -f \"${PROFILE_FILE}\" ]; then . \"${PROFILE_FILE}\"; fi"
rc_targets=("${HOME}/.bashrc")
if [[ -f "${HOME}/.bash_profile" ]]; then
    rc_targets+=("${HOME}/.bash_profile")
elif [[ -f "${HOME}/.profile" ]]; then
    rc_targets+=("${HOME}/.profile")
else
    touch "${HOME}/.profile"
    rc_targets+=("${HOME}/.profile")
fi
[[ -f "${HOME}/.zshrc" ]] && rc_targets+=("${HOME}/.zshrc")

for rc_file in "${rc_targets[@]}"; do
    if ! line_in_file "${PROFILE_FILE}" "$rc_file"; then
        {
            echo ""
            echo "# MJSTP Profile"
            echo "${source_snippet}"
        } >> "$rc_file"
        log_success "Added sourcing of ${PROFILE_FILE} to $(basename "$rc_file")"
    fi
done

# Export variables for child scripts
export MJSTP_ROOT="${ROOT_DIR}"
export MJSTP_PROFILE="${PROFILE_FILE}"
export LIB_DIR="${LIB_DIR}"

SUCCEEDED_PKGS=()
FAILED_PKGS=()

for pkg in "${ORDERED_PKGS[@]}"; do
    log_info "Installing ${pkg}..."

    install_script="${SRC_DIR}/${pkg}/install.sh"

    if "${install_script}"; then
        log_success "${pkg} installed successfully."
        SUCCEEDED_PKGS+=("${pkg}")
    else
        log_error "Failed to install ${pkg}."
        FAILED_PKGS+=("${pkg}")
        if [[ -z "${KEEP_GOING}" ]]; then
            exit 1
        fi
    fi
done

echo ""
log_info "=== Installation Summary ==="
log_success "Succeeded (${#SUCCEEDED_PKGS[@]}): ${SUCCEEDED_PKGS[*]:-none}"
if [[ ${#FAILED_PKGS[@]} -gt 0 ]]; then
    log_error "Failed (${#FAILED_PKGS[@]}): ${FAILED_PKGS[*]}"
    exit 1
fi
log_success "All requested packages processed."
