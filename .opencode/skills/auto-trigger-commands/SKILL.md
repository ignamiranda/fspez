---
name: auto-trigger-commands
description: Auto-trigger OpenCode custom commands by adding behavioral instructions in AGENTS.md. Use when you want a custom command to run automatically on certain user input (e.g. /learn when user says "commit"). OpenCode config schema does NOT support a "trigger" property on commands.
---

# Auto-triggering Custom Commands in OpenCode

OpenCode's `command` config schema in `opencode.json` does **not** support a `trigger` or auto-run property. The only supported properties are `template`, `description`, `agent`, `model`, and `subtask`.

## How to auto-trigger a command

Add a behavioral instruction in `AGENTS.md` telling the model to proactively run the command when certain keywords are detected:

```markdown
## Auto-trigger: `/learn` on commit
Whenever the user says "commit" (or "git commit", "time to commit", etc.), automatically run the `/learn` command first to extract reusable knowledge from the session before the commit is performed.
```

## Why this works

The model reads `AGENTS.md` as part of its instructions and will proactively execute the specified command when it detects matching keywords in user input. This is the standard OpenCode pattern since there is no built-in trigger mechanism.
