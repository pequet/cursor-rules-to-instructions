#!/bin/bash

# Standard Error Handling
set -e
set -u
set -o pipefail

# Error trapping for debugging
trap 'print_error "Line $LINENO failed with exit code $?"' ERR

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
#   ./sync-ide-rules.sh <project_root_path> [--to <targets>]
#   <project_root_path>: Path to the project root containing master-rules/ directory
#   --to <targets>: Comma-separated list of targets (cursor,github,claude,gemini,docs) (default: all)#
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
    echo "Usage: $0 <project_root_path> [--to <targets>]"
    echo ""
    echo "Synchronize master rules to multiple AI coding assistant formats"
    echo ""
    echo "Arguments:"
    echo "  project_root_path    Path to the project root containing master-rules/ directory"
    echo ""
    echo "Options:"
    echo "  --to <targets>       Comma-separated list of targets to generate (default: all)"
    echo "                       Available targets: cursor, github, claude, gemini, docs"
    echo "  -h, --help           Show this help message and exit"
    echo ""
    echo "Examples:"
    echo "  # Process all targets (default)"
    echo "  $0 /path/to/my/project"
    echo ""
    echo "  # Process only Claude and Gemini files"
    echo "  $0 /path/to/my/project --to claude,gemini"
    echo ""
    echo "  # Process only Cursor IDE files"
    echo "  $0 /path/to/my/project --to cursor"
    echo ""
    echo "  # Process documentation files only"
    echo "  $0 /path/to/my/project --to docs"
    echo ""
    echo "  # Process GitHub Copilot and documentation files"
    echo "  $0 /path/to/my/project --to github,docs"
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

# Ensure balanced triple backtick code fences in a file (append closing fence if odd count)
ensure_balanced_code_fences() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    local count
    # Count lines that start with ``` optionally followed by a language token
    count=$(grep -E '^```' "$file" | wc -l | tr -d ' \t') || count=0
    if [[ $count -gt 0 && $((count % 2)) -eq 1 ]]; then
        echo "\n\n\`\`\`" >> "$file"
    fi
}

# Convert Cursor-style frontmatter (globs / alwaysApply) to single applyTo line
# Rules:
#  - If globs has one specific pattern → applyTo: "thatPattern"
#  - If globs has multiple patterns → join with commas inside one quoted string
#  - Universal pair ["*", "**/*"] with alwaysApply true → applyTo: "*,**/*"
#  - alwaysApply true with no globs → applyTo: "*,**/*"
#  - Remove original globs / alwaysApply keys entirely
transform_frontmatter_to_applyTo() {
    local src="$1" dest="$2"
    local in_fm=0 fm_done=0
    local line
    local globs_line="" always_apply="" apply_to="" description_line=""
    local -a other_meta=()
    local -a body=()

    # Read file once; handle files without frontmatter quickly
    IFS= read -r line < "$src" || true
    if [[ "$line" != '---' ]]; then
        cp "$src" "$dest"; return 0
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ $line == '---' ]]; then
            if [[ $in_fm -eq 0 ]]; then in_fm=1; continue; else fm_done=1; in_fm=0; continue; fi
        fi
    if [[ $in_fm -eq 1 ]]; then
            case "$line" in
                description:*) description_line="$line" ;;
                globs:*) globs_line="$line" ;;
                alwaysApply:*) always_apply="${line#*:}" ;;
                applyTo:*) # If already present, keep & we won't attempt conversion
                    apply_to="${line#applyTo: }"; apply_to="${apply_to%\r}"; apply_to="${apply_to%\n}"; apply_to="${apply_to//\"/}" ;;
                '') ;; # skip blank inside fm
                *) other_meta+=("$line") ;;
            esac
        else
            body+=("$line")
        fi
    # Removed premature break so we capture the entire body after frontmatter
    done < "$src"

    # If apply_to not already set, derive from globs / alwaysApply
    if [[ -z $apply_to ]]; then
        # Normalize always_apply (strip spaces)
        local always_trim="${always_apply//[[:space:]]/}"
        if [[ -n $globs_line ]]; then
            local raw=${globs_line#globs:}
            # Extract content inside [ ... ]
            raw=${raw#*[[]}; raw=${raw%%]*}
            local patterns=()
            IFS=',' read -r -a parts <<< "$raw"
            for p in "${parts[@]}"; do
                p="${p//\"/}"; p="${p//\'/}"; p="${p//[[:space:]]/}"; [[ -n $p ]] && patterns+=("$p")
            done
            if [[ ${#patterns[@]} -eq 2 ]]; then
                # Sort manually without paste; rely on printf+sort
                local sorted=$(printf '%s\n' "${patterns[@]}" | sort | tr '\n' ',')
                sorted="${sorted%,}"
                if [[ $sorted == '*,**/*' ]]; then
                    apply_to="*,**/*"
                fi
            fi
            if [[ -z $apply_to ]]; then
                if [[ ${#patterns[@]} -eq 1 ]]; then
                    apply_to="${patterns[0]}"
                elif [[ ${#patterns[@]} -gt 1 ]]; then
                    apply_to="$(IFS=','; echo "${patterns[*]}")"
                fi
            fi
        fi
        if [[ -z $apply_to && $always_trim == true ]]; then
            apply_to="*,**/*"
        fi
    fi

    {
        echo '---'
        [[ -n $description_line ]] && echo "$description_line"
    # Safe expansion with set -u
    for m in ${other_meta+"${other_meta[@]}"}; do [[ -n $m ]] && echo "$m"; done
        [[ -n $apply_to ]] && echo "applyTo: \"$apply_to\""
        echo '---'
        printf '%s\n' "${body[@]}"
    } > "$dest"
}

# *
# * Target Generation Functions
# *

# Create cursor .mdc files for Cursor IDE
generate_cursor_files() {
    local source_dir="$1"
    local cursor_rules_dir="$2"
    
    print_step "Processing target: Cursor IDE"
    
    log_message "DEBUG" "Source dir: $source_dir"
    log_message "DEBUG" "Cursor rules dir: $cursor_rules_dir"
    log_message "DEBUG" "ASSETS_DIR: $ASSETS_DIR"
    
    # Create target directory if it doesn't exist
    # print_info "Creating target directory: $cursor_rules_dir"
    mkdir -p "$cursor_rules_dir"
    # print_info "Target directory created successfully"
    
    # Copy README if it exists in assets
    local cursor_readme="${ASSETS_DIR}/.cursor/rules/README.md"
    
    if [[ -f "$cursor_readme" ]]; then
        backup_file "${cursor_rules_dir}/README.md" || log_message "DEBUG" "Cursor README backup skipped (file doesn't exist)"
        log_message "DEBUG" "Backup completed, copying README"
        cp "$cursor_readme" "${cursor_rules_dir}/README.md"
        log_message "INFO" "Copied Cursor README to: ${cursor_rules_dir}/README.md"
    else
        print_warning "README file not found: $cursor_readme"
    fi
    
    # Find all source files
    log_message "INFO" "Looking for .md files in: $source_dir"
    
    local file_count=0
    while IFS= read -r -d '' source_file; do
        ((file_count++))
        log_message "INFO" "Processing file $file_count: $source_file"
        
        ((FILES_PROCESSED++))
        local basename_file=$(basename "$source_file")
        local dest_file="${cursor_rules_dir}/${basename_file%.md}.mdc"
        
        log_message "INFO" "Converting $basename_file to ${basename_file%.md}.mdc"
        
        # Backup existing file
        backup_file "$dest_file" || log_message "DEBUG" "Backup failed or file didn't exist"
        
        # Simple copy with extension change - assumes master rules are already in correct format
        # In a real implementation, you might process the file here
        cp "$source_file" "$dest_file"
        
        # print_info "Generated: ${dest_file#${PROJECT_ROOT}/}"
        log_message "INFO" "Generated Cursor file: $dest_file"
        ((FILES_CONVERTED++))
    done < <(find "$source_dir" -name "*.md" -type f -print0)
    
    print_info "Cursor files generation completed. Processed $file_count rules."
}

# Create GitHub Copilot .instructions.md files
generate_github_files() {
    local source_dir="$1" github_instructions_dir="$2"
    print_step "Processing target: GitHub Copilot"
    mkdir -p "$github_instructions_dir"
    local github_readme="${ASSETS_DIR}/.github/instructions/README.md"
    if [[ -f "$github_readme" ]]; then
        backup_file "${github_instructions_dir}/README.md" || true
        cp "$github_readme" "${github_instructions_dir}/README.md"
    fi
    local file_count=0
    while IFS= read -r -d '' src; do
        ((file_count++))
        ((FILES_PROCESSED++))
        local base=$(basename "$src")
        local dest="${github_instructions_dir}/${base%.md}.instructions.md"
        backup_file "$dest" || true
        transform_frontmatter_to_applyTo "$src" "$dest"
        ((FILES_CONVERTED++))
    done < <(find "$source_dir" -type f -name '*.md' -print0)
    print_info "GitHub files generation completed. Processed $file_count rules."
}

# Create CLAUDE.md for Claude Code
generate_claude_file() {
    local source_dir="$1"
    local claude_file="$2"
    local claude_template="${ASSETS_DIR}/CLAUDE.md"
    
    print_step "Processing target: Claude Code" #: ${claude_file#${PROJECT_ROOT}/}"
    
    # Check if template exists
    if [[ ! -f "$claude_template" ]]; then
        print_error "Claude template not found: ${claude_template#${PROJECT_ROOT}/}"
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
        return 0
    fi
    
    log_message "DEBUG" "Found ${#rule_files[@]} rule files to process"
    
    # Append each rule to the Claude file with proper heading format
    for rule_file in "${rule_files[@]}"; do
        ((FILES_PROCESSED++))
        local basename_rule=$(basename "${rule_file}")
        
        # Skipping individual file output for conciseness
        
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
        
        # Add rule to Claude file with H3 heading (under "## Development Rules")
        if [[ -n "$rule_id" ]]; then
            echo "### [${rule_id}] ${title}" >> "$claude_file"
        else
            echo "### ${title}" >> "$claude_file"
        fi
        echo "" >> "$claude_file"
        
        # Skipping individual file output for conciseness


        # Extract content after frontmatter with whitespace normalization
        local in_frontmatter=false
        local frontmatter_count=0
        local started=false
        local prev_blank=false
        
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
            
            # Add all other content (collapse multiple blank lines; drop leading blanks)
            if [[ -z "$line" ]]; then
                if [[ "$started" == false ]]; then
                    continue
                fi
                if [[ "$prev_blank" == true ]]; then
                    continue
                fi
                echo "" >> "$claude_file"
                prev_blank=true
                continue
            fi
            echo "$line" >> "$claude_file"
            started=true
            prev_blank=false
        done < "$rule_file"
        
        # Add separator between rules (ensure single blank)
        if [[ "$prev_blank" == false ]]; then
            echo "" >> "$claude_file"
        fi
        # Balance fences after each rule block to localize issues
        ensure_balanced_code_fences "$claude_file"
        
        ((FILES_CONVERTED++))
    done
    
    print_info "Claude files generation completed. Processed ${#rule_files[@]} rules."
    # Final balance pass
    ensure_balanced_code_fences "$claude_file"
    # print_info "Claude file created successfully: ${claude_file#${PROJECT_ROOT}/}"
}

# Create GEMINI.md for Gemini CLI
generate_gemini_file() {
    local source_dir="$1"
    local gemini_file="$2"
    local gemini_template="${ASSETS_DIR}/GEMINI.md"
    
    print_step "Processing target: Gemini CLI" #: ${gemini_file#${PROJECT_ROOT}/}"
    
    # Check if template exists
    if [[ ! -f "$gemini_template" ]]; then
        print_error "Gemini template not found: ${gemini_template#${PROJECT_ROOT}/}"
        ((ERRORS_COUNT++))
        return 1
    fi
    
    log_message "DEBUG" "PROJECT_ROOT=$PROJECT_ROOT"
    log_message "DEBUG" "ASSETS_DIR=$ASSETS_DIR"
    log_message "DEBUG" "gemini_template=$gemini_template"
    log_message "DEBUG" "Template exists? $(test -f "$gemini_template" && echo YES || echo NO)"
    
    # Backup existing file
    backup_file "$gemini_file"
    log_message "DEBUG" "After backup_file call"
    
    # Copy template to destination
    cp "$gemini_template" "$gemini_file"
    log_message "DEBUG" "After template copy"
    
    # Find all rule files
    local rule_files=()
    while IFS= read -r -d '' file; do
        rule_files+=("$file")
    done < <(find "${source_dir}" -name "*.md" -type f -print0 | sort -z)
    
    if [[ ${#rule_files[@]} -eq 0 ]]; then
        print_warning "No rule files found in: ${source_dir#${PROJECT_ROOT}/}"
        return 0
    fi
    
    log_message "DEBUG" "Found ${#rule_files[@]} rule files to process"
    
    log_message "DEBUG" "About to start Gemini file processing loop"
    
    # Append each rule to the Gemini file with proper heading format
    for rule_file in "${rule_files[@]}"; do
        ((FILES_PROCESSED++))
        local basename_rule=$(basename "${rule_file}")
        
        log_message "DEBUG" "Processing Gemini file: $rule_file"
        # Skipping individual file output for conciseness
        
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
        
        # Add rule to Gemini file with H3 heading (under "## Development Rules")
        if [[ -n "$rule_id" ]]; then
            echo "### [${rule_id}] ${title}" >> "$gemini_file"
        else
            echo "### ${title}" >> "$gemini_file"
        fi
        echo "" >> "$gemini_file"
        
        # Extract content after frontmatter (only top block) with whitespace normalization
        local in_frontmatter=false
        local frontmatter_done=false
        local heading_skipped=false
        local started=false
        local prev_blank=false
        
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
            
            # Add all other content; collapse multiple blanks; drop leading blanks
            if [[ -z "$line" ]]; then
                if [[ "$started" == false ]]; then
                    continue
                fi
                if [[ "$prev_blank" == true ]]; then
                    continue
                fi
                echo "" >> "$gemini_file"
                prev_blank=true
                continue
            fi
            echo "$line" >> "$gemini_file"
            started=true
            prev_blank=false
        done < "$rule_file"
        
        # Ensure exactly one blank line after each rule block
        if [[ "$prev_blank" == false ]]; then
            echo "" >> "$gemini_file"
        fi
    ensure_balanced_code_fences "$gemini_file"
        
        ((FILES_CONVERTED++))
    done
    
    print_info "Gemini files generation completed. Processed ${#rule_files[@]} rules."
    # print_info "Gemini file created successfully: ${gemini_file#${PROJECT_ROOT}/}"
    ensure_balanced_code_fences "$gemini_file"
}

# Copy documentation files for Codex CLI
copy_doc_files_to_project() {
    local target_project_root="$1"
    local doc_files=("AGENTS.md" "ARCHITECTURE.md" "RULES.md")
    
    print_step "Processing target: Codex CLI Documentation"
    
    for doc_file in "${doc_files[@]}"; do
        local source_file="${ASSETS_DIR}/${doc_file}"
        local dest_file="${target_project_root}/${doc_file}"
        
        if [[ ! -f "$source_file" ]]; then
            print_error "Documentation template not found: ${source_file#${PROJECT_ROOT}/}"
            ((ERRORS_COUNT++))
            continue
        fi
        
        # Backup existing file
        backup_file "$dest_file"
        
        # Copy template to destination
        cp "$source_file" "$dest_file"
    # Balance code fences in copied doc
    ensure_balanced_code_fences "$dest_file"
        
        print_info "Copied ${doc_file} to project root"
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
