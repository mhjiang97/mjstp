#!/usr/bin/env bash

set -e

# Get the absolute path of the workspace root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
SRC_DIR="${ROOT_DIR}/src/pkgs"
LIB_DIR="${ROOT_DIR}/lib"

# shellcheck disable=SC1091
source "${LIB_DIR}/utils.sh"

# Check system compat
if ! check_system; then
    log_error "System check failed. Aborting."
    exit 1
fi

# Map to store dependencies
declare -A DEPS

# Discover packages and dependencies
log_info "Discovering packages in ${SRC_DIR}..."
PACKAGES=()
while IFS= read -r -d '' pkg_path; do
    pkg_name=$(basename "$(dirname "${pkg_path}")")
    PACKAGES+=("${pkg_name}")

    # Extract Dependencies line
    # Format: # Dependencies: foo, bar
    dep_line=$(grep -i "^# Dependencies:" "${pkg_path}" | sed 's/# Dependencies://i' | tr -d ' ')

    if [[ -n "${dep_line}" ]]; then
        DEPS[${pkg_name}]="${dep_line}"
    fi
done < <(find "${SRC_DIR}" -name "install.sh" -print0)

# Sort dependencies (DFS)
declare -A VISITED
declare -A INSTALLING
ORDERED_PKGS=()

resolve_deps() {
    local pkg=$1

    if [[ "${VISITED[${pkg}]}" == "1" ]]; then
        return
    fi

    if [[ "${INSTALLING[${pkg}]}" == "1" ]]; then
        log_error "Circular dependency detected involving $pkg"
        exit 1
    fi

    INSTALLING[${pkg}]=1

    # Split dependencies by comma
    local pkg_deps=${DEPS[${pkg}]}
    if [[ -n "${pkg_deps}" ]]; then
        IFS=',' read -ra ADDR <<< "${pkg_deps}"
        for dep in "${ADDR[@]}"; do
            # Trim whitespace
            dep=$(echo "$dep" | xargs)

            # Check if dep exists in our package list
            local exists=0
            for p in "${PACKAGES[@]}"; do
                if [[ "$p" == "$dep" ]]; then
                    exists=1
                    break
                fi
            done

            if [[ "$exists" == "1" ]]; then
                resolve_deps "$dep"
            else
                log_warn "Package '$pkg' depends on '$dep' which was not found in src/pkgs/. Assuming pre-installed or typo."
            fi
        done
    fi

    VISITED[${pkg}]=1
    unset 'INSTALLING[${pkg}]'
    ORDERED_PKGS+=("${pkg}")
}

# Resolve for all packages (or specific ones if args provided)
TARGETS=("$@")
if [[ ${#TARGETS[@]} -eq 0 ]]; then
    TARGETS=("${PACKAGES[@]}")
fi

log_info "Resolving dependencies..."
for target in "${TARGETS[@]}"; do
    # Verify target exists
    found=0
    for p in "${PACKAGES[@]}"; do
        if [[ "$p" == "$target" ]]; then
            found=1
            break
        fi
    done

    if [[ "$found" == "1" ]]; then
        resolve_deps "${target}"
    else
        log_error "Package '$target' not found."
        exit 1
    fi
done

# Execute Installs
log_info "Installation order: ${ORDERED_PKGS[*]}"

# Create a common profile file if it doesn't exist
PROFILE_FILE="$HOME/.mjstp_profile"
# Use utils helpers correctly
if [[ ! -f "$PROFILE_FILE" ]]; then
    touch "$PROFILE_FILE"
    log_info "Created profile file at ${PROFILE_FILE}"

    if ! line_in_file "source \"${PROFILE_FILE}\"" "$HOME/.bashrc"; then
        {
            echo ""
            echo "# MJSTP Profile"
            echo "if [ -f \"${PROFILE_FILE}\" ]; then source \"${PROFILE_FILE}\"; fi"
        } >> "$HOME/.bashrc"
        log_success "Added sourcing of ${PROFILE_FILE} to .bashrc"
    fi
fi

# Export variables for child scripts
export MJSTP_ROOT="${ROOT_DIR}"
export MJSTP_PROFILE="${PROFILE_FILE}"
export LIB_DIR="${LIB_DIR}"
export PATH="${HOME}/local/bin:${HOME}/local/opt/bin:${PATH}" # Ensure path is set for execution

for pkg in "${ORDERED_PKGS[@]}"; do
    log_info "Installing ${pkg}..."

    install_script="${SRC_DIR}/${pkg}/install.sh"
    chmod +x "${install_script}"

    if "${install_script}"; then
        log_success "${pkg} installed successfully."
    else
        log_error "Failed to install ${pkg}."
        exit 1
    fi
done

log_success "All requested packages processed."
