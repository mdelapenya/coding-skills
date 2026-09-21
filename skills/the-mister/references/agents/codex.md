# OpenAI Codex

Not yet exercised end to end. The dispatch example below matches the `collaboration.spawn_agent` schema observed in one Codex session (2026-09); read the actual tool schema and model list in your Codex before dispatching.

## Models

| Tier | `model` | `reasoning_effort` | Display name for trailers |
|---|---|---|---|
| Hard | `gpt-5.6-sol` | `high` | GPT-5.6 Sol |
| Medium | `gpt-5.6-terra` | `medium` | GPT-5.6 Terra |
| Easy, Git | `gpt-5.6-luna` | `low` | GPT-5.6 Luna (Git never signs) |

Trailer address: whatever your organisation uses for agent commits. The mister runs as Astra; never spawn it. Record the `model` you passed (or the role's configured model) in the node's evidence; a role name alone identifies a role, not a model.

## Dispatch

`spawn_agent` takes `task_name`, `message`, `fork_turns`, `model`, and `reasoning_effort`. There is no `agent_type`. Task names use underscores, so the DAG node id lives inside the order text.

```json
{
  "task_name": "n02_widget_model",
  "message": "<the order above the cut line, preamble included>",
  "fork_turns": "none",
  "model": "gpt-5.6-terra",
  "reasoning_effort": "medium"
}
```

`fork_turns` must be `"none"`: a model override requires a non-full-history fork, and a clean slate keeps the mister's context out of the worker. Call `wait_agent` on the running set; it returns on the first completion. Accept that node, then spawn whatever became ready. Readiness, not waves.

## Optional worker configuration

Standalone agent TOMLs ([documentation](https://learn.chatgpt.com/docs/agent-configuration/subagents)) take `name`, `description`, and `developer_instructions`, and may set `model` and `model_reasoning_effort`. Use one only when it adds something the direct call cannot, for example a pinned Git operator:

```toml
name = "luna-git"
description = "Runs git, gh, and glab commands exactly as written. Never edits files, never types a commit message."
model = "gpt-5.6-luna"
model_reasoning_effort = "low"
developer_instructions = """
<Git operator preamble from references/plan-and-orders.md, verbatim>
"""
```

`agents.enabled = false` is the documented switch for a worker's multi-agent tools; whether it enforces no-spawn for a subagent is unverified. Until it is, the preamble's "never spawn" is an instruction, not a fence.

## Sandbox

Sandboxed sessions may be offline. Fetch, push, and `gh` need network; an offline Git node is an environment failure to report to the user, never something to simulate.
