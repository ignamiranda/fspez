---
name: learn
description: Extract reusable knowledge from the current session and encode it as agent skills. Creates new skills, updates existing ones, and fixes skill triggers. Use when user invokes /learn, says "learn", "extract skill", "save this knowledge", or on commit (auto-triggered via AGENTS.md).
---

# /learn — Extract Skills from Session

## Process (run in order)

### 1. Scan session for patterns
Analyze the conversation for:
- **Problems solved** — bugs fixed, errors overcome, workarounds found
- **Domain knowledge** — architecture decisions, API quirks, environment specifics
- **Workflows** — multi-step sequences the user repeated or documented
- **Conventions** — coding patterns, naming, file layout, testing styles
- **Commands** — build/test/lint commands and how they're used

### 2. Check existing skills
Read every `.opencode/skills/*/SKILL.md`. For each:
- Does this session's knowledge overlap? → Update the skill with new info
- Was this skill's description too narrow to trigger when it should have? → Expand the `Use when` triggers
- Was this skill loaded but not useful? → Narrow its triggers

### 3. Identify untriggered skills
For each existing skill, ask: "Was there anything in this session where this skill would have helped?" If yes, the description missed the trigger — expand it with the matching keywords from this session.

### 4. Create new skills
If the session revealed knowledge not covered by any existing skill:
- Create `.opencode/skills/<name>/SKILL.md` following the `write-a-skill` skill's template (load it with the skill tool)
- Include `name` and `description` frontmatter with clear triggers
- Keep SKILL.md under 100 lines; split into REFERENCE.md if longer

### 5. Update AGENTS.md
If the session revealed commands, constraints, or architecture facts not in AGENTS.md, update that file too.

## What to extract

| Session content | Skill output |
|----------------|--------------|
| "I kept getting 403 until I added X-Modhash" | New skill or update to existing auth skill |
| "Run `npm run build:windows` not `npm run build`" | Fix AGENTS.md Commands section |
| "The repo uses provider pattern, not BLoC" | Add architecture note to AGENTS.md |
| "I always forget to set `CI=true` before running tests" | Add to skill or AGENTS.md |

## What NOT to extract

- One-time setup steps (auth tokens, installs)
- User-specific preferences (editor, theme)
- Session-specific data (bug IDs, temp file paths)
- Trivial or well-known facts (what is a loop, how to use git)
