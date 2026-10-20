# Generic / unknown runtime

Fallback for any agent without a dedicated file here.

## Fetch tooling

With a shell, `gh` and `glab` are the canonical tools and the skill runs as written. With only a host MCP server, use it for Step 2 metadata (head and base SHA must come from one response) and for linked issues; Step 4's clone still needs a shell. With neither, the user must check out the PR head and paste the metadata; the skill then verifies `HEAD == headRefOid` and runs the "current branch" path. The skill never manufactures data.

## Models

| Tier | Requirement | Used for |
|---|---|---|
| Hard | the strongest model available for a sub-task | assessor; escalated reviewer |
| Medium | a mid-cost model | reviewers A, B, C |
| Easy | the cheapest | summary |

With one model only, record it for every pass; the lenses, the assessor's steel-man and the state file still apply.

## Fan-out primitive

If the runtime can start isolated sub-tasks with their own prompt (and ideally their own model), each reviewer prompt from `references/passes.md` is one sub-task, dispatched together, with no reviewer's output in another's context. The assessor and summary are two more sub-tasks, in sequence. If it cannot, run single mode and record `mode: single (fallback: no isolated sub-agent primitive)` in `findings.md` so the report says so. Do not emulate independence by role-playing three reviewers in one context: that is one reviewer with three hats, and the report would overstate it.

## Looping primitive

Most runtimes have no loop primitive (Claude Code is the exception). In increasing order of automation:

1. **Manual**: re-invoke `/pr-reviewer <num>` after each round until `converged: true` or `--rounds=N`.
2. **Task phrasing**: "Run `/pr-reviewer <num> --rounds=3` repeatedly until `findings.md` records `converged: true` for the current revision."
3. **External shell driver**:
   ```bash
   for i in $(seq 1 3); do
     <agent-invocation> "/pr-reviewer <num> --rounds=3"
     awk '/^## Revision/{c=0} /^- converged: true$/{c=1} END{exit !c}' "<base-dir>/findings.md" && break
   done
   ```

The `awk` resets at every `## Revision` header, so only the latest revision's convergence stops the loop. Always pass `--rounds=N`; an invocation that finds the cap already reached renders the report without running a pass.

## Posting

Step 11 of the skill, after the report, with explicit confirmation, through whatever the runtime offers. Without a posting path, print the report and let the user post it.
