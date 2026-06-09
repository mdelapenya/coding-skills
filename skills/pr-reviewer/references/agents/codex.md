# OpenAI Codex

Topic file for running `pr-reviewer` from inside OpenAI Codex (CLI / cloud agent).

## Fetch tooling

The skill drives its own fetch. Codex has shell access in its sandboxed workspace and is competent with `gh` (GitHub) and `glab` (GitLab).

**Network requirement**: the skill needs outbound network to clone the PR and run platform commands. If the sandbox is offline (the default for many Codex environments), the user must check out the PR before invoking — or paste the PR context (metadata, commits, diff, linked issues, files) into the task. Codex should refuse to invent data it cannot fetch.

## Looping primitive

As of writing, **OpenAI Codex CLI does not have a `/loop` primitive** — it is an open feature request ([codex#15679](https://github.com/openai/codex/issues/15679); a broader scheduling proposal sits at [codex#25466](https://github.com/openai/codex/issues/25466) / [codex#8317](https://github.com/openai/codex/issues/8317)). The Codex *cloud app* has Automations for recurring tasks, but those are scheduled outside the CLI session and are coarse-grained, not per-iteration of a review.

Until a real loop primitive ships, use one of:

- **Iteration prompt** — instruct Codex up front: "Run `/pr-reviewer [<num>]` up to 3 times, stopping when `findings.md` records `converged: true`." Codex will sequence the rounds itself.
- **External driver (Codex CLI)** — wrap the CLI in a shell `while` loop that breaks on the convergence marker. Cap with `--rounds=N`.
- **Codex Automations (cloud app)** — if scheduling is required externally (e.g., a nightly re-review), set up an automation that re-runs the task. Much coarser than per-iteration looping.

`--rounds=N` is the universal hard stop. Always pass it.

## Posting the final report

If outbound network is available:

```bash
gh pr review <pr-number> --comment --body-file <path-the-skill-printed>
```

If the sandbox is offline, print the report and let the user post it themselves. Do not "simulate" posting.

Always confirm with the user before posting.

## References

- [Feature: in-session scheduling + /loop (codex#25466)](https://github.com/openai/codex/issues/25466)
- [Feature: /loop recurring prompt in Codex TUI (codex#15679)](https://github.com/openai/codex/issues/15679)
- [Codex app Automations](https://developers.openai.com/codex/app/automations)
