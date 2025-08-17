# Convert Cursor Rules to GitHub Copilot Instructions

> In the beginning, Cursor created an AI-powered IDE and said "Let there be unlimited requests." And developers saw that it was good. They invested time creating custom rules, perfecting workflows, and paying subscription fees.
> Then Cursor declared that "unlimited" actually meant "500 requests per month" and that many included features would now count as requests. And the developers were sad.
> This script will translate your Cursor rules into GitHub Copilot instructions faster than you can say "my subscription was devalued again!"

A utility script that converts your existing Cursor IDE rules into GitHub Copilot instructions, allowing you to preserve your custom AI assistant training when transitioning between tools.

Whether you're exploring alternatives due to recent changes in Cursor's pricing model or simply want to use your rules across multiple platforms, this script helps you maintain consistency in your AI-assisted development workflow.

## Features

- **Simple conversion**: Transforms `.cursor/rules/*.mdc` files into `.github/instructions/*.instructions.md` files
- **Preserves formatting**: Maintains your original rule structure and content
- **Quick setup**: One command to convert your entire project
- **Cross-platform**: Works on macOS and Linux systems

## Usage

Convert your Cursor rules by running the script with your project path:

```bash
./convert-cursor-rules.sh /path/to/my/project
```

**Examples:**

```bash
# Convert rules in the current directory
./convert-cursor-rules.sh .

# Convert rules in a specific project
./convert-cursor-rules.sh /path/to/my/project
```

The script will automatically:
1. Scan for `.cursor/rules/*.mdc` files in your project
2. Create the `.github/instructions/` directory if it doesn't exist
3. Convert each rule file to the appropriate GitHub Copilot instruction format
4. Preserve your original files (no data is lost)

## Requirements

- **Bash shell** (macOS or Linux)
- **Existing Cursor rules** in your project (`.cursor/rules/*.mdc` files)
- A sense of humor about subscription services

## Installation

1. Clone this repository or download the script
2. Make the script executable: `chmod +x convert-cursor-rules.sh`
3. Run the script on your project

## License

This project is licensed under the MIT License.

## Support

If you find this tool helpful, consider supporting its development:

- [Buy Me a Coffee](https://buymeacoffee.com/pequet)
- [GitHub Sponsors](https://github.com/sponsors/pequet)

🧑‍💻

