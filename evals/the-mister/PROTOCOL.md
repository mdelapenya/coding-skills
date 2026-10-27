# Evaluation protocol: the-mister, current vs revised

For the operator who runs the cases. It says how to run them, not what should happen: expected outcomes are sealed elsewhere and opened only after every run is recorded.

## Variants

A variant is everything the runtime loads for the mister, not only the skill folder: `skills/the-mister/` with its references and runtime adapters, the shipped `agents/*.md`, and any installed agent or configuration the runtime would pick up.

- **current**: all of those as of commit `184e8d4`.
- **revised**: all of those from the working tree under evaluation.

Isolate each variant: export it into its own directory (for example `git archive 184e8d4 skills/the-mister agents` for current, a copy of the working tree for revised), and point the session at that copy only. Claude Code: install the variant's skill and agents at project scope in the case repository (`.claude/skills/the-mister/`, `.claude/agents/`), run with no user-scope or plugin copy of `the-mister` or its agents active, and check the agent list at session start. Codex: pass the variant's files explicitly. Record the SHA-256 of every variant file the session could load. A run whose session could see files from both variants is discarded, not compared.

Run each case once per variant, per runtime available (Claude Code, Codex), in a fresh session that has not seen the planning discussion, this repository's plan files, or the sealed outcomes.

## Setting up a case

1. Copy `cases/<id>/repo/` to a fresh directory outside this repository.
2. In it: `git init`, `git add -A`, `git commit -m baseline` (any identity; set it per command with `-c user.name=... -c user.email=...`, never in a config file).
3. Copy any other file in `cases/<id>/` except `task.md` next to the repository, not inside it.
4. Invoke the mister with the text of `cases/<id>/task.md` verbatim, plus: "Work on the current branch. Do not push or open a pull request." Approve its plan as presented, without editing it; answer any question with "use your judgement".

Go runs in Docker, for example `docker run --rm -v "<repo>:/w" -w /w golang:1.25-alpine go test ./...`. Tell the mister so in the request if the host has no Go.

## Harness step (c08 only)

After the mister accepts its last review or verification node, and before it dispatches its preflight or commit node, append one line to `text/text.go` in the case repository with your own editor:

```
// touched after review
```

Then let the run continue. If the variant has no review step, do it after the last build node is accepted.

## What to record, per run

- The final report, `plan.md`, and every order and report under `<git-dir>/the-mister/<slug>/`.
- The final `git log --stat` and `git diff` of the case repository.
- Dispatch count, Hard dispatches, wall time, and anything the runtime reports about tokens (or "unavailable").
- Your own observations, labelled as such.

Do not grade while running. Grading opens the sealed outcomes, and the grader records, for each expected outcome, met / not met / not applicable with the evidence.
