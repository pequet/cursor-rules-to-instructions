# IDE Rules Synchronizer

> Maintain consistent AI guidance across multiple AI coding assistants from a Single Source of Truth (SSoT).

A utility script that synchronizes your master rules to multiple AI coding assistant formats, allowing you to maintain a single source of truth for your AI assistant configurations.

Whether you're using multiple AI tools like GitHub Copilot, Cursor, Claude, or Gemini, this script helps you maintain consistency in your AI-assisted development workflow.

## Features

- **Single Source of Truth**: Maintain all your rules in one directory (`master-rules/`)
- **Multi-Target Support**: Convert to multiple formats simultaneously:
  - **Cursor IDE**: `.cursor/rules/*.mdc`
  - **GitHub Copilot**: `.github/instructions/*.instructions.md`
  - **Claude Code**: Template-based file with rules appended as `CLAUDE.md`
  - **Gemini CLI**: Template-based file with rules appended as `GEMINI.md`
  - **Codex CLI**: Generated documentation files (`AGENTS.md`, `ARCHITECTURE.md`, `RULES.md`)
- **Flexible Configuration**: Choose which targets to generate
- **Preserves Structure**: Maintains your original rule structure and content
- **Quick Setup**: One command to synchronize your entire project
- **File Backups**: Automatically creates backups of existing files before overwriting
- **macOS Compatible**: Works with the default Bash 3.2+ shipped with macOS

## Usage

Synchronize your master rules by running the script:

```bash
./scripts/sync-ide-rules.sh --from master-rules --to cursor,github,claude,gemini,docs
```

This will convert all rules from `master-rules/` to all supported targets.

**Advanced Usage:**

```bash
# Convert only to specific targets
./scripts/sync-ide-rules.sh --to claude,gemini

# Only update documentation files
./scripts/sync-ide-rules.sh --to docs
```

Available targets:
- `cursor`: Generates `.cursor/rules/*.mdc` files (Cursor IDE)
- `github`: Generates `.github/instructions/*.instructions.md` files (GitHub Copilot)
- `claude`: Generates a single `CLAUDE.md` file with template content plus rules (Claude Code)
- `gemini`: Generates a single `GEMINI.md` file with template content plus rules (Gemini CLI)
- `docs`: Copies static documentation files (`AGENTS.md`, `ARCHITECTURE.md`, `RULES.md`) (Codex CLI)

## Project Structure

- `master-rules/`: Directory containing source rule files
- `assets/`: Templates for generating target files
  - `AGENTS.md`: Quick-start guide template
  - `ARCHITECTURE.md`: Architecture documentation template
  - `RULES.md`: Rules index template
  - `CLAUDE.md`: Claude documentation base template
  - `GEMINI.md`: Gemini documentation base template
- `scripts/`: Utility scripts
  - `sync-ide-rules.sh`: Main synchronization script
  - `utils/`: Helper utilities

## Source File Format

Place your master rule files in the `master-rules/` directory with proper markdown formatting:

```markdown
---
description: "A brief description of this rule"
globs: "*.js,*.ts"  # Files this rule applies to (for Cursor)
alwaysApply: false  # Whether to apply to all files (for Cursor)
---

# Rule Title

Rule content goes here...
```

## Template Files

The `assets/` directory should contain template files for documentation and AI assistant files:

- `AGENTS.md`: Quick-start guide for humans and AI agents (Codex CLI - optimized for 200-400 words)
- `ARCHITECTURE.md`: System architecture and component documentation  
- `RULES.md`: Index of all rules and their derived implementations
- `CLAUDE.md`: Base template for Claude Code documentation (aggregated single file approach)
- `GEMINI.md`: Base template for Gemini CLI documentation (comprehensive single file approach)

## License

This project is licensed under the MIT License.

## Support

If you find this tool helpful, consider supporting its development:

- [Buy Me a Coffee](https://buymeacoffee.com/pequet)
- [GitHub Sponsors](https://github.com/sponsors/pequet)