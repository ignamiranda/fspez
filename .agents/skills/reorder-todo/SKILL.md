---
name: reorder-todo
description: Renumber ranked handoff entries in TODO.md sequentially. Use after inserting or removing a handoff line in TODO.md to fix numbering without manual editing.
---

# Reorder TODO

Renumbers all `N. ` entries under `## Ranked handoffs` in `TODO.md` sequentially from 1, preserving all other content (blank lines, notes, section headers).

## Usage

```pwsh
pwsh .agents/skills/reorder-todo/scripts/reorder-todo.ps1
```

## Workflow

1. Open `TODO.md` and insert or remove a handoff entry at the correct position (use your judgment for importance ranking)
2. Don't worry about the number — leave it as any placeholder (e.g. `0. `)
3. Run the script
4. Verify the output — all entries are renumbered sequentially

## How it works

The script:
- Finds all lines matching `^\d+. ` under the `## Ranked handoffs` section
- Renumbers them from 1 in document order
- Preserves blank lines, notes, section headers, and non-numbered content
- Writes TODO.md in-place
