# Claude Code

Topic file for running `pr-reviewer` from inside Claude Code. Named `claude-code.md` on purpose: `claude.md` resolves as `CLAUDE.md` on a case-insensitive filesystem and may be auto-loaded as project instructions.

## Fetch tooling

Claude Code has the `Bash` tool. The skill drives metadata and clone itself with `gh` (GitHub) or `glab` (GitLab).

- **From inside the matching repo:** `/pr-reviewer` (current PR branch) or `/pr-reviewer <num>`
- **From a barebones directory:** `/pr-reviewer https://github.com/<org>/<repo>/pull/<n>` or `/pr-reviewer <org>/<repo>#<n>` (GitHub), `<group>/<project>!<n>` (GitLab)

## Models

Same aliases as `the-mister`'s Claude Code file, so one override vocabulary works for both skills.

| Tier | `model` | Used for |
|---|---|---|
| Hard | `opus` | assessor; the escalated reviewer in complex/consequential PRs |
| Medium | `sonnet` | reviewers A, B, C by default |
| Easy | `haiku` | summary |

Effort: the `Agent` tool takes an `effort` parameter (`low`, `medium`, `high`, `xhigh`, `max`); the skill's "high effort" is `effort: "high"`. If your build of the tool lacks it, paste `Think hard and read every call site before concluding.` into the prompt instead and record which you did. Record the alias and effort you passed, not what the agent says it is. Never pass `fable`.

## Fan-out primitive

One `Agent` call per reviewer, all three in one message, foreground so you cannot proceed without their results:

```
Agent(subagent_type: "general-purpose", model: "sonnet", effort: "medium",
      description: "pr-reviewer A correctness #<num>",
      prompt: <reviewer prompt from references/passes.md, fully instantiated>,
      run_in_background: false)
```

`general-purpose` has `Bash`, which the reviewer needs for `git diff` and `grep` in the review tree. Its read-only behaviour is an instruction in the prompt, not an enforced fence; the prompt's RULES block is what holds it. `Explore` is read-only by construction but may refuse `git` commands on a detached checkout; prefer `general-purpose`.

The assessor is one `Agent` call with `model: "opus"`; the summary one with `model: "haiku"`. Never use `isolation: "worktree"`: the review tree is already pinned and a second worktree would not be.

If `Agent` is not in your tool list, or the first call is denied, fall back to single mode and record `mode: single (fallback: <reason>)` in `findings.md` so the report says so.

## Looping primitive

Claude Code ships `/loop`:

```
/loop /pr-reviewer [<num>]
```

Each iteration re-pins the revision (Step 2), reuses the clone, and appends a round to `findings.md`. `/loop` does not read files: the skill ends every unfinished round with a status line, and when a round finishes the revision (converged, `--rounds` reached, or `Latest-state review incomplete`) the iteration says so plainly and the loop is stopped (by you in dynamic mode, or by the user). Publication is offered only on that final iteration, so the loop is never blocked on a question. If the author is actively pushing, `/loop 10m /pr-reviewer [<num>]` paces the re-pins; the `--max-refresh` budget caps how many restarts the pushes can cause mid-review.

## Posting

Step 11 of the skill, via `AskUserQuestion` then `gh api … /reviews --input`. Always after the report, always with explicit confirmation.
