# AGENTS.md

This document provides a quick-start guide for both humans and AI agents working with this codebase.

TARGET LENGTH: 200-400 words (optimized for quick consumption by both humans and AI agents)

## Structure
<!-- 🔧 BEGIN REPLACE Describe your actual project structure in 2-3 sentences -->
Example modular: "Code is organized in feature-based modules with clear separation of concerns"
Example layered: "Three-tier architecture with presentation, business logic, and data access layers"
Example domain-driven: "Domain-driven design with bounded contexts and aggregate roots"
<!-- 🔧 REPLACE END -->

## Commands
<!-- 🔧 BEGIN REPLACE List your actual project commands - keep concise, only essential commands -->
Example npm: npm run build, npm test, npm start, npm run lint
Example make: make build, make test, make deploy, make clean
Example custom: ./scripts/build.sh, ./scripts/test.sh, ./scripts/deploy.sh
<!-- 🔧 REPLACE END -->

## Coding Style
<!-- 🔧 BEGIN REPLACE List your actual coding standards -->
Example linting: ESLint with Airbnb config, Prettier for formatting
Example documentation: JSDoc for public APIs, inline comments for complex logic
Example naming: camelCase for variables, PascalCase for classes, kebab-case for files
Example patterns: Functional programming preferred, immutable data structures
<!-- 🔧 REPLACE END -->

## Testing
<!-- 🔧 BEGIN REPLACE Describe your testing approach -->
Example unit testing: Jest for unit tests, 80%+ code coverage required
Example integration: Supertest for API testing, TestContainers for database tests
Example e2e: Cypress for end-to-end testing, Playwright for cross-browser testing
Example practices: TDD encouraged, tests must pass before PR merge
<!-- 🔧 REPLACE END -->

## Commit/PR
<!-- 🔧 BEGIN REPLACE Document your actual Git workflow -->
Example conventional commits: feat:, fix:, docs:, style:, refactor:, test:
Example branching: feature/ticket-123, bugfix/issue-456, hotfix/critical-789
Example PR process: Squash merge preferred, linear history maintained
Example review: Two approvals required, automated checks must pass
<!-- 🔧 REPLACE END -->

## AI Assistants & IDEs
For more detailed guidance, see the specialized files for each AI assistant:
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture and components
- [RULES.md](RULES.md) - Index of all rules and their implementations
- [CLAUDE.md](CLAUDE.md) - Claude Code specific guidance (aggregated single file)
- [GEMINI.md](GEMINI.md) - Gemini CLI specific guidance (comprehensive single file)
- [README.md](README.md) - Project overview and setup instructions

<!-- Additional AI assistant integration notes -->
 This project maintains synchronized rules across multiple AI coding assistants:
 - **Cursor IDE**: Individual rules in `.cursor/rules/` directory
 - **GitHub Copilot**: Individual instructions in `.github/instructions/` directory
 - **Claude Code**: Aggregated guidance in single `CLAUDE.md` file
 - **Codex CLI**: Quick-start documentation in this `AGENTS.md` file
 - **Gemini CLI**: Comprehensive guidance in single `GEMINI.md` file
