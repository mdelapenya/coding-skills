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

Five definitions in this repository's root `agents/` directory: `coding-skills:the-mister`, `coding-skills:engineer`, `coding-skills:reviewer`, `coding-skills:mechanic`, `coding-skills:git-operator` under the plugin, or `the-mister`, `engineer`, `reviewer`, `mechanic`, `git-operator` when symlinked into `~/.claude/agents/`. Definitions load at session start.

| Agent | Tools | Enforced by the tool list | Instruction only |
|---|---|---|---|
| `the-mister` | Read, Grep, Glob, Agent, Write, Edit, SendMessage, AskUserQuestion, EnterPlanMode, ExitPlanMode | no shell | writes only under its state directory |
| `engineer` | Read, Grep, Glob, Edit, Write, Bash | cannot spawn | never runs git; edits only owned files |
| `reviewer` | Read, Grep, Glob | cannot spawn; no edit tools and no shell, so read-only and git-free | reviews against the request only; reports counterexamples rather than fixing |
| `mechanic` | Read, Grep, Glob, Edit, Write, Bash | cannot spawn | never runs git; edits only owned files |
| `git-operator` | Bash(git *), Bash(gh *), Bash(glab *), Read | cannot spawn; no edit tools; non-git commands that write are denied (observed: `touch`, and `>` redirection on a git command) | runs only the listed commands; never summarises output. Read-only non-git commands such as `ls` were observed to run, and git itself can write (`--output`, `commit`, `switch`) |

The `git-operator` row is from a test, not the documentation: the subagent docs (https://code.claude.com/docs/en/sub-agents.md) define `tools` as a list of tool names and say nothing about `Bash(<pattern>)` entries there; they say a `disallowedTools` entry with a pattern removes the whole tool. On Claude Code 2.1.284, a project-scope agent with `tools: Bash(git *), Read` run under `bypassPermissions` ran `git status` and `ls -la` and was denied `touch`; in a second run it was denied `git status --short > file` and stopped there, so a non-git command chained after `&&` is untested. Only project scope was tested; plugin scope is assumed to behave the same because `tools` is not among the fields plugin agents ignore. Under `default` mode the same agent still asked for approval for `git status`: the pattern narrows Bash, it grants nothing. Re-test after a Claude Code upgrade. Plugin agents ignore `hooks`, `mcpServers`, and `permissionMode` (same page), so a `PreToolUse` hook cannot tighten the plugin copy further.

`the-mister` is opt-in: add `context: fork` and `agent: the-mister` to the skill frontmatter. Plan-mode approval and `AskUserQuestion` must still reach the user from the fork; test it in your setup first. Without the shipped agents, engineers fall back to `general-purpose`, whose tools include `Agent`: "never spawn" is then an instruction too.

## Dispatch

One `Agent` call per ready node, all ready nodes in one message:

```
Agent(subagent_type: "engineer", model: "sonnet",
      description: "N02 add Widget model",
      prompt: <orders/N02-widget-model.md above the cut line>,
      run_in_background: true)
```

| Role | `subagent_type` | Without the shipped agents |
|---|---|---|
| Engineer (Hard, Medium) | `engineer`, with `model` set by tier | `general-purpose` with `model` set by tier; the preamble is then the only fence against spawning |
| Reviewer (step 7) | `reviewer`, with `model` set by tier (Hard by default; Medium only with the written reason) | `general-purpose` with the same `model`; read-only is then only the preamble. Not `Explore`: its one-question persona is too narrow for a whole-change review |
| Mechanic | `mechanic` | `general-purpose` with `model: "haiku"`; the preamble is then the only fence |
| Git operator | `git-operator` | `general-purpose` with `model: "haiku"`; the preamble is then the only fence. Never `Explore`: its read-only persona may refuse `git switch` or `git push` |
| Explorer | `Explore` | (built in) read-only by construction; pass `model` explicitly |

Paste the order, do not summarise it: the worker has no other context. With `run_in_background: true` the harness notifies you as each finishes; do not poll. `SendMessage` continues a worker for a one-line clarification; a real order gap means revising the order and re-dispatching.

Never use `isolation: "worktree"` on `Agent` or the `EnterWorktree` tool: both run git outside a Git node, and disjoint ownership already makes per-agent worktrees unnecessary.
