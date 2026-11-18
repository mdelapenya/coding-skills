# State file: `findings.md`

One file per PR, under the base dir resolved in Step 3. It is the only thing the skill persists. Every round appends; nothing is rewritten except a revision's `freshness` line when it is superseded and the file-level `refreshes-used` counter.

## Layout

```markdown
# pr-reviewer - <platform> <org/repo> #<num>: <title>
refreshes-used: 0                            # restarts of an unfinished review; reset to 0 when a revision finishes

## Revision 1 - head <full-sha> base <full-sha> merge-base <full-sha> - captured <UTC>
scope: full | delta
scope-reason: first review | requested --full | follow-up | requested --since | full fallback: <reason>
baseline: none | revision <R> head <full-sha> merge-base <full-sha> | external head <full-sha> merge-base <full-sha>
prior-coverage: n/a | complete | unknown    # n/a for full scope; unknown for an explicit baseline without stored coverage
comparison: <pinned commands and selected hunks/files, including range-diff reconciliation when needed>
widened: none | <unchanged paths and the delta dependency requiring each>
carried-findings: none | <ids, original reviewed heads, statuses and evidence; not re-reviewed>
freshness: current <UTC> | superseded <UTC> by head <sha12> base <sha12> | unverified <UTC>
finished: false                              # true once converged, or round count reached the last rounds-cap; --no-loop never sets it

### Round 1 - <UTC>
mode: staged | single (requested) | single (fallback: <reason>)
models: A=<alias>/<effort> B=<alias>/<effort> C=<alias>/<effort> assessor=<alias>/<effort> summary=<alias>/<effort>
passes: A=ok B=ok C=ok assessor=ok          # or partial:<reason>, recovered, missing, interrupted
coverage-gaps: none                          # or the Step 5 category that could not be loaded
ci: not consulted | ci@<sha12> <summary>
checks-run: A=<commands> B=<commands> C=<commands> assessor=<commands>
limits: <union of what could not be verified, from every pass>
disagreements: none | <precise open question the assessor could not settle>

#### Confirmed
- ...
#### Weakened
- ...
#### Retracted
- ...
#### Needs info
- ...

#### Convergence
- changed-from-previous: n/a
- converged: false
- rounds-cap: 3

### Round 2 - <UTC>
...

## Revision 2 - head <full-sha> base <full-sha> merge-base <full-sha> - captured <UTC> (supersedes revision 1)
...
```

Rules:

- A **revision** pins one `(head, base)` pair and one scope selection. A new pair, even with the same head, is a new revision. An explicit scope change can also open a revision on the same pair; see `scope.md`.
- Rounds number from 1 inside each revision. Convergence compares consecutive rounds of the same revision only.
- `refreshes-used` is a file-level counter of automatic restarts of an **unfinished** review. It is incremented when the PR moves mid-review and a successor revision is opened, and reset to 0 whenever a revision records `finished: true` (converged, or round count at its last `rounds-cap`). A user re-invoking with a larger `--max-refresh` is the way past it mid-review.
- Select the last completely covered baseline per `scope.md`, not simply the last header. Prior completed coverage can be reused for delta scope, but convergence never crosses revisions. Re-verify findings affected by the delta; carry unaffected findings with their original provenance. An `interrupted` round's raw findings remain hints only.
- New headers store full commit SHAs. Legacy headers with short SHAs remain readable if they resolve uniquely. Missing scope fields on a legacy revision mean full scope; missing coverage evidence is never assumed complete. A delta baseline's complete coverage must trace back through completed delta revisions to a complete full review.
- `checks-run`, `limits` and `disagreements` are stored because every round is a separate invocation: the later-round assessor needs the open question, and the summary needs the commands and limits for the validation section.
- Models, passes and coverage are written **with** the round, after the passes finish; nothing is written before dispatch. Write the round with a temp file and `mv` into place so a crash mid-write cannot leave a half round. The `.lock` directory next to the file guards against two invocations writing at once.

## Finding schema

Every finding, in every round, in this shape. Field order fixed so rounds can be diffed.

```
- id: F-<short-stable-slug>
  revision: <R>
  file: <path>:<line-or-range>
  category: <correctness|regression|tests|security|performance|api|maintainability|scope|hygiene>
  severity: <blocker|major|minor|nit>
  reachability: <proven|plausible|unknown> - <the caller, config or input that reaches the path, cited; or what is missing>
  sources: [A, C]                 # staged mode: which reviewers raised it; single mode: [self]
  claim: <one sentence>
  evidence: <the exact code or behaviour reacted to, quoted>
  evidence-kind: <static|executed|ci@<sha12>|unverified>
  reasoning: <why this is a problem in this codebase>
  status: <pending-challenge|confirmed|weakened|retracted|needs-info>
  stability: <fresh|stable|unstable>        # from round 2 on
  challenge: "<the strongest defence the PR author could give>"
  verdict: "<why the defence fails, or why it wins>"
```

- `id` is stable across rounds and across the assessor's merge. When two reviewers raise the same underlying defect under different slugs, the assessor keeps the first slug and lists both in `sources`.
- `evidence-kind` says how the evidence was obtained. `static`: read from the code. `executed`: a **read-only** command the reviewer ran in the review tree and quoted (the `git` subcommands and `grep` that RULES in `passes.md` allows); building, installing or running the PR's tests is not allowed, so it is never `executed`. `ci@<sha>`: a hosted CI result the coordinator fetched for exactly this head. `unverified`: rests on reasoning alone (for example "a test exists" without showing it runs against this head). A `confirmed` finding with `unverified` evidence stays `confirmed`, but the report carries the kind so the author can weigh it.
- `severity` and `reachability` are two separate claims, never merged into one. `severity` rates the defect **as if the path is reached**; `reachability` says whether it is. `proven` needs a cited, real caller, configuration or input in the review tree that reaches the changed path; `plausible` means a route exists but nothing shown triggers it; `unknown` means the reviewer could not tell, with what would settle it. "This branch is wrong" can be certain while "this branch ever runs" is unknown: keep both, and let the reader weigh them. `evidence` and `evidence-kind` describe the defect; the reachability line carries its own citation.
- `stability`: `stable` when the status matched the previous round, `unstable` when it flipped (the assessor must then pick a side with explicit reasoning), `fresh` when the finding first appeared this round.
- `challenge` and `verdict` are written by the assessor (single mode: by you) and are mandatory on anything that is not `pending-challenge`.

## Lenses

Reviewers in staged mode carry one lens each, so the three first passes overlap as little as possible. The categories are the same for everyone; the lens is what each reviewer leads with and must cover exhaustively.

| Reviewer | Lens | Leads with |
|---|---|---|
| A | correctness, regression, performance, maintainability | off-by-one, nil/undefined, swallowed errors, ordering and races, behaviour changes the description does not mention, N+1 and accidental quadratic work |
| B | security, trust boundaries, persisted state | input validation and injection sinks, authz/authn changes, secret handling, path traversal and SSRF, anything that crosses a privilege or tenant boundary, data migrations and format changes that are hard to roll back |
| C | tests, validation, API contract, scope and hygiene | whether new branches are actually executed by new tests, mocks that fake away the thing under test, always-true asserts, backward compatibility and error-shape changes, diff versus description and linked issues, commit messages that contradict the diff |

Every reviewer reads the entire selected scope (full diff or delta plus required dependencies). A finding outside a reviewer's lens is still a valid finding within that scope.

## Successor rules

Applied once per invocation, in Step 3, after reading `findings.md`:

- Same `(head, base)` pair and scope selection as its current revision → this is the next round of that revision. If that revision converged, or its stored round count is already at this invocation's `--rounds`, run no pass: go to Step 10 and render from the file. An explicit scope change opens a new revision at round 1 even on the same pair; identical flags never reset rounds.
- Different pair, and the current revision is **finished** (converged, or its round count reached the cap recorded on its last round) → reset `refreshes-used` to 0, mark the old revision `superseded`, open a new revision at round 1. Finished does not imply complete coverage: choose its baseline separately under `scope.md`.
- Different pair, and the current revision is unfinished → the PR moved mid-review. If `refreshes-used` is below `--max-refresh`, increment it, mark the old revision `superseded`, open a new revision at round 1. Otherwise run no pass: write the freshness record and go to Step 10 with verdict `Latest-state review incomplete`.

## Base dir on Windows

PowerShell: `$env:LOCALAPPDATA\pr-reviewer\<repo-slug>\<num>\`.
