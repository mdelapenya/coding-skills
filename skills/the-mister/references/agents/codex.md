# OpenAI Codex

An accepted Codex run on 2026-09-21 exercised 21 worker invocations, parallel nodes, preflight, and commit. It did not exercise retries after a bad order or implementation defect, the dirty-baseline stop, push, or PR creation. The revised adapter below was checked against the `collaboration` tool schemas exposed on 2026-10-25 and the official documentation linked below; it has not been re-exercised end to end. Read your runtime's actual schemas and model list before dispatching.

## Models

Example tier mapping checked on 2026-10-25 against official documentation and the session's advertised model overrides; availability and substitutions must be checked again at the start of each run:

| Tier | `model` | `reasoning_effort` | Trailer name (exact model id) |
|---|---|---|---|
| Hard | `gpt-6.1-sol` | `high` | `gpt-6.1-sol` |
| Medium | `gpt-5.6-terra` | `medium` | `gpt-5.6-terra` |
| Easy, Git | `gpt-6-luna` | `low` | `gpt-6-luna` (Git never signs) |

Sol and Luna ids and efforts were advertised by that session's `collaboration.spawn_agent` schema. [Official model documentation](https://learn.chatgpt.com/docs/models) lists GPT-5.6 Terra as available during the rollout; its [model reference](https://developers.openai.com/api/docs/models/gpt-5.6-terra) supports `medium` reasoning effort. Terra was not advertised for subagent dispatch in that particular session; that does not establish its removal from Codex. Record the runtime's actual list, chosen mapping, every substitution, and every missing tier under Assumptions. If the runtime exposes no list, record that limitation and use only explicitly advertised choices; do not invent a model-discovery command.

When a tier is unavailable, move up one tier, never down, and state both the intended tier and the effective tier/model in the order. If the runtime does not offer Terra, a Medium order says "Medium unavailable; dispatched at Hard on gpt-6.1-sol". If no eligible model exists for Hard, report the limitation instead of assigning the mister or downgrading. Git remains a Git-role order even when its model must move up.

Trailer address: whatever your organisation uses for agent commits. Use the exact recorded model id as the trailer name unless a verified display name is available; do not manufacture one by expanding the id. The mister runs as Astra; never spawn it. Record the model and effort explicitly requested, plus any known configuration override, in the node's evidence. A role name or worker self-description is not model identity; if the effective model is unknown, say so.

## Capability check

Before adopting the shared workflow, check which tools this client actually exposes. Claude's `allowed-tools` frontmatter and this repository's `agents/*.md` are not evidence that a Codex worker has restricted tools.

Use direct file-reading/search tools when available. Otherwise dispatch read-only evidence collection to workers: literal listing, reading, or searching is Easy; interpretation uses the appropriate tier. Require the requested file contents or matches verbatim, with paths and line numbers; fetch chunks when necessary instead of accepting a summary as the file. This also applies to reading state on resume and inspecting captures. Every git-related operation still goes to a Git node.

Write the approved plan and orders through a non-shell file tool, such as `apply_patch`, restricted to the state directory. Shell-only reading is therefore not itself a reason to stop: workers can supply the reads while the mister persists state without executing commands. If no non-shell state-writing tool is available either, report that specific limitation with an inline plan and orders. The September run establishes workflow coverage, not which file-access mechanism a current client exposes; do not infer that mechanism from its success.

Use the client's available planning and user-input controls; do not invent `EnterPlanMode` or `ExitPlanMode` calls. Approval still means an actual user response or existing session authorization, never a timeout or an unanswered question.

## Dispatch

In the observed `collaboration` schema, `spawn_agent` takes `task_name`, `message`, `fork_turns`, `model`, and `reasoning_effort`. There is no `agent_type` or custom-agent selector. Task names use underscores, so the DAG node id lives inside the order text.

Example for a Medium node promoted to Hard because Medium is unavailable:

```json
{
  "task_name": "n02_widget_model",
  "message": "<complete order above the cut line, canonical preamble included; state the Medium-to-Hard substitution>",
  "fork_turns": "none",
  "model": "gpt-6.1-sol",
  "reasoning_effort": "high"
}
```

Use `fork_turns: "none"` with model/effort overrides in this schema. Inline the canonical preamble, all needed context, and applicable user and repository constraints in the order; a clean fork must not depend on inherited conversation. Include relevant execution restrictions, verification requirements, and file-ownership boundaries explicitly rather than relying on a worker to know private instructions.

Call `collaboration` tools directly when the runtime requires it. Respect the slot limit your runtime advertises, including whether it counts the primary agent. Queue excess ready nodes without changing dependencies or overlapping ownership.

`wait_agent` can return for mailbox activity, user input, or a timeout; its summary is not the worker's report and does not prove completion. Read the delivered report and confirm status before accepting a node. Accept each completed node, then dispatch newly ready work: readiness, not waves. Prefer waits up to 60 seconds so progress updates remain possible.

For a missing verbatim Git report, use the runtime's continuation mechanism on the same worker to request it once. Check that it starts an idle worker: for example, the observed schema provides `followup_task`, whereas `send_message` alone only queues a message. An order gap requires revising the order and logging another dispatch. An interruption is not evidence that a command completed; reconcile before retrying mutations.

## Enforcement and optional configuration

| Restriction | Observed direct-dispatch guarantee |
|---|---|
| Engineer/mechanic cannot spawn or run git | Instruction only; no per-worker tool allowlist argument |
| Git operator obeys file-write restrictions and runs only listed commands | Instruction only; a shell can write files; listed output-file exceptions follow the canonical preamble |
| Explorer/diagnosis node is read-only | Instruction only; the role text does not remove write tools |
| Mister cannot execute commands or edit outside state | Instruction only when those tools remain exposed |
| Git output is verbatim | Acceptance criterion; tools do not enforce report wording |

[Official subagent documentation](https://learn.chatgpt.com/docs/agent-configuration/subagents) describes standalone custom-agent TOMLs, model overrides, and capability switches. Custom files can override a requested model or effort; account for them in evidence. They inherit parent permissions, so an explorer persona is not a separate read-only sandbox. The observed direct-dispatch schema cannot select such a file: do not claim an installed TOML is active without runtime evidence.

The [configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference) documents `agents.enabled = false` to disable multi-agent tools. It is not established here as a per-worker switch: disabling the mister's own agents would also prevent dispatch. The subagent documentation lists `features.shell_tool = false` for custom agents; that removes shell capability, not all possible write paths. No command-pattern allowlist or complete no-write fence for these roles was verified. Keep these restrictions labelled as instructions until the actual worker tool surface proves otherwise.

Keep any configured worker's role text verbatim from `references/plan-and-orders.md`; do not create a second preamble here. No custom TOMLs are shipped by this change.

## Sandbox and environment

Use the session's actual permissions and network capabilities. Sandboxed sessions may be offline: fetch, push, and remote `gh`/`glab` operations need network access. An offline, unauthenticated, or approval-blocked Git node reports an environment failure; never simulate output or silently change permissions. Unclear verification failures use the shared read-only diagnosis workflow before edits or tier escalation. Do not kill an unrelated process to clear a port.
