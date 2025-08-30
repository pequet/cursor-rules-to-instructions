#!/bin/bash

# Standard Error Handling
# Temporarily disabled for debugging
#set -e
#set -u
#set -o pipefail

# Error trapping for debugging
trap 'echo "ERROR: Line $LINENO failed with exit code $?" >&2' ERR

# --- Logging Toggle (disabled until log dir ensured) ---
LOGGING_ENABLED=0

# █   █  IDE Rules Synchronizer: Multi-Target Rule Conversion Tool
#  █ █   Version: 3.0.0
#  █ █   Author: Benjamin Pequet
# █   █  GitHub: https://github.com/pequet/cursor-rules-to-instructions/
#
# Purpose:
#   Synchronizes master rules to multiple AI coding assistant formats.
#   Generates documentation files (AGENTS.md, ARCHITECTURE.md, RULES.md) and 
#   AI-specific files (CLAUDE.md, GEMINI.md) from templates in assets/.
#   Creates individual rule files for different IDE assistants (.cursor/rules/*.mdc, .github/instructions/*.instructions.md)
#
# Usage:
#   ./sync-ide-rules.sh --from <source_dir> --to <targets>
#   --from <source_dir>: Directory containing master rule files (default: master-rules)
#   --to <targets>: Comma-separated list of targets (cursor,github,claude,gemini,docs) (default: all)
#
# Dependencies:
#   - Bash 3.2+ (compatible with macOS default bash)
#   - Standard Unix utilities (find, sed, awk, grep)
#   - scripts/utils/messaging_utils.sh
#   - scripts/utils/logging_utils.sh
#
# Changelog:
#   3.0.0 - 2025-08-29 - Refactored to support multi-agent docs and a simpler approach
#   2.0.0 - 2025-08-29 - Major refactoring to support multiple targets
#   1.0.0 - 2025-08-17 - Initial release
#
# Support the Project:
#   - Buy Me a Coffee: https://buymeacoffee.com/pequet
#   - GitHub Sponsors: https://github.com/sponsors/pequet


# --- Global Variables ---
# Resolve the true script directory, following symlinks
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
PROJECT_ROOT="$( cd -P "$( dirname "$SCRIPT_DIR" )" >/dev/null 2>&1 && pwd )"

# --- Utility Scripts ---
source "${SCRIPT_DIR}/utils/logging_utils.sh"
source "${SCRIPT_DIR}/utils/messaging_utils.sh"

# --- Configuration ---
# Processing statistics
declare -i FILES_PROCESSED=0
declare -i FILES_CONVERTED=0
declare -i FILES_SKIPPED=0
declare -i ERRORS_COUNT=0

# --- Asset Paths ---
ASSETS_DIR="${PROJECT_ROOT}/assets"

# --- Logging Configuration ---
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE_PATH="${SCRIPT_DIR}/logs/${SCRIPT_NAME}.log"

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
    echo "Synchronize master rules to multiple AI coding assistant formats"
    echo ""
    echo "Arguments:"
    echo "  project_root_path    Path to the project root containing master-rules/ directory"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/my/project"
    echo "  $0 ."
}

backup_file() {
    local file_path="$1"
    
    if [[ -f "$file_path" ]]; then
        local backup_file="${file_path}.bak"
        cp "$file_path" "$backup_file"
        return 0
    fi
    return 0
}

# *
# * Target Generation Functions
# *

# Create cursor .mdc files for Cursor IDE
generate_cursor_files() {
    echo "DEBUG: Entering generate_cursor_files function" >&2
    local source_dir="$1"
    local cursor_rules_dir="$2"
    echo "DEBUG: source_dir=$source_dir, cursor_rules_dir=$cursor_rules_dir" >&2
    
    print_step "Processing target: Cursor IDE"
    echo "DEBUG: After print_step" >&2
    echo "INFO: Processing target: Cursor IDE" >&2
    echo "DEBUG: After first log_message" >&2
    
    echo "INFO: Source dir: $source_dir" >&2
    echo "DEBUG: After source dir log" >&2
    echo "INFO: Cursor rules dir: $cursor_rules_dir" >&2
    echo "DEBUG: After cursor rules dir log" >&2
    echo "INFO: ASSETS_DIR: $ASSETS_DIR" >&2
    echo "DEBUG: After ASSETS_DIR log" >&2
    
    # Create target directory if it doesn't exist
    echo "DEBUG: About to create directory" >&2
    echo "INFO: Creating target directory: $cursor_rules_dir" >&2
    echo "DEBUG: About to run mkdir -p" >&2
    mkdir -p "$cursor_rules_dir"
    echo "DEBUG: mkdir completed" >&2
    echo "INFO: Target directory created successfully" >&2
    echo "DEBUG: Directory creation logged" >&2
    
    # Copy README if it exists in assets
    echo "DEBUG: About to copy README" >&2
    local cursor_readme="${ASSETS_DIR}/.cursor/rules/README.md"
    echo "DEBUG: cursor_readme=$cursor_readme" >&2
    echo "INFO: Checking for README file: $cursor_readme" >&2
    echo "DEBUG: After checking README log" >&2
    
    if [[ -f "$cursor_readme" ]]; then
        echo "DEBUG: README file exists" >&2
        echo "INFO: README file exists, proceeding with backup and copy" >&2
        echo "DEBUG: About to backup README" >&2
        backup_file "${cursor_rules_dir}/README.md" || echo "DEBUG: Backup returned non-zero (file doesn't exist)" >&2
        echo "DEBUG: Backup completed" >&2
        echo "INFO: Backup completed, copying README" >&2
        echo "DEBUG: About to cp README" >&2
        cp "$cursor_readme" "${cursor_rules_dir}/README.md"
        echo "DEBUG: cp completed" >&2
        print_info "Copied Cursor rules README"
        echo "DEBUG: print_info completed" >&2
        echo "SUCCESS: Copied Cursor README to: ${cursor_rules_dir}/README.md" >&2
        echo "DEBUG: Success log completed" >&2
    else
        echo "DEBUG: README file not found" >&2
        echo "WARNING: README file not found: $cursor_readme" >&2
        echo "DEBUG: Warning log completed" >&2
    fi
    
    # Find all source files
    echo "DEBUG: About to find source files" >&2
    echo "INFO: Looking for .md files in: $source_dir" >&2
    echo "DEBUG: After find log" >&2
    
    local file_count=0
    echo "DEBUG: Initialized file_count=0" >&2
    while IFS= read -r -d '' source_file; do
        ((file_count++))
        echo "INFO: Processing file $file_count: $source_file" >&2
        
        ((FILES_PROCESSED++))
        local basename_file=$(basename "$source_file")
        local dest_file="${cursor_rules_dir}/${basename_file%.md}.mdc"
        
        echo "INFO: Converting $basename_file to ${basename_file%.md}.mdc" >&2
        
        # Backup existing file
        backup_file "$dest_file" || echo "DEBUG: Backup failed or file didn't exist" >&2
        echo "DEBUG: Past backup_file call" >&2
        
        # Simple copy with extension change - assumes master rules are already in correct format
        # In a real implementation, you might process the file here
        cp "$source_file" "$dest_file"
        
        print_info "Generated: ${dest_file#${PROJECT_ROOT}/}"
        echo "SUCCESS: Generated Cursor file: $dest_file" >&2
        ((FILES_CONVERTED++))
        echo "DEBUG: File processing completed for: $source_file" >&2
    done < <(echo "DEBUG: Starting find command for: $source_dir" >&2 && find "$source_dir" -name "*.md" -type f -print0)
    echo "DEBUG: Find command completed" >&2
    
    echo "INFO: Cursor files generation completed. Processed $file_count files." >&2
}

# Create GitHub Copilot .instructions.md files
generate_github_files() {
    echo "DEBUG: Entering generate_github_files function" >&2
    local source_dir="$1"
    local github_instructions_dir="$2"
    echo "DEBUG: source_dir=$source_dir, github_instructions_dir=$github_instructions_dir" >&2
    
    print_step "Processing target: GitHub Copilot"
    echo "DEBUG: After print_step" >&2
    echo "INFO: Processing target: GitHub Copilot" >&2
    echo "DEBUG: After first log_message" >&2
    
    echo "INFO: Source dir: $source_dir" >&2
    echo "DEBUG: After source dir log" >&2
    echo "INFO: GitHub instructions dir: $github_instructions_dir" >&2
    echo "DEBUG: After github instructions dir log" >&2
    echo "INFO: ASSETS_DIR: $ASSETS_DIR" >&2
    echo "DEBUG: After ASSETS_DIR log" >&2
    
    # Create target directory if it doesn't exist
    echo "DEBUG: About to create directory" >&2
    echo "INFO: Creating target directory: $github_instructions_dir" >&2
    echo "DEBUG: About to run mkdir -p" >&2
    mkdir -p "$github_instructions_dir"
    echo "DEBUG: mkdir completed" >&2
    echo "INFO: Target directory created successfully" >&2
    echo "DEBUG: Directory creation logged" >&2
    
    # Copy README if it exists in assets
    echo "DEBUG: About to copy README" >&2
    local github_readme="${ASSETS_DIR}/.github/instructions/README.md"
    echo "DEBUG: github_readme=$github_readme" >&2
    echo "INFO: Checking for README file: $github_readme" >&2
    echo "DEBUG: After checking README log" >&2
    
    if [[ -f "$github_readme" ]]; then
        echo "DEBUG: README file exists" >&2
        echo "INFO: README file exists, proceeding with backup and copy" >&2
        echo "DEBUG: About to backup README" >&2
        backup_file "${github_instructions_dir}/README.md" || echo "DEBUG: Backup returned non-zero (file doesn't exist)" >&2
        echo "DEBUG: Backup completed" >&2
        echo "INFO: Backup completed, copying README" >&2
        echo "DEBUG: About to cp README" >&2
        cp "$github_readme" "${github_instructions_dir}/README.md"
        echo "DEBUG: cp completed" >&2
        print_info "Copied GitHub instructions README"
        echo "DEBUG: print_info completed" >&2
        echo "SUCCESS: Copied GitHub README to: ${github_instructions_dir}/README.md" >&2
        echo "DEBUG: Success log completed" >&2
    else
        echo "DEBUG: README file not found" >&2
        echo "WARNING: README file not found: $github_readme" >&2
        echo "DEBUG: Warning log completed" >&2
    fi
    
    # Find all source files
    echo "DEBUG: About to find source files" >&2
    echo "INFO: Looking for .md files in: $source_dir" >&2
    echo "DEBUG: After find log" >&2
    
    local file_count=0
    echo "DEBUG: Initialized file_count=0" >&2
    while IFS= read -r -d '' source_file; do
        ((file_count++))
        echo "INFO: Processing file $file_count: $source_file" >&2
        
        ((FILES_PROCESSED++))
        local basename_file=$(basename "$source_file")
        local dest_file="${github_instructions_dir}/${basename_file%.md}.instructions.md"
        
        echo "INFO: Converting $basename_file to ${basename_file%.md}.instructions.md" >&2
        
        # Backup existing file
        backup_file "$dest_file" || echo "DEBUG: Backup failed or file didn't exist" >&2
        echo "DEBUG: Past backup_file call" >&2
        
        # Convert frontmatter and copy content
        # For simplicity, assuming a simple copy with extension change
        # In a full implementation, you would process frontmatter here
        cp "$source_file" "$dest_file"
        
        print_info "Generated: ${dest_file#${PROJECT_ROOT}/}"
        echo "SUCCESS: Generated GitHub Copilot file: $dest_file" >&2
        ((FILES_CONVERTED++))
        echo "DEBUG: File processing completed for: $source_file" >&2
    done < <(echo "DEBUG: Starting find command for: $source_dir" >&2 && find "$source_dir" -name "*.md" -type f -print0)
    echo "DEBUG: Find command completed" >&2
    
    echo "INFO: GitHub files generation completed. Processed $file_count files." >&2
}

# Create CLAUDE.md for Claude Code
generate_claude_file() {
    local source_dir="$1"
    local claude_file="$2"
    local claude_template="${ASSETS_DIR}/CLAUDE.md"
    
    print_step "Creating Claude Code file: ${claude_file#${PROJECT_ROOT}/}"
    echo "INFO: Processing target: Claude Code" >&2
    
    # Check if template exists
    if [[ ! -f "$claude_template" ]]; then
        print_error "Claude template not found: ${claude_template#${PROJECT_ROOT}/}"
        echo "ERROR: Claude template not found: $claude_template" >&2
        ((ERRORS_COUNT++))
        return 1
    fi
    
    # Backup existing file
    backup_file "$claude_file"
    
    # Copy template to destination
    cp "$claude_template" "$claude_file"
    
    # Find all rule files
    local rule_files=()
    while IFS= read -r -d '' file; do
        rule_files+=("$file")
    done < <(find "${source_dir}" -name "*.md" -type f -print0 | sort -z)
    
    if [[ ${#rule_files[@]} -eq 0 ]]; then
        print_warning "No rule files found in: ${source_dir#${PROJECT_ROOT}/}"
        echo "WARNING: No rule files found in: $source_dir" >&2
        return 0
    fi
    
    print_info "Found ${#rule_files[@]} rule file(s) to process"
    echo "INFO: Found ${#rule_files[@]} rule files for Claude" >&2
    
    # Append each rule to the Claude file with proper heading format
    for rule_file in "${rule_files[@]}"; do
        ((FILES_PROCESSED++))
        local basename_rule=$(basename "${rule_file}")
        
        print_info "Adding ${basename_rule} to Claude file"
        
        # Extract rule ID and title (assuming format like 1001-rule-name.md)
        local rule_id
        local title
        
        # Try to extract ID from filename (assumes format like 1001-rule-name.md)
        if [[ $basename_rule =~ ^([0-9]+)- ]]; then
            rule_id="${BASH_REMATCH[1]}"
            # Extract title from file (first heading)
            title=$(grep -m 1 "^# " "$rule_file" | sed 's/^# //')
            
            # If no title found, use filename without extension and ID
            if [[ -z "$title" ]]; then
                title="${basename_rule#${rule_id}-}"
                title="${title%.md}"
            fi
        else
            # If no ID found, just use the title
            rule_id=""
            title=$(grep -m 1 "^# " "$rule_file" | sed 's/^# //')
            
            # If no title found, use filename without extension
            if [[ -z "$title" ]]; then
                title="${basename_rule%.md}"
            fi
        fi
        
        # Add a blank line and then add rule to Claude file with H3 heading (under "## Development Rules")
        echo "" >> "$claude_file"
        if [[ -n "$rule_id" ]]; then
            echo "### [${rule_id}] ${title}" >> "$claude_file"
        else
            echo "### ${title}" >> "$claude_file"
        fi
        echo "" >> "$claude_file"
        
        # Extract content after frontmatter
        local in_frontmatter=false
        local frontmatter_count=0
        
        while IFS= read -r line; do
            if [[ "$line" == "---" ]]; then
                if [[ "$in_frontmatter" == false ]]; then
                    in_frontmatter=true
                    ((frontmatter_count++))
                else
                    in_frontmatter=false
                    ((frontmatter_count++))
                fi
                continue
            fi
            
            # Skip frontmatter content
            if [[ "$in_frontmatter" == true ]]; then
                continue
            fi
            
            # Skip initial heading (already used as section title)
            if [[ "$frontmatter_count" -eq 2 && "$line" =~ ^#[[:space:]] ]]; then
                frontmatter_count=3  # Mark that we've processed the heading
                continue
            fi
            
            # Add all other content
            echo "$line" >> "$claude_file"
        done < "$rule_file"
        
        # Add separator between rules
        echo "" >> "$claude_file"
        
        ((FILES_CONVERTED++))
    done
    
    print_info "Claude file created successfully: ${claude_file#${PROJECT_ROOT}/}"
    echo "SUCCESS: Created Claude file: $claude_file with ${#rule_files[@]} rules" >&2
}

# Create GEMINI.md for Gemini CLI
generate_gemini_file() {
    local source_dir="$1"
    local gemini_file="$2"
    local gemini_template="${ASSETS_DIR}/GEMINI.md"
    
    print_step "Creating Gemini CLI file: ${gemini_file#${PROJECT_ROOT}/}"
    echo "INFO: Processing target: Gemini CLI" >&2
    
    # Check if template exists
    if [[ ! -f "$gemini_template" ]]; then
        print_error "Gemini template not found: ${gemini_template#${PROJECT_ROOT}/}"
        echo "ERROR: Gemini template not found: $gemini_template" >&2
        ((ERRORS_COUNT++))
        return 1
    fi
    
    echo "DEBUG: PROJECT_ROOT=$PROJECT_ROOT" >&2
    echo "DEBUG: ASSETS_DIR=$ASSETS_DIR" >&2
    echo "DEBUG: gemini_template=$gemini_template" >&2
    echo "DEBUG: Template exists? $(test -f "$gemini_template" && echo "YES" || echo "NO")" >&2
    
    # Backup existing file
    backup_file "$gemini_file"
    echo "DEBUG: After backup_file call" >&2
    
    # Copy template to destination
    cp "$gemini_template" "$gemini_file"
    echo "DEBUG: After template copy" >&2
    
    # Find all rule files
    local rule_files=()
    while IFS= read -r -d '' file; do
        rule_files+=("$file")
    done < <(find "${source_dir}" -name "*.md" -type f -print0 | sort -z)
    
    if [[ ${#rule_files[@]} -eq 0 ]]; then
        print_warning "No rule files found in: ${source_dir#${PROJECT_ROOT}/}"
        echo "WARNING: No rule files found in: $source_dir" >&2
        return 0
    fi
    
    print_info "Found ${#rule_files[@]} rule file(s) to process"
    echo "INFO: Found ${#rule_files[@]} rule files for Gemini" >&2
    
    echo "DEBUG: About to start Gemini file processing loop" >&2
    
    # Append each rule to the Gemini file with proper heading format
    for rule_file in "${rule_files[@]}"; do
        ((FILES_PROCESSED++))
        local basename_rule=$(basename "${rule_file}")
        
        echo "DEBUG: Processing Gemini file: $rule_file" >&2
        print_info "Adding ${basename_rule} to Gemini file"
        
        # Extract rule ID and title (assuming format like 1001-rule-name.md)
        local rule_id
        local title
        
        # Try to extract ID from filename (assumes format like 1001-rule-name.md)
        if [[ $basename_rule =~ ^([0-9]+)- ]]; then
            rule_id="${BASH_REMATCH[1]}"
            # Extract title from file (first heading)
            title=$(grep -m 1 "^# " "$rule_file" | sed 's/^# //')
            
            # If no title found, use filename without extension and ID
            if [[ -z "$title" ]]; then
                title="${basename_rule#${rule_id}-}"
                title="${title%.md}"
            fi
        else
            # If no ID found, just use the title
            rule_id=""
            title=$(grep -m 1 "^# " "$rule_file" | sed 's/^# //')
            
            # If no title found, use filename without extension
            if [[ -z "$title" ]]; then
                title="${basename_rule%.md}"
            fi
        fi
        
        # Add a blank line and then add rule to Gemini file with H3 heading (under "## Development Rules")
        echo "" >> "$gemini_file"
        if [[ -n "$rule_id" ]]; then
            echo "### [${rule_id}] ${title}" >> "$gemini_file"
        else
            echo "### ${title}" >> "$gemini_file"
        fi
        echo "" >> "$gemini_file"
        
        # Extract content after frontmatter (only treat the first frontmatter block at the top)
        local in_frontmatter=false
        local frontmatter_done=false
        local heading_skipped=false
        
        while IFS= read -r line; do
            # Handle only the first frontmatter pair at the start of the file
            if [[ "$frontmatter_done" == false && "$line" == "---" ]]; then
                if [[ "$in_frontmatter" == false ]]; then
                    in_frontmatter=true
                else
                    in_frontmatter=false
                    frontmatter_done=true
                fi
                continue
            fi
            
            # Skip lines while inside the top-of-file frontmatter
            if [[ "$in_frontmatter" == true ]]; then
                continue
            fi
            
            # Skip the first markdown H1 heading after frontmatter
            if [[ "$frontmatter_done" == true && "$heading_skipped" == false && "$line" =~ ^#[[:space:]] ]]; then
                heading_skipped=true
                continue
            fi
            
            # Add all other content (including code fences and YAML examples)
            echo "$line" >> "$gemini_file"
        done < "$rule_file"
        
        # Add spacing between rules
        echo "" >> "$gemini_file"
        echo "" >> "$gemini_file"
        
        ((FILES_CONVERTED++))
    done
    
    print_info "Gemini file created successfully: ${gemini_file#${PROJECT_ROOT}/}"
    echo "SUCCESS: Created Gemini file: $gemini_file with ${#rule_files[@]} rules" >&2
}

# Copy documentation files for Codex CLI
copy_doc_files_to_project() {
    local target_project_root="$1"
    local doc_files=("AGENTS.md" "ARCHITECTURE.md" "RULES.md")
    
    print_step "Processing target: Codex CLI Documentation"
    echo "INFO: Processing target: Codex CLI Documentation" >&2
    
    for doc_file in "${doc_files[@]}"; do
        local source_file="${ASSETS_DIR}/${doc_file}"
        local dest_file="${target_project_root}/${doc_file}"
        
        if [[ ! -f "$source_file" ]]; then
            print_error "Documentation template not found: ${source_file#${PROJECT_ROOT}/}"
            echo "ERROR: Documentation template not found: $source_file" >&2
            ((ERRORS_COUNT++))
            continue
        fi
        
        # Backup existing file
        backup_file "$dest_file"
        
        # Copy template to destination
        cp "$source_file" "$dest_file"
        
        print_info "Copied ${doc_file} to project root"
        echo "SUCCESS: Copied documentation file: $doc_file" >&2
        ((FILES_CONVERTED++))
    done
}

# *
# * Main Execution Functions
# *

print_summary() {    
    if [[ ${ERRORS_COUNT} -eq 0 ]]; then
        print_completed "Synchronization complete!"
    else
        print_error "Synchronization completed with ${ERRORS_COUNT} errors."
    fi
    
    print_info "Converted: ${FILES_CONVERTED} files"
    
    if [[ ${FILES_SKIPPED} -gt 0 ]]; then
        print_info "Skipped: ${FILES_SKIPPED} files"
    fi
    
    print_separator
    
    # Add next steps for the user
    print_info "Next steps:"
    print_info "1. Review the generated files in their respective locations:"
    print_info "   - Codex CLI Documentation: AGENTS.md, ARCHITECTURE.md, RULES.md"
    print_info "   - Cursor IDE: .cursor/rules/"
    print_info "   - GitHub Copilot: .github/instructions/"
    print_info "   - Claude Code: CLAUDE.md"
    print_info "   - Gemini CLI: GEMINI.md"
    print_info "2. Test with your preferred AI coding assistants"
    print_info "3. Make any necessary adjustments to the rule files"
}

main() {
    print_header "IDE Rules Synchronizer v3.0"
    ensure_log_directory
    enable_logging
    
    # Initialize variables
    local project_root=""
    local targets="cursor,github,claude,gemini,docs"  # default all targets
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --to)
                targets="$2"
                shift 2
                ;;
            --from)
                shift  # skip --from for now, we use positional arg
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*|--*)
                print_error "Unknown option $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$project_root" ]]; then
                    project_root="$1"
                else
                    print_error "Multiple project paths specified: $project_root and $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required project root
    if [[ -z "$project_root" ]]; then
        print_error "Missing required project root path argument"
        echo ""
        show_usage
        exit 1
    fi
    
    # Get and validate project root path
    project_root="$(cd "$project_root" 2>/dev/null && pwd)" || {
        print_error "Invalid project root path: $project_root"
        print_error "The specified path does not exist or is not accessible."
        exit 1
    }
    
    # Configuration - relative to project root
    local master_rules_dir="$project_root/master-rules"
    
    # Show relative paths for readability
    local relative_project="${project_root#${PWD}/}"
    [[ "$relative_project" == "$project_root" ]] && relative_project="$project_root"
    local relative_source="${master_rules_dir#${PWD}/}"
    [[ "$relative_source" == "$master_rules_dir" ]] && relative_source="$master_rules_dir"
    
    print_info "Synchronizing IDE rules from master-rules"
    print_info "Project root: $relative_project"
    print_info "Source directory: $relative_source"
    print_info "Target formats: $targets"
    
    # Check if master-rules directory exists
    if [[ ! -d "$master_rules_dir" ]]; then
        print_error "Master-rules directory not found: $relative_source"
        print_error "Ensure your project has a master-rules/ directory with rule files."
        exit 1
    fi
    
        # Set source_dir to master_rules_dir for consistency with existing code
    source_dir="$master_rules_dir"

    # Set USER_PROJECT_ROOT for functions that need the user's project path
    USER_PROJECT_ROOT="$project_root"

    # Initialize global counters
    FILES_PROCESSED=0
    FILES_CONVERTED=0
    FILES_SKIPPED=0
    ERRORS_COUNT=0
    
    # Check if assets directory exists
    if [[ ! -d "$ASSETS_DIR" ]]; then
        print_error "Assets directory not found: $ASSETS_DIR"
        print_error "Ensure the script's assets/ directory contains template files."
        exit 1
    fi
    
    # Validate dependencies
    validate_dependencies
    
    # Log conversion start
    log_message "INFO" "Starting rules synchronization"
    log_message "INFO" "Project root: $relative_project"
    log_message "INFO" "Source directory: $relative_source"
    log_message "INFO" "Target formats: $targets"
    
    # Convert targets string to array
    IFS=',' read -ra target_array <<< "$targets"
    
    # Process each target
    for target in "${target_array[@]}"; do
        case "$target" in
            cursor)
                generate_cursor_files "$source_dir" "${project_root}/.cursor/rules"
                ;;
            
            github)
                generate_github_files "$source_dir" "${project_root}/.github/instructions"
                ;;
            
            claude)
                generate_claude_file "$source_dir" "${project_root}/CLAUDE.md"
                ;;
            
            gemini)
                generate_gemini_file "$source_dir" "${project_root}/GEMINI.md"
                ;;
            
            docs)
                copy_doc_files_to_project "$project_root"
                ;;
            
            *)
                print_warning "Unknown target: $target (skipping)"
                ((FILES_SKIPPED++))
                ;;
        esac
    done
    
    # Show results
    print_footer
    print_summary
    
    # Log completion
    if [[ ${ERRORS_COUNT} -eq 0 ]]; then
        log_message "INFO" "Synchronization completed successfully"
        exit 0
    else
        log_message "ERROR" "Synchronization completed with ${ERRORS_COUNT} errors"
        exit 1
    fi
}

# --- Script Entrypoint ---
main "$@"
