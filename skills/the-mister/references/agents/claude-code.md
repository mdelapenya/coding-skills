# Claude Code

Named `claude-code.md` on purpose: `claude.md` resolves as `CLAUDE.md` on a case-insensitive filesystem and may be auto-loaded as project instructions.

## Models

| Tier | `model` | Display name for trailers |
|---|---|---|
| Hard | `opus` | Claude Opus 5 |
| Medium | `sonnet` | Claude Sonnet 5 |
| Easy, Git | `haiku` | Claude Haiku 4.5 (Git never signs) |

Trailer address: `<noreply@anthropic.com>`. The mister runs as Fable; never pass `fable` to a subagent. Record the `model` alias and `subagent_type` you passed in the node's evidence; the alias is sufficient, and no exact backend generation is claimed beyond this table.

## Shipped agents

Three definitions in this repository's root `agents/` directory: `coding-skills:the-mister`, `coding-skills:mechanic`, `coding-skills:git-operator` under the plugin, or `the-mister`, `mechanic`, `git-operator` when symlinked into `~/.claude/agents/`. Definitions load at session start.

| Agent | Tools | Enforced restriction |
|---|---|---|
| `the-mister` | Read, Grep, Glob, Agent, Write, Edit, SendMessage, AskUserQuestion, EnterPlanMode, ExitPlanMode | no shell |
| `mechanic` | Read, Grep, Glob, Edit, Write, Bash | cannot spawn |
| `git-operator` | Bash, Read | no dedicated edit tools; cannot spawn. "Never edit a file" is an instruction, since Bash can write |

`the-mister` is opt-in: add `context: fork` and `agent: the-mister` to the skill frontmatter. Plan-mode approval and `AskUserQuestion` must still reach the user from the fork; test it in your setup first. Engineers run on `general-purpose`, whose tools include `Agent` and `Bash`: their "never spawn, never run git" is an instruction, not an enforced restriction.

## Dispatch

One `Agent` call per ready node, all ready nodes in one message:

```
Agent(subagent_type: "general-purpose", model: "sonnet",
      description: "N02 add Widget model",
      prompt: <orders/N02-widget-model.md above the cut line>,
      run_in_background: true)
```

| Role | `subagent_type` | Without the shipped agents |
|---|---|---|
| Engineer | `general-purpose` | (built in) |
| Mechanic | `mechanic` | `general-purpose` with `model: "haiku"`; the preamble is then the only fence |
| Git operator | `git-operator` | `general-purpose` with `model: "haiku"`. Never `Explore`: its read-only persona may refuse `git switch` or `git push` |
| Explorer | `Explore` | (built in) read-only by construction; pass `model` explicitly |

Paste the order, do not summarise it: the worker has no other context. With `run_in_background: true` the harness notifies you as each finishes; do not poll. `SendMessage` continues a worker for a one-line clarification; a real order gap means revising the order and re-dispatching.

Never use `isolation: "worktree"` on `Agent` or the `EnterWorktree` tool: both run git outside a Git node, and disjoint ownership already makes per-agent worktrees unnecessary.
