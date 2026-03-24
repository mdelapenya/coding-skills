# Coding Skills

Reusable AI agent skills for software development workflows.

## Skills

| Skill | Purpose | Trigger phrases |
|---|---|---|
| **babysit-pr** | Monitor CI builds and merge conflicts for a PR, diagnose failures, merge main, and push fixes | "babysit this PR", "check CI", "fix the build", "why is CI failing", "resolve conflicts" |
| **ci-detective** | Investigate CI failures by cross-referencing against other recent runs to determine if failures are pre-existing or introduced by the PR | "investigate CI failure", "is this test flaky", "why is this test failing", "ci detective" |
| **describe-pr** | Generate a concise PR description from a GitHub pull request diff | "describe this PR", "add PR description", "fill in PR body", "summarize PR changes" |
| **pr-lawyer** | Address PR review comments by fixing valid feedback or challenging debatable ones with a reasoned argument | "address PR comments", "respond to review", "challenge this comment", "fight back on review", "pr lawyer" |

## Platform Support

These skills work with multiple AI coding agents. The repo includes symlinks for automatic discovery:

| Platform | Discovery path | How to install |
|---|---|---|
| **Claude Code** | `.claude/skills/` | Clone repo, or install as plugin |
| **GitHub Copilot** | `.github/skills/` | Clone repo into your project |
| **OpenAI Codex** | `.agents/skills/` | Clone repo into your project |
| **Gemini CLI** | `.gemini/skills/` or `.agents/skills/` | Clone repo, or install as extension |

All four paths are symlinks to the canonical `skills/` directory, so skills stay in sync.

## Quick Start

### Option 1: Clone into your project

```bash
git clone https://github.com/mdelapenya/coding-skills.git
```

The symlinks inside the repo handle platform discovery automatically.

### Option 2: Copy skills to your agent's discovery path

```bash
# For Claude Code
cp -r skills/* ~/.claude/skills/

# For Copilot
cp -r skills/* .github/skills/

# For Codex
cp -r skills/* .agents/skills/

# For Gemini CLI
cp -r skills/* .gemini/skills/
```

### Option 3: Symlink for single source of truth

```bash
REPO=/path/to/coding-skills/skills

# Claude Code (user-global)
ln -s $REPO/babysit-pr ~/.claude/skills/babysit-pr
ln -s $REPO/ci-detective ~/.claude/skills/ci-detective
ln -s $REPO/describe-pr ~/.claude/skills/describe-pr
ln -s $REPO/pr-lawyer ~/.claude/skills/pr-lawyer
```

## Repo Structure

```
coding-skills/
├── skills/                          # Canonical skill files
│   ├── babysit-pr/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── github.md
│   ├── ci-detective/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── github-actions.md
│   ├── describe-pr/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── github.md
│   └── pr-lawyer/
│       ├── SKILL.md
│       └── references/
│           ├── github.md
│           └── gitlab.md
├── .agents/skills -> ../skills      # Codex + Gemini CLI
├── .claude/skills -> ../skills      # Claude Code
├── .github/skills -> ../skills      # Copilot
├── .gemini/skills -> ../skills      # Gemini CLI
├── .claude-plugin/
│   └── plugin.json                  # Claude Code plugin manifest
├── gemini-extension.json            # Gemini CLI extension manifest
└── README.md
```

## License

MIT
