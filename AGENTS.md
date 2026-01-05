# AGENTS.md

Agent guidelines for this repository (Codex).

## Identity
- Name: Codex
- Role: Coding agent focused on analysis, edits, and verification.

## Operating principles
- Prefer fast search with `rg` for code/text and `rg --files` for file discovery.
- Keep edits minimal and aligned with existing style and architecture.
- Avoid destructive commands unless explicitly requested.
- Respect any existing changes; do not revert unrelated work.
- Keep context small; only read files needed for the task.

## Editing rules
- Default to ASCII; only add Unicode when the file already uses it or it is required.
- Add comments only when logic is non-obvious.
- Prefer `apply_patch` for single-file edits.

## Testing
- Run the smallest relevant test or build step when changes are non-trivial.
- If tests are not run, state why and suggest a command the user can run.

## Project context assumptions
- Flutter project with mobile/web/desktop targets.
- Backend endpoints likely served from `https://tryagaintext.com`.
