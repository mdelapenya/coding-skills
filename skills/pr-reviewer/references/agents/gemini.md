# Gemini CLI

Topic file for running `pr-reviewer` from inside the Gemini CLI (with the coding-skills extension installed).

## Fetch tooling

The skill drives its own fetch. Gemini CLI has shell access and is competent with `gh` (GitHub) and `glab` (GitLab).

## Looping primitive

As of writing, **Gemini CLI does not have a `/loop` primitive** — it is an open feature request ([gemini-cli#22653](https://github.com/google-gemini/gemini-cli/issues/22653); recurring-task scheduling is requested separately at [gemini-cli#25415](https://github.com/google-gemini/gemini-cli/issues/25415)). The official recommendation today is to run Gemini CLI from an **external `cron`** for recurring use cases.

Until a real loop primitive ships, use one of:

- **Repeat instruction in the prompt** — "Run `/pr-reviewer [<num>]` up to 3 times, stopping when `findings.md` records `converged: true`." Gemini will sequence the rounds itself.
- **External shell driver** —
  ```bash
  for i in 1 2 3; do
    gemini -p "/pr-reviewer [<num>]"
    grep -q '^- converged: true$' "<base-dir>/findings.md" && break
  done
  ```
  Most predictable option for CI or scripted reviews.
- **External cron** — for periodic re-reviews, schedule the shell driver above with `cron`. Coarser than per-iteration looping but works today.

`--rounds=N` is the universal hard stop.

## Posting the final report

```bash
gh pr review <pr-number> --comment --body-file <path-the-skill-printed>
```

Always confirm with the user before posting.

## References

- [Feature: /loop command for periodic prompts (gemini-cli#22653)](https://github.com/google-gemini/gemini-cli/issues/22653)
- [Recurring schedule tasks (gemini-cli#25415)](https://github.com/google-gemini/gemini-cli/issues/25415)
