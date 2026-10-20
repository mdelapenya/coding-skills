# OpenAI Codex

Topic file for running `pr-reviewer` from inside OpenAI Codex (CLI / app). Not yet exercised end to end in staged mode; the dispatch shape below matches the `collaboration.spawn_agent` schema observed in one Codex session (2026-09). Read your Codex's actual tool schema and model list before dispatching.

## Fetch tooling

Codex has shell access in its sandboxed workspace and is competent with `gh` and `glab`. **Network requirement**: Steps 2 and 4 need outbound network. If the sandbox is offline, the user must check out the PR head beforehand and the skill can only run the "current branch" path, verifying `HEAD == headRefOid` against metadata the user pastes in. Codex must not invent metadata it could not fetch. The default workspace-write sandbox may not allow `$HOME/.cache`; Step 3's temp-dir fallback covers that.

## Models

Same aliases as `the-mister`'s Codex file.

| Tier | `model` | `reasoning_effort` | Used for |
|---|---|---|---|
| Hard | `gpt-5.6-sol` | `high` | assessor; escalated reviewer |
| Medium | `gpt-5.6-terra` | `medium` | reviewers A, B, C by default |
| Easy | `gpt-5.6-luna` | `low` | summary |

Codex takes effort as a dispatch parameter, so "high effort" is `reasoning_effort: "high"` rather than prompt text. Record the model and effort you passed.

## Fan-out primitive

`spawn_agent` takes `task_name`, `message`, `fork_turns`, `model`, `reasoning_effort`. Three calls for the reviewers, then `wait_agent` repeatedly until all three have returned (it returns on the first completion); only then spawn the assessor:

```json
{
  "task_name": "pr_reviewer_a_correctness",
  "message": "<reviewer prompt from references/passes.md, fully instantiated>",
  "fork_turns": "none",
  "model": "gpt-5.6-terra",
  "reasoning_effort": "medium"
}
```

`fork_turns` must be `"none"`: a model override requires a non-full-history fork, and a clean slate is what keeps one reviewer's context out of another. Reviewers must not be able to see each other's results; do not fork from a turn that already contains one.

If the sandbox has no `spawn_agent`, fall back to single mode and record `mode: single (fallback: <reason>)` in `findings.md` so the report says so.

## Looping primitive

Codex CLI has no `/loop` primitive at the time of writing ([codex#15679](https://github.com/openai/codex/issues/15679); broader scheduling at [codex#25466](https://github.com/openai/codex/issues/25466)). Use one of:

- **Iteration prompt**: "Run `/pr-reviewer <num> --rounds=3` and keep invoking it until `findings.md` records `converged: true` for the current revision."
- **External driver (CLI)**: a shell `while` loop that breaks on the convergence marker (see the `awk` check in `generic.md`). Always pass `--rounds=N`.
- **Codex app Automations** for coarse scheduled re-reviews.

## Posting

Step 11 of the skill. If the sandbox is offline, print the report and let the user post it; do not simulate posting.
