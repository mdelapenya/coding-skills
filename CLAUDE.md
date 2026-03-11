# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository stores **reusable AI agent skills** for software development workflows. Skills follow the [Agent Skills open standard](https://agentskills.io/specification) and work across multiple AI platforms.

## Repository Layout

```
coding-skills/
├── skills/                    # Canonical skill definitions (single source of truth)
│   └── <skill-name>/
│       ├── SKILL.md           # Required: frontmatter + instructions
│       └── references/        # Optional: detailed docs (loaded on-demand)
├── .claude/skills -> ../skills    # Claude Code discovery
├── .agents/skills -> ../skills    # OpenAI Codex / GitHub Copilot
├── .github/skills -> ../skills    # GitHub Copilot
├── .gemini/skills -> ../skills    # Gemini CLI
├── .claude-plugin/plugin.json     # Claude plugin metadata
└── gemini-extension.json          # Gemini extension metadata
```

**All edits go in `skills/`** — the platform directories are symlinks. Never create files directly in `.claude/skills/`, `.agents/skills/`, `.github/skills/`, or `.gemini/skills/`.

## Skill Structure

### SKILL.md Format

```markdown
---
name: skill-name
description: What the skill does and when to use it. Include trigger phrases.
allowed-tools: Read Edit Grep Glob
metadata:
  author: mdelapenya
  version: "1.0.0"
---

# Skill Title

Instructions, workflows, and reference content.
```

### Frontmatter Fields

- **`name`** (required): Lowercase + hyphens only, 1-64 chars, must match directory name
- **`description`** (required): Used for auto-discovery — be specific, include trigger phrases (e.g., "Use when user says X, Y, Z")
- **`allowed-tools`**: Space-delimited pre-approved tools (e.g., `Read Grep Bash(python *)`)
- **`metadata`**: Key-value pairs for author, version, tags
- **`disable-model-invocation`**: Set `true` for manual-only skills (side-effect operations like deploy)
- **`user-invocable`**: Set `false` for background-knowledge-only skills (hidden from user menu)
- **`context: fork`**: Run in isolated subagent context
- **`agent`**: Subagent type when using `context: fork` (`Explore`, `Plan`, `general-purpose`)

## Authoring Conventions

### Naming
- Use gerund form: `processing-pdfs`, `managing-databases`, `writing-documentation`
- Avoid vague names: `helper`, `utils`, `tools`

### Descriptions
- Write in third person
- Include specific trigger conditions and example user phrases
- Mention what the skill does NOT do when disambiguation is needed (e.g., "Do NOT use for editing existing posts")

### Body Content
- Keep `SKILL.md` under 500 lines — move detailed reference to `references/` subdirectory
- Use progressive disclosure: link to reference files (one level deep only)
- Match instruction specificity to task fragility: high freedom for creative tasks, exact scripts for fragile operations
- Use workflow patterns: numbered steps, checklists (`- [ ]`), conditional branches

### Dynamic Context
- `$ARGUMENTS` / `$1`, `$2`... for invocation arguments
- `${CLAUDE_SESSION_ID}`, `${CLAUDE_SKILL_DIR}` for runtime context
- `` !`command` `` for command injection (output replaces placeholder before Claude sees it)

## Installation

Add this repo as a Claude Code plugin or symlink individual skills:

```bash
# As a plugin (all skills)
claude plugin add /path/to/coding-skills

# Individual skill
ln -s /path/to/coding-skills/skills/skill-name ~/.claude/skills/skill-name
```

## Testing

- Manual: `/skill-name [arguments]`
- Verify auto-discovery: describe a matching scenario and check if Claude triggers the skill
- Test across models (Haiku, Sonnet, Opus) — effectiveness varies by model capability
