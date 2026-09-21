# Claude Code

Topic file for running `pr-reviewer` from inside Claude Code.

## Fetch tooling

Claude Code has the `Bash` tool. The skill drives the fetch itself using `gh` (GitHub) or `glab` (GitLab) — you do not need to pre-load anything before invoking `/pr-reviewer`. Two ways to invoke it:

- **From inside the matching repo:**
  - `/pr-reviewer` — review the currently checked-out PR branch
  - `/pr-reviewer <num>` — clone PR `<num>` from the current repo's remote into a temp dir and review it
- **From a barebones directory** (no git repo needed):
  - `/pr-reviewer https://github.com/<org>/<repo>/pull/<n>` — clones into cwd if it is empty, otherwise into temp
  - `/pr-reviewer <org>/<repo>#<n>` (GitHub) or `<group>/<project>!<n>` (GitLab) shorthand — same behavior

## Looping primitive

Claude Code ships a `/loop` slash command (verified at the time of writing):

```
/loop /pr-reviewer [<num>]
```

This re-invokes the skill repeatedly, model-paced (omit the interval). Each iteration:

1. Re-establishes PR context (re-fetches via `gh`/`glab`) and reuses the existing clone, refreshing it with `git fetch && git reset --hard`.
2. Runs one full round of the skill.
3. Appends to `<base-dir>/findings.md`.

Recommended flow:

1. Run `/pr-reviewer [<num>]` once to produce round 1.
2. If round 1 finishes without converging and you want iteration:
   ```
   /loop /pr-reviewer [<num>]
   ```
3. The loop exits naturally when:
   - The skill writes `converged: true` to `findings.md`
   - The skill reaches `--rounds=N`
   - The user stops the loop

### Timed loop (PR still moving)

If the author is actively pushing commits, use a timed loop so each iteration re-fetches at a sensible cadence:

```
/loop 10m /pr-reviewer [<num>]
```

## Posting the final report

The skill prints the report by default. To post it on GitHub:

```bash
gh pr review <pr-number> --comment --body-file <path-the-skill-printed>
```

Always confirm with the user before posting — a review is visible to others.
