---
type: guide
domain: methods
subject: Cursor Rules to Instructions
status: active
tags: notes-active
summary: "Explains the repository's context within the parent framework."
---

> [!NOTE]
> This document originates from a boilerplate template which may have evolved since this project was created. The latest version can be found in the [cursor-project-boilerplate repository](https://github.com/pequet/cursor-project-boilerplate/blob/main/docs/000-Framework-Context.md).

# Framework Context

This public repository, while fully functional on its own, is designed to serve as a **submodule** within a larger, homegrown and highly opinionated private framework for integrated thinking. The current document is thus a "convex mirror" looking out from the repository into the framework that gives it context.

For a standalone user, this information is optional. For the developer concerned with the system-level context, it is crucial, embodying the design principle: "when in doubt, zoom out."

## A Progressively Unfolding Structure

The parent framework's architecture is best understood by progressively unfolding its layers, from the highest level down to the specific location of this repository.

### Level 1: The `Core` and `Projects`

At the highest level, the entire system is divided into two main parts:

```text
Root/
├── Core/         # The stable, shared foundation
└── Projects/     # Modular "plugins" that extend the Core
```

-   **`Core`:** Contains the stable, foundational elements of the system. This public repository is part of the `Core`.
-   **`Projects`:** A collection of modular "plugins" that extend the `Core`. 

### Locating This Repository

Putting it all together, this public repository (`cursor-rules-to-instructions/`) is a `Method` within the `Core` folder.

```text
Core/
└─ Controllers/
   └── Methods/
        └── Operations/
            └── Scripts/
                └── IDE/
                    └── Convert Rules to Instructions/
                        ├── cursor-rules-to-instructions/  # This Public Repo
                        └── private/                       # Assets tracked by the parent framework
```

### Level 2: Split Repository Pattern

This path reveals a **Public-Private Pattern** at the `Convert Rules to Instructions` level, which separates the public-facing code (the submodule) from its private development assets (`private/`). These private assets, typically including `.cursor/`, `.specstory/`, `inbox/`, `memory-bank/` (and confidential files) are thus allowed to be informed and tracked by the parent framework, not the public submodule.

```text
Convert Rules to Instructions/                   # Grouping
├── cursor-rules-to-instructions/                # This Public Repo (contains symlinks to the private assets)
│   ├── .cursor -> ../private/.cursor/
│   ├── .specstory -> ../private/.specstory/
│   ├── inbox -> ../private/inbox/
│   ├── memory-bank -> ../private/memory-bank/
│   ├── archives/
│   ├── docs/
│   ├── scripts/
│   └── src/
└── private/                                     # Assets tracked by the parent framework
    ├── .cursor/
    ├── .specstory/
    ├── inbox/
    └── memory-bank/
```

This organization allows for a clean public repository while maintaining a rich, private context for development, and the ability to switch between the two contexts seamlessly.

## Development Principles

This layered structure enables a powerful and organized development workflow guided by three key principles:

-   **Inbox-Driven Development:** All new ideas, notes, tasks, and raw information related to this project are first captured in the parent `Models/0. Inbox/` and then moved to the public repository `cursor-rules-to-instructions/inbox/`. This keeps the public repository clean while ensuring no idea is lost.
-   **Archival Over Deletion:** Following a "never delete" principle, files are moved to the `cursor-rules-to-instructions/archives/` or back to the parent `Models/4. Archives/` instead of being deleted. This preserves a complete history of the project's evolution.
-   **Private Asset Management:** The sibling `private/` directory stores development artifacts (`.cursor/`, `.specstory/`, `inbox/`, `memory-bank/`) that are essential for development and should be versioned in the private parent repository, but are not part of the public-facing submodule. 
