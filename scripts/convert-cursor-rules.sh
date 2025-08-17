#!/bin/bash

# Standard Error Handling
set -e
set -u
set -o pipefail

# --- Logging Toggle (disabled until log dir ensured) ---
LOGGING_ENABLED=0

# --- Utility Scripts ---
# Source utility functions
# shellcheck source=scripts/utils/logging_utils.sh
source "$(dirname "$0")/utils/logging_utils.sh"
# shellcheck source=scripts/utils/messaging_utils.sh
source "$(dirname "$0")/utils/messaging_utils.sh"

# █   █  Cursor Rules to Instructions: Rule Conversion Tool
#  █ █   Version: 1.0.0
#  █ █   Author: Benjamin Pequet
# █   █  GitHub: https://github.com/pequet/cursor-rules-to-instructions/
#
# Purpose:
#   Converts Cursor IDE rules (.mdc files) to GitHub Copilot instructions (.instructions.md files).
#   Facilitates seamless migration between AI coding assistants while maintaining all rule functionality.
#
# Usage:
#   ./convert-cursor-rules.sh [source_dir] [dest_dir]
#   source_dir: Directory containing .mdc files (default: current directory)
#   dest_dir: Directory for .instructions.md files (default: .github/instructions)
#
# Dependencies:
#   - Bash 4.0+
#   - Standard Unix utilities (find, sed, awk, grep)
#   - scripts/utils/messaging_utils.sh
#   - scripts/utils/logging_utils.sh
#
# Changelog:
#   1.0.0 - 2025-08-17 - Initial release
#
# Support the Project:
#   - Buy Me a Coffee: https://buymeacoffee.com/pequet
#   - GitHub Sponsors: https://github.com/sponsors/pequet

# --- Configuration ---
# Processing statistics
declare -i FILES_PROCESSED=0
declare -i FILES_CONVERTED=0
declare -i FILES_SKIPPED=0
declare -i ERRORS_COUNT=0

# --- Logging Configuration ---
# The script name can be used to generate a log file name
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE_PATH="scripts/logs/${SCRIPT_NAME}.log"

# --- Function Definitions ---

# *
# * Utility and Setup Functions
# *

validate_dependencies() {
    local required_commands=("find" "sed" "awk" "grep")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            print_error "Required command not found: ${cmd}"
            exit 1
        fi
    done
}

show_usage() {
    echo "Usage: $0 <project_root_path>"
    echo ""
    echo "Convert Cursor .mdc rules to GitHub Copilot .instructions.md format"
    echo ""
    echo "Arguments:"
    echo "  project_root_path    Path to the project root containing .cursor/rules/ directory"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/my/project"
    echo "  $0 ."
}

# *
# * File Processing Functions
# *

# Convert glob patterns from Cursor to GitHub format
convert_glob() {
    local cursor_glob="$1"
    
    # Handle empty globs or "[]" (empty array)
    if [[ -z "$cursor_glob" || "$cursor_glob" == "[]" ]]; then
        echo "[]"
        return
    fi
    
    # Special case: if it's already the correct format, return as-is
    if [[ "$cursor_glob" == "*,**/*" ]]; then
        echo "*,**/*"
        return
    fi
    
    # Check if it contains commas (multiple patterns)
    if [[ "$cursor_glob" == *","* ]]; then
        # Split by comma, convert each pattern, and rejoin
        local converted_patterns=()
        IFS=',' read -ra patterns <<< "$cursor_glob"
        for pattern in "${patterns[@]}"; do
            # Trim whitespace
            pattern="${pattern#"${pattern%%[![:space:]]*}"}"  # Remove leading whitespace
            pattern="${pattern%"${pattern##*[![:space:]]}"}"  # Remove trailing whitespace
            # Convert individual pattern
            local converted=$(convert_single_glob "$pattern")
            converted_patterns+=("$converted")
        done
        # Join with commas
        local result
        printf -v result '%s,' "${converted_patterns[@]}"
        echo "${result%,}"
    else
        # Single pattern
        convert_single_glob "$cursor_glob"
    fi
}

# Convert a single glob pattern
convert_single_glob() {
    local pattern="$1"
    
    case "$pattern" in
        *.cursor/rules/**/*.mdc)
            echo ".github/instructions/**/*.instructions.md"
            ;;
        .cursor/rules/*.md)
            echo ".github/instructions/*.instructions.md"
            ;;
        "*")
            echo "*,**/*"
            ;;
        "*,**/*")
            echo "*,**/*"
            ;;
        "**/*")
            echo "*,**/*"  # Convert "**/*" to "*,**/*"
            ;;
        *.mdc)
            echo "${pattern%.mdc}.instructions.md"
            ;;
        *)
            # Standard glob patterns are fine, keep as-is
            echo "$pattern"
            ;;
    esac
}

process_frontmatter() {
    local input_file="$1"
    local temp_file
    temp_file=$(mktemp)
    
    # Extract frontmatter info first
    local description=""
    local apply_to="*,**/*"  # Default value
    local always_apply=false
    local glob_pattern=""
    
    # Check if file has frontmatter
    if head -1 "$input_file" | grep -q "^---$"; then
        # Extract description and globs from frontmatter
        local in_frontmatter=false
        while IFS= read -r line; do
            if [[ "$line" == "---" ]]; then
                if [[ "$in_frontmatter" == false ]]; then
                    in_frontmatter=true
                    continue
                else
                    # End of frontmatter
                    break
                fi
            elif [[ "$in_frontmatter" == true ]]; then
                if [[ "$line" =~ ^description:[:space:]*(.*)$ ]]; then
                    description="${BASH_REMATCH[1]}"
                elif [[ "$line" =~ ^globs:[:space:]*(.*)$ ]]; then
                    local glob_value="${BASH_REMATCH[1]}"
                    # Store the globs value but don't set apply_to yet
                    # We'll decide what to do after checking alwaysApply
                    glob_value=$(echo "$glob_value" | sed 's/^["'\'']//' | sed 's/["'\'']$//')
                    # Trim whitespace safely
                    glob_value="${glob_value#"${glob_value%%[![:space:]]*}"}"  # Remove leading whitespace
                    glob_value="${glob_value%"${glob_value##*[![:space:]]}"}"  # Remove trailing whitespace
                    
                    # Always store the glob pattern, even if it's empty or "[]"
                    glob_pattern="$glob_value"
                elif [[ "$line" =~ ^alwaysApply:[:space:]*(.*) ]]; then
                    local always_apply_value="${BASH_REMATCH[1]}"
                    # Trim whitespace safely
                    always_apply_value="${always_apply_value#"${always_apply_value%%[![:space:]]*}"}"  # Remove leading whitespace
                    always_apply_value="${always_apply_value%"${always_apply_value##*[![:space:]]}"}"  # Remove trailing whitespace
                    if [[ "$always_apply_value" == "true" ]]; then
                        always_apply=true
                    fi
                fi
            fi
        done < "$input_file"
        
        # Extract content after frontmatter (everything after second ---)
        local content_start_line=$(grep -n "^---$" "$input_file" | sed -n '2p' | cut -d: -f1)
        if [[ -n "$content_start_line" ]]; then
            content_start_line=$((content_start_line + 1))
            tail -n +${content_start_line} "$input_file" > "${temp_file}.content"
        else
            # No second ---, treat everything after first --- as content
            local first_line=$(grep -n "^---$" "$input_file" | head -1 | cut -d: -f1)
            first_line=$((first_line + 1))
            tail -n +${first_line} "$input_file" > "${temp_file}.content"
        fi
    else
        # No frontmatter, whole file is content
        cp "$input_file" "${temp_file}.content"
        log_message "WARNING" "No frontmatter found in $input_file - adding default applyTo"
    fi
    
    # Write new frontmatter
    echo "---" > "$temp_file"
    if [[ -n "$description" ]]; then
        echo "description: $description" >> "$temp_file"
    else
        echo "description: " >> "$temp_file"
    fi
    
    # IMPORTANT: If alwaysApply is true, ALWAYS use "*,**/*" regardless of globs
    if [[ "$always_apply" == true ]]; then
        apply_to="*,**/*"
    else
        # Only if alwaysApply is false, convert the globs
        if [[ -n "$glob_pattern" ]]; then
            apply_to=$(convert_glob "$glob_pattern")
        fi
    fi
    
    echo "applyTo: \"$apply_to\"" >> "$temp_file"
    echo "---" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Process content to convert .mdc references
    if [[ -f "${temp_file}.content" ]]; then
        while IFS= read -r line; do
            # Convert .mdc references to .instructions.md
            local converted_line="$line"
            # Convert .cursor/rules/ paths to .github/instructions/
            converted_line=$(echo "$converted_line" | sed 's|\.cursor/rules|.github/instructions|g')
            # Convert .mdc file extensions to .instructions.md - more comprehensive patterns
            converted_line=$(echo "$converted_line" | sed 's|\.mdc|.instructions.md|g')
            echo "$converted_line" >> "$temp_file"
        done < "${temp_file}.content"
        rm "${temp_file}.content"
    fi
    
    cat "$temp_file"
    rm -f "${temp_file}"
}

convert_single_file() {
    local source_file="$1"
    local dest_file="$2"
    local basename_source
    basename_source=$(basename "${source_file}")
    local basename_dest
    basename_dest=$(basename "${dest_file}")
    
    # Create destination directory if it doesn't exist
    local dest_dir
    dest_dir="$(dirname "${dest_file}")"
    if [[ ! -d "${dest_dir}" ]]; then
        mkdir -p "${dest_dir}"
        print_info "Created directory: ${dest_dir}"
        log_message "INFO" "Created directory: ${dest_dir}"
    fi
    
    # Check for special handling cases first
    if [[ "${basename_source}" == "derived-cursor-rules.mdc" ]]; then
        print_warning "SKIPPED auto-generated file: ${basename_source} (content should be migrated to numbered rules)"
        log_message "NOTICE" "SKIPPED auto-generated file: ${basename_source} (content should be migrated to numbered rules)"
        
        # Create a minimal file noting that it was skipped
        echo "WARN: SKIPPED auto-generated file: derived-cursor-rules.mdc" > "${dest_file}"
        
        ((FILES_SKIPPED++))
        return 0
    fi
    
    # For normal files, continue with conversion
    print_info "Converting ${basename_source} → ${basename_dest}"
    
    # Process the file and write to destination
    if [[ "${basename_source}" == "vibe-tools.mdc" ]]; then
        print_warning "Special handling for: ${basename_source}"
        log_message "INFO" "Special handling for ${basename_source}"
    fi
    
    # Process the file and write to destination
    if process_frontmatter "${source_file}" > "${dest_file}"; then
        log_message "SUCCESS" "Converted: ${dest_file}"
        ((FILES_CONVERTED++))
        return 0
    else
        print_error "Failed to convert: ${basename_source}"
        log_message "ERROR" "Failed to convert: ${source_file}"
        ((ERRORS_COUNT++))
        return 1
    fi
}

copy_instructions_readme() {
    local dest_dir="$1"
    local script_dir
    script_dir="$(dirname "$(realpath "$0")")"
    local readme_source="${script_dir}/../assets/.github/instructions/README.md"
    local readme_dest="${dest_dir}/README.md"
    
    # Only copy if source README exists and destination doesn't
    if [[ -f "${readme_source}" && ! -f "${readme_dest}" ]]; then
        cp "${readme_source}" "${readme_dest}"
        print_info "Created instructions README: ${readme_dest#${PWD}/}"
        log_message "INFO" "Copied instructions README to: ${readme_dest}"
    fi
}

find_and_convert_files() {
    local source_dir="$1"
    local dest_dir="$2"
    
    # Show relative paths for readability
    local relative_source="${source_dir#${PWD}/}"
    [[ "$relative_source" == "$source_dir" ]] && relative_source="$source_dir"
    
    print_step "Scanning for .mdc files in: ${relative_source}"
    
    # Find all .mdc files (portable approach without mapfile)
    local mdc_files=()
    while IFS= read -r -d '' file; do
        mdc_files+=("$file")
    done < <(find "${source_dir}" -name "*.mdc" -type f -print0)
    
    if [[ ${#mdc_files[@]} -eq 0 ]]; then
        print_warning "No .mdc files found in: ${relative_source}"
        return 0
    fi
    
    print_info "Found ${#mdc_files[@]} .mdc file(s) to convert"
    log_message "INFO" "Found ${#mdc_files[@]} .mdc files to convert"
    
    # Ensure destination directory exists
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir"
        print_info "Created directory: ${dest_dir#${PWD}/}"
        log_message "INFO" "Created directory: $dest_dir"
    fi
    
    # Copy instructions README to destination directory
    copy_instructions_readme "$dest_dir"
    
    # Process each file
    local conversion_error=0
    for mdc_file in "${mdc_files[@]}"; do
        ((FILES_PROCESSED++))
        
        # Generate destination filename (portable relative path)
        local relative_path
        if [[ "${mdc_file}" == "${source_dir}/"* ]]; then
            relative_path="${mdc_file#${source_dir}/}"
        else
            # Fallback if paths differ (e.g., absolute vs relative)
            relative_path="$(basename "${mdc_file}")"
        fi
        local dest_file="${dest_dir}/${relative_path%.mdc}.instructions.md"
        
        local result=0
        convert_single_file "${mdc_file}" "${dest_file}"
        result=$?
        
        # Only consider a non-zero result as an error if it's not 2 (skipped)
        if [[ ${result} -ne 0 && ${result} -ne 2 ]]; then
            conversion_error=1
        fi
    done
    
    return ${conversion_error}
}

# *
# * Main Execution Functions
# *

print_summary() {    
    if [[ ${ERRORS_COUNT} -eq 0 ]]; then
        print_completed "Conversion complete!"
    else
        print_error "Conversion completed with ${ERRORS_COUNT} errors."
    fi
    
    print_info "Converted: ${FILES_CONVERTED} files"
    
    if [[ ${FILES_SKIPPED} -gt 0 ]]; then
        print_info "Skipped: ${FILES_SKIPPED} files"
    fi
    
    print_separator
    
    # Add next steps for the user
    print_info "Next steps:"
    print_info "1. Review the converted files in .github/instructions"
    print_info "2. Test with GitHub Copilot in VS Code"
    print_info "3. Adjust applyTo patterns if needed"
    print_info "4. Consider adding a single .github/copilot-instructions.md for global rules"
}

main() {
    print_header "Cursor Rules to Instructions Converter v1.0"
    ensure_log_directory
    enable_logging
    
    # Validate arguments
    if [[ $# -ne 1 ]]; then
        print_error "Missing required project root path argument"
        echo ""
        show_usage
        exit 1
    fi
    
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    # Get and validate project root path
    local project_root
    project_root="$(cd "$1" 2>/dev/null && pwd)" || {
        print_error "Invalid project root path: $1"
        print_error "The specified path does not exist or is not accessible."
        exit 1
    }
    
    # Configuration - relative to project root
    local cursor_rules_dir="$project_root/.cursor/rules"
    local github_instructions_dir="$project_root/.github/instructions"
    
    # Show relative paths for readability
    local relative_project="${project_root#${PWD}/}"
    [[ "$relative_project" == "$project_root" ]] && relative_project="$project_root"
    local relative_source="${cursor_rules_dir#${PWD}/}"
    [[ "$relative_source" == "$cursor_rules_dir" ]] && relative_source="$cursor_rules_dir"
    local relative_dest="${github_instructions_dir#${PWD}/}"
    [[ "$relative_dest" == "$github_instructions_dir" ]] && relative_dest="$github_instructions_dir"
    
    print_info "Converting .mdc files to .instructions.md format"
    print_info "Project root: $relative_project"
    print_info "Source directory: $relative_source"
    print_info "Destination directory: $relative_dest"
    
    # Check if cursor rules directory exists
    if [[ ! -d "$cursor_rules_dir" ]]; then
        print_error "Cursor rules directory not found: $relative_source"
        print_error "Ensure your project has a .cursor/rules/ directory with .mdc files."
        exit 1
    fi
    
    # Validate environment
    validate_dependencies
    
    # Log conversion start
    log_message "INFO" "Starting Cursor rules to GitHub Copilot instructions conversion"
    log_message "INFO" "Project root: $project_root"
    
    # Perform conversion
    find_and_convert_files "$cursor_rules_dir" "$github_instructions_dir"
    
    # Show results
    print_footer
    print_summary
    
    # Log completion
    if [[ ${ERRORS_COUNT} -eq 0 ]]; then
        log_message "INFO" "Conversion completed successfully"
        exit 0
    else
        log_message "ERROR" "Conversion completed with ${ERRORS_COUNT} errors"
        exit 1
    fi
}

# --- Script Entrypoint ---
main "$@"
