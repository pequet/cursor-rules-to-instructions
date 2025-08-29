# RULES.md

This document provides an index of all coding rules and their derived implementations for different AI assistants.

## Rule Sources and Derived Files

The rules in this project follow a source → derived pattern where canonical rules in `master-rules/` are converted to various formats for different AI assistants:

### Source Files
- `master-rules/*.md`: Canonical rule definitions (single source of truth)

### Derived Files - AI Assistant Specific
- **Claude Code**: `CLAUDE.md` - Aggregated single file with companion docs and external tools
- **Codex CLI**: Documentation files (`AGENTS.md`, `ARCHITECTURE.md`, `RULES.md`) for general AI assistant reference
- **Cursor IDE**: `.cursor/rules/*.mdc` files with `globs`/`alwaysApply` frontmatter
- **Gemini CLI**: `GEMINI.md` - Comprehensive single file with embedded quickstart and architecture, all rules under H2 headings
- **GitHub Copilot**: `.github/instructions/*.instructions.md` files with `applyTo` frontmatter  

## AI Assistant Behavior & Rationale

### Cursor IDE
- **File Pattern**: Individual `.mdc` files in `.cursor/rules/`
- **Loading**: Uses `globs` and `alwaysApply` frontmatter to determine when to apply rules
- **Example**: `globs: "*.js"` applies to JavaScript files only; `alwaysApply: true` applies to all files
- **Rationale**: Cursor works best with modular, file-specific rules that can be selectively applied

### GitHub Copilot
- **File Pattern**: Individual `.instructions.md` files in `.github/instructions/`
- **Loading**: Uses `applyTo` frontmatter to determine scope
- **Example**: `applyTo: "*,**/*"` applies to all files
- **Rationale**: Copilot's instruction system expects individual files with clear scope definitions

### Claude Code
- **File Pattern**: Single aggregated `CLAUDE.md` file
- **Loading**: Processes entire file as context
- **Content**: Includes companion docs, external tools context, and all rules
- **Rationale**: Claude Code works best with comprehensive, single-file contexts that include all relevant information

### Gemini CLI
- **File Pattern**: Single comprehensive `GEMINI.md` file
- **Loading**: Processes entire file, expects H2 headings for rule organization
- **Content**: Embedded quickstart guide, architecture overview, and all rules under H2 headings
- **Rationale**: Gemini CLI performs better with long, comprehensive single-file approaches with clear hierarchical structure

### Codex CLI (General AI Reference)
- **File Pattern**: Documentation files (`AGENTS.md`, `ARCHITECTURE.md`, `RULES.md`)
- **Loading**: Referenced as companion documentation
- **Content**: `AGENTS.md` optimized for 200-400 words as entry point
- **Rationale**: Serves as general-purpose documentation for any AI assistant, with `AGENTS.md` as the primary entry point

<!-- 🔧 BEGIN REPLACE Any project-specific rule maintenance notes -->
Example custom workflows: Integration with pre-commit hooks, automated rule validation
Example team practices: Rule review process, naming conventions for rule files
Example monitoring: Tracking rule effectiveness, A/B testing different rule approaches
Example documentation: Maintaining rule changelog, documenting rule rationale
<!-- 🔧 REPLACE END -->
