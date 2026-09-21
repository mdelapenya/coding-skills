# Coding Skills

Reusable AI agent skills for software development workflows.

## Skills

| Skill | Purpose | Trigger phrases |
|---|---|---|
| **ci-detective** | Investigate CI failures by cross-referencing against other recent runs to determine if failures are pre-existing or introduced by the PR | "investigate CI failure", "is this test flaky", "why is this test failing", "ci detective" |
| **pr-lawyer** | Address PR review comments by fixing valid feedback or challenging debatable ones with a reasoned argument | "address PR comments", "respond to review", "challenge this comment", "fight back on review", "pr lawyer" |
| **pr-nurse** | Monitor CI builds and merge conflicts for a PR, diagnose failures, merge main, and push fixes | "nurse this PR", "check CI", "fix the build", "why is CI failing", "resolve conflicts" |
| **pr-reviewer** | Multi-pass adversarial review of a pull request that challenges its own findings to drop false positives, designed to be looped until findings converge | "review this PR", "adversarial review", "deep PR review", "audit this pull request", "pr reviewer" |
| **pr-scribe** | Generate a concise PR description from a GitHub pull request diff | "describe this PR", "add PR description", "fill in PR body", "summarize PR changes" |
| **the-mister** | Plan an implementation as a DAG and dispatch every node to a cheaper subagent by difficulty (Opus/Sol, Sonnet/Terra, Haiku/Luna), with all git operations always on Haiku/Luna; the mister only orchestrates and verifies | "orchestrate this", "plan and delegate", "use the squad", "mister", "ask the mister", "delegate to cheaper models" |

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

**macOS / Linux:**

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

**Windows (PowerShell):**

```powershell
Copy-Item -Recurse skills\* "$env:USERPROFILE\.claude\skills\"
```

### Option 3: Symlink for single source of truth

**macOS / Linux:**

```bash
REPO=/path/to/coding-skills/skills

# Claude Code (user-global)
ln -s $REPO/ci-detective ~/.claude/skills/ci-detective
ln -s $REPO/pr-lawyer ~/.claude/skills/pr-lawyer
ln -s $REPO/pr-nurse ~/.claude/skills/pr-nurse
ln -s $REPO/pr-reviewer ~/.claude/skills/pr-reviewer
ln -s $REPO/pr-scribe ~/.claude/skills/pr-scribe
ln -s $REPO/the-mister ~/.claude/skills/the-mister

# Agents used by the-mister (Claude Code reads ~/.claude/agents/ at session start)
mkdir -p ~/.claude/agents
ln -s $REPO/../agents/git-operator.md ~/.claude/agents/git-operator.md
ln -s $REPO/../agents/mechanic.md ~/.claude/agents/mechanic.md
ln -s $REPO/../agents/the-mister.md ~/.claude/agents/the-mister.md
```

**Windows (PowerShell):**

True symlinks require admin rights or Developer Mode. Use directory junctions instead — they don't need admin and the harness follows them transparently:

```powershell
$repo = "C:\path\to\coding-skills\skills"
$home_skills = "$env:USERPROFILE\.claude\skills"

foreach ($n in 'ci-detective','pr-lawyer','pr-nurse','pr-reviewer','pr-scribe','the-mister') {
    New-Item -ItemType Junction -Path (Join-Path $home_skills $n) -Target (Join-Path $repo $n)
}
```

## Repo Structure

```
coding-skills/
├── skills/                          # Canonical skill files
│   ├── ci-detective/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── github-actions.md
│   │       └── gitlab-ci.md
│   ├── pr-lawyer/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── github.md
│   │       └── gitlab.md
│   ├── pr-nurse/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── github.md
│   │       └── gitlab.md
│   ├── pr-reviewer/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── agents/
│   │           ├── claude-code.md
│   │           ├── codex.md
│   │           ├── copilot.md
│   │           ├── gemini.md
│   │           └── generic.md
│   ├── pr-scribe/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── biomelab.md
│   │       ├── github.md
│   │       └── gitlab.md
│   └── the-mister/
│       ├── SKILL.md
│       └── references/
│           ├── plan-and-orders.md
│           └── agents/
│               ├── claude-code.md
│               ├── codex.md
│               └── generic.md
├── agents/                          # Claude Code agent definitions (plugin-discovered)
│   ├── git-operator.md              # the-mister: every Git node
│   ├── mechanic.md                  # the-mister: Easy nodes
│   └── the-mister.md                # the-mister: optional no-Bash orchestrator (context: fork)
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
