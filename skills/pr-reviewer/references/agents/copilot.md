# GitHub Copilot

Topic file for running `pr-reviewer` from GitHub Copilot (CLI agent mode, IDE chat, Copilot Workspace). Not yet exercised in staged mode.

## Fetch tooling

Metadata can come from the GitHub MCP server (`get_pull_request` gives `head.sha` and `base.sha` in one response, which is what Step 2 needs) or from `gh` in a shell. The clone and pin in Step 4 need a shell regardless; `git` is the universal path.

## Models

Copilot does not expose a per-subagent model choice at the time of writing. Record `copilot` as the model for every pass, and record the effort you asked for in prose. If your Copilot does offer model selection for sub-tasks, map Hard to the strongest model available, Medium to a mid-cost one, Easy to the cheapest, and record what you chose.

## Fan-out primitive

Copilot CLI's agent mode can run a task end to end but, at the time of writing, has no primitive to spawn three isolated sub-agents that cannot see each other. Without one, run single mode and record `mode: single (fallback: no isolated sub-agent primitive)` in `findings.md` so the report says so. If a future version adds isolated sub-tasks, each reviewer prompt from `references/passes.md` is one sub-task; the isolation requirement is that no reviewer's context contains another's output.

## Looping primitive

No `/loop` or `/schedule` yet ([copilot-cli#2056](https://github.com/github/copilot-cli/issues/2056)). Autopilot completes one task; it does not repeat a prompt. Use:

- **Manual re-invocation** after each round until `converged: true` or `--rounds=N`.
- **Autopilot task phrasing**: "Run `/pr-reviewer <num> --rounds=3` repeatedly until `findings.md` records `converged: true` for the current revision."
- **External shell driver** that breaks on the convergence marker (see the `awk` check in `generic.md`).

## Posting

Step 11 of the skill. Through the GitHub MCP server's review-creation resource if connected, else `gh api … /reviews --input`. Always after the report, always with explicit confirmation.
