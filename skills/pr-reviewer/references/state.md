# State file: `findings.md`

One file per PR, under the base dir resolved in Step 3. It is the only thing the skill persists. Every round appends; nothing is rewritten except a revision's `freshness` line when it is superseded and the file-level `refreshes-used` counter.

## Layout

```markdown
# pr-reviewer - <platform> <org/repo> #<num>: <title>
refreshes-used: 0                            # restarts of an unfinished review; reset to 0 when a revision finishes

## Revision 1 - head <sha12> base <sha12> merge-base <sha12> - captured <UTC>
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

## Revision 2 - head <sha12> base <sha12> merge-base <sha12> - captured <UTC> (supersedes revision 1)
...
```

Rules:

- A **revision** is one `(head, base)` pair. A new pair, even with the same head, is a new revision.
- Rounds number from 1 inside each revision. Convergence compares consecutive rounds of the same revision only.
- `refreshes-used` is a file-level counter of automatic restarts of an **unfinished** review. It is incremented when the PR moves mid-review and a successor revision is opened, and reset to 0 whenever a revision records `finished: true` (converged, or round count at its last `rounds-cap`). A user re-invoking with a larger `--max-refresh` is the way past it mid-review.
- Findings of a superseded revision, including an `interrupted` round's raw findings, are read by the next revision's round-1 reviewers as **hints to re-verify**, never copied forward with their status.
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
- `stability`: `stable` when the status matched the previous round, `unstable` when it flipped (the assessor must then pick a side with explicit reasoning), `fresh` when the finding first appeared this round.
- `challenge` and `verdict` are written by the assessor (single mode: by you) and are mandatory on anything that is not `pending-challenge`.

## Lenses

Reviewers in staged mode carry one lens each, so the three first passes overlap as little as possible. The categories are the same for everyone; the lens is what each reviewer leads with and must cover exhaustively.

| Reviewer | Lens | Leads with |
|---|---|---|
| A | correctness, regression, performance, maintainability | off-by-one, nil/undefined, swallowed errors, ordering and races, behaviour changes the description does not mention, N+1 and accidental quadratic work |
| B | security, trust boundaries, persisted state | input validation and injection sinks, authz/authn changes, secret handling, path traversal and SSRF, anything that crosses a privilege or tenant boundary, data migrations and format changes that are hard to roll back |
| C | tests, validation, API contract, scope and hygiene | whether new branches are actually executed by new tests, mocks that fake away the thing under test, always-true asserts, backward compatibility and error-shape changes, diff versus description and linked issues, commit messages that contradict the diff |

Every reviewer reads the whole diff. A finding outside a reviewer's lens is still a valid finding.
