# Gemini CLI

Topic file for running `pr-reviewer` from the Gemini CLI with the coding-skills extension installed. Not yet exercised in staged mode.

## Fetch tooling

Gemini CLI has shell access and is competent with `gh` and `glab`. Steps 2 to 5 run as written.

## Models

Gemini CLI does not expose a per-subagent model choice at the time of writing. Record `gemini` as the model for every pass and the effort you asked for in prose. If your setup offers sub-task model selection, map Hard to the strongest, Medium to a mid-cost, Easy to the cheapest, and record the choice.

## Fan-out primitive

No isolated sub-agent primitive at the time of writing. Run single mode and record `mode: single (fallback: no isolated sub-agent primitive)` in `findings.md` so the report says so. If one becomes available, each reviewer prompt from `references/passes.md` is one isolated sub-task, and no reviewer's context may contain another's output.

## Looping primitive

No `/loop` yet ([gemini-cli#22653](https://github.com/google-gemini/gemini-cli/issues/22653); scheduling at [gemini-cli#25415](https://github.com/google-gemini/gemini-cli/issues/25415)). Use:

- **Repeat instruction**: "Run `/pr-reviewer <num> --rounds=3` until `findings.md` records `converged: true` for the current revision."
- **External shell driver**:
  ```bash
  for i in 1 2 3; do
    gemini -p "/pr-reviewer <num> --rounds=3"
    awk '/^## Revision/{c=0} /^- converged: true$/{c=1} END{exit !c}' "<base-dir>/findings.md" && break
  done
  ```
  The `awk` resets at every `## Revision` header, so a superseded revision's `converged: true` cannot stop the loop.
- **External cron** for periodic re-reviews.

## Posting

Step 11 of the skill: `gh api … /reviews --input` after the report, with explicit confirmation.
