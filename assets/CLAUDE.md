# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

<!-- 🔧 BEGIN REPLACE Brief project description for Claude Code context -->
Example web app: "A modern React web application for managing customer relationships with real-time updates"
Example API service: "RESTful API service built with Node.js for handling e-commerce transactions"
Example CLI tool: "Command-line tool for automating DevOps workflows and deployment processes"
Example data pipeline: "Python-based data processing pipeline for analytics and reporting"
<!-- 🔧 REPLACE END -->

This project follows a structured architecture and has specific conventions that you should follow when providing assistance. Please refer to the companion documentation for more context:

- [AGENTS.md](AGENTS.md) - Quick-start guide for working with this codebase (200-400 words, optimized for Codex CLI)
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture and components
- [RULES.md](RULES.md) - Index of all rules and their implementations

## External Tools & Context

<!-- 🔧 BEGIN REPLACE List any external tools, APIs, or services Claude should be aware of -->
Example development tools: Docker for containerization, Make for build automation, Git hooks for quality checks
Example APIs: Stripe for payments, SendGrid for emails, Auth0 for authentication
Example services: PostgreSQL database, Redis cache, AWS S3 storage
Example monitoring: Sentry for error tracking, DataDog for metrics, LogRocket for user sessions
Example deployment: Kubernetes cluster, GitHub Actions CI/CD, Terraform infrastructure

### Development Tools
- Build System: Webpack/Vite with hot reload
- Package Manager: npm/yarn with lock files
- Code Quality: ESLint, Prettier, Husky git hooks

### External APIs & Services  
- Authentication: OAuth 2.0 with JWT tokens
- Database: PostgreSQL with Prisma ORM
- Storage: AWS S3 for file uploads

### Deployment & Infrastructure
- Containerization: Docker with multi-stage builds
- Orchestration: Kubernetes with Helm charts
- CI/CD: GitHub Actions with automated testing
<!-- 🔧 REPLACE END -->

## Development Rules

The following rules should be applied when working with this codebase:

