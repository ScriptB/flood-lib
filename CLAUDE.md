# Operational Guidelines

## Pre-Flight
- Consult ARCHITECTURE.md to locate file paths before searching.
- Consult ctx/index.md for task-specific rules and read indicated ctx/ files.

## Code Rules
- Zero comments: no inline, block, or trailing comments. Code is self-documenting via clear names and short functions.
- Micro-refactoring: refactor touched code incrementally (flatten conditionals, extract functions <25 lines). No monolithic refactors.
- Living map: update ARCHITECTURE.md and ctx/index.md whenever adding or moving files.

## Reading & Output
- View targeted line ranges, not full large files.
- Be concise. Output minimal text, direct diffs, no conversational fluff.

## Post-Audit
- Verify zero comments in modified code before finishing.
- Verify ARCHITECTURE.md reflects any new files.

## Project
Flood is a Roblox UI library with a fluent design language, spring/tween animation engine, centralized theme system, and modular component architecture. It targets executor script environments and syncs to Roblox via Rojo (`default.project.json`).
