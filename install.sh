#!/bin/bash

# Standard Error Handling
set -e
set -u
set -o pipefail

# Author: Benjamin Pequet
# Purpose: Installs the sync-ide-rules.sh script for global use.
# Project: https://github.com/pequet/ide-rules-synchronizer
# Refer to main project for detailed docs.

# --- Source Utilities ---
# Resolve the true directory of this install script to find project files
INSTALL_SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${INSTALL_SCRIPT_DIR}/scripts/utils/logging_utils.sh"
source "${INSTALL_SCRIPT_DIR}/scripts/utils/messaging_utils.sh"

# Set a log file path for the installer
LOG_FILE_PATH="${INSTALL_SCRIPT_DIR}/logs/install.log"

# --- Main Installation Logic ---
main() {
    ensure_log_directory
    print_header "IDE Rules Synchronizer Installer"

    # --- Define Paths ---
    local SOURCE_SCRIPT_NAME="sync-ide-rules.sh"
    local DEST_SCRIPT_NAME="core-sync-ide-rules.sh"
    local DEST_DIR="/usr/local/bin"
    local SOURCE_SCRIPT_PATH="${INSTALL_SCRIPT_DIR}/scripts/${SOURCE_SCRIPT_NAME}"
    local DEST_PATH="${DEST_DIR}/${DEST_SCRIPT_NAME}"

    # --- Step 1: Verify source file ---
    print_step "Step 1: Verifying required script"
    if [ ! -f "$SOURCE_SCRIPT_PATH" ]; then
        print_error "Source script not found at ${SOURCE_SCRIPT_PATH}"
        exit 1
    fi
    print_success "Source script found."

    # --- Step 2: Verify destination directory ---
    print_step "Step 2: Verifying destination directory"
    if [ ! -d "$DEST_DIR" ]; then
        print_error "Destination directory ${DEST_DIR} not found."
        print_info "Please ensure standard Homebrew/macOS paths are configured."
        exit 1
    fi
    print_success "Destination directory found."

    # --- Step 3: Install the main script ---
    print_step "Step 3: Installing the main script"
    print_info "This will make the '${DEST_SCRIPT_NAME}' command available globally."
    print_info "You may be prompted for your administrator password."

    if ! sudo ln -sf "$SOURCE_SCRIPT_PATH" "$DEST_PATH"; then
        print_error "Failed to create symbolic link. Please check permissions for ${DEST_DIR}."
        exit 1
    fi

    print_separator
    print_completed "Installation Complete"
    print_info "The '${DEST_SCRIPT_NAME}' command is now installed."
    print_info "You can now run it from any directory."
    print_info "To use, type 'core-' and press Tab to autocomplete."
    print_footer
}

# --- Script Entrypoint ---
main "$@" 