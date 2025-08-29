# IDE Rules Synchronizer

> Maintain consistent AI guidance across multiple AI coding assistants from a Single Source of Truth (SSoT).

A utility script that synchronizes your master rules to multiple AI coding assistant formats, allowing you to maintain a single source of truth for your AI assistant configurations.

Whether you're using multiple AI tools like GitHub Copilot, Cursor, Claude, or Gemini, this script helps you maintain consistency in your AI-assisted development workflow.

## Features

- **Single Source of Truth**: Maintain all your rules in one directory (`master-rules/`)
- **Multi-Target Support**: Convert to multiple formats simultaneously:
  - **Cursor**: `.cursor/rules/*.mdc`
  - **GitHub Copilot**: `.github/instructions/*.instructions.md`
  - **Claude**: Single file concatenation to `CLAUDE.md`
  - **Gemini**: Simple markdown format in `GEMINI.md`
- **Flexible Configuration**: Choose which targets to generate
- **Preserves Structure**: Maintains your original rule structure and content
- **Quick Setup**: One command to synchronize your entire project

## Usage

Synchronize your master rules by running the script with your project path:

```bash
./sync-ide-rules.sh /path/to/my/project
```

This will convert all rules from `master-rules/` to all supported targets.

**Advanced Usage:**

```bash
# Specify a custom source directory
./sync-ide-rules.sh /path/to/my/project --from my-custom-rules

# Convert only to specific targets
./sync-ide-rules.sh /path/to/my/project --to cursor,github
```

Available targets:
- `cursor`: Generates `.cursor/rules/*.mdc` files
- `github`: Generates `.github/instructions/*.instructions.md` files
- `claude`: Generates a single `CLAUDE.md` file
- `gemini`: Generates a single `GEMINI.md` file

## Source File Format

Place your master rule files in the `master-rules/` directory (or a custom directory specified with `--from`):

```markdown
---
description: "A description of the rule's purpose"
# Any other metadata fields
---

# Rule Title

Your rule content here...
```

## Requirements

- **Bash shell** (macOS or Linux)
- **Standard Unix utilities** (find, sed, awk, grep)

## Installation

1. Clone this repository or download the script
2. Make the script executable: `chmod +x scripts/sync-ide-rules.sh`
3. Run the script on your project

## License

This project is licensed under the MIT License.

## Support

If you find this tool helpful, consider supporting its development:

- [Buy Me a Coffee](https://buymeacoffee.com/pequet)
- [GitHub Sponsors](https://github.com/sponsors/pequet)

🧑‍💻

