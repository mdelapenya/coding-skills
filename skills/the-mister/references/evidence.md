# Durable evidence and independent acceptance

Read this before dispatching or resuming. All state is under `<git-dir>/the-mister/<slug>/`, never in the tracked repository root. The mister uses non-shell file tools to persist it; a generic runtime's launcher may persist returned reports instead. Workers return reports and never save them themselves, including the Git operator. The separate, explicit capture exception in `plan-and-orders.md` is unchanged.

## Reports and recovery

Before evaluating any return, save the complete report verbatim as `reports/<id>.<attempt>.md`, where `attempt` is the node's monotonically increasing dispatch number. Do this for failed, interrupted and missing-evidence responses too. Never overwrite or edit a report. A clarification that starts another worker turn is another dispatch, even on the same worker, and gets another attempt path. A queued message that starts no turn has no attempt. If a turn returns several report messages, collect them in arrival order and write the attempt file once when the return is complete, before evaluating. Late messages go into an immutable `reports/<id>.<attempt>.late.<n>.md` supplement, never replace the original.

Write the report in one operation from the returned text; never retype it, and never write your own summary in its place. A long report stays long: the bytes it points to live in `captures/`, which you cite rather than copy. If the runtime gives you no exact copy of the returned text, say so in the node's Log line and in its terminal record. Persistence does not stop partway through a run: a node whose report is not on disk cannot be `done`.

Persist a dispatch event before invocation and the returned report before a verdict. If invocation fails or execution is uncertain, retain its reserved dispatch number and reconcile what actually ran before retrying. A missing response is not a successful attempt. State-write failure stops acceptance: do not mark done with only conversation memory. If no durable non-shell writer or launcher is available, report that limitation and stop at inline orders.

The first discovery of an unknown git dir is the bootstrap exception: reserve the Git node id/attempt and its dispatch event inline, obtain `git rev-parse --absolute-git-dir`, then immediately persist that event and its full returned report at the discovered state path before evaluation or any further invocation. Do not write an approved `plan.md` until approval; reports/metrics may exist first. If a resumed run used a temporary discovery id, reconcile it with existing ids before appending (allocate a fresh id, never collide with a prior attempt). After locating the state, read its starting HEAD and immutable task base SHA before constructing commands that reference them. Never invent either from the current HEAD. If the task base is missing or ambiguous, report committed comparisons as unverified and stop the commit gate; preserve the starting baseline evidence independently.

On resume, read `plan.md`, the orders, every referenced report and `metrics.jsonl` before reconciling outcomes. Missing reports invalidate their summarized evidence. Restore counts from dispatch events and reconcile any gap with the append-only plan log; use the highest reserved count across the node's origin/supersession chain, never reset a count after promotion, rename, compaction or resume. Reconcile uncertain Git mutations before issuing them again. A persisted verdict alone does not establish that today's content still matches the inspected content.

## Budget

Three dispatches per node, each retry with a stated reason to expect improvement. What counts:

- Every worker invocation for the node counts, including a same-worker re-request for missing evidence. A message that makes a worker act again after it reported counts too, however it was delivered; only a message that never starts a turn does not. Recovery, extra scope or a second try sent into a worker that has already reported is a dispatch, never a free continuation.
- A worker invoked only to stop and save its state (the user paused the run, a stop rule fired) does not count against the implementation budget. Log `failed` with "interrupted" and the partial state, and record the metrics reason `interruption`.
- A confirmed review finding is new work, not a retry: it becomes a fix node with its own budget, linked to its review round. So does a follow-up that changes the outcome of an accepted node. Inheritance applies only to the same unaccepted outcome.
- The one re-request happens only within the remaining budget; budget spent, stop and report before any further invocation.
- **Only the user raises a budget or the review-round limit**, with an answer that names the node, or the slug, and the new limit. Record it once under Assumptions with the user's words; it applies to this slug only, never to later ones. A statement about another limit (message caps, turns, timeouts) or a general "you may increase it" is not budget authority, and you never raise a cap yourself.

## Resume procedure

First locate the git dir with a read-only Git discovery node if unknown, then read `plan.md`, its starting HEAD and task base SHA, reports and metrics. If the saved task base is missing or ambiguous, report committed comparisons as unverified; never substitute the current HEAD. Dispatch a read-only Git reconciliation node for the branch line, `git status --porcelain`, `git diff`, `git diff --cached`, `git rev-parse HEAD`, and `git log -5 --oneline`. When the saved task base is unambiguous, also run `git diff --no-renames --name-status <task-base-sha>..HEAD` and `git diff --no-renames <task-base-sha>..HEAD`. Read the persisted reports and metrics before reconciling nodes; a missing report invalidates its summarized evidence. For each node whose last Log line is `dispatched`, inspect its owned files: verified complete, append `done`; unfinished, append `failed` (interrupted, with the partial state) and write that state into its order. Before retrying any branch, commit, push, or PR node, check whether it already succeeded; if the outcome is unknown, report the uncertainty rather than replay the mutation. Resume neither resets the budget nor rolls anything back.

## Metrics

The mister appends one JSON object per line to `<git-dir>/the-mister/<slug>/metrics.jsonl` through state-writing tools. No worker writes metrics. Use UTC timestamps and stable node ids; a renamed or split replacement for the same failed outcome records `origin_node` and inherits its dispatch budget. Independent diagnosis, inspection and review nodes have their own ids and budgets.

Dispatch event (one per invocation, including evidence re-requests):

```json
{"event":"dispatch","slug":"widget","node":"N02-widget","attempt":1,"at":"2026-11-07T10:00:00Z","kind":"build","tier":"medium","effective_tier":"hard","model":"gpt-6.1-sol","role":"engineer","reason":"initial","origin_node":"N02-widget"}
```

`tier` is the intended tier for that attempt; `effective_tier`, `model`, role, and any requested effort or known override come from the actual dispatch, never the worker's self-description. Record unavailable effective-model telemetry as `null` with a reason. Retry reasons distinguish `evidence_request`, `order_gap`, `mechanical`, `substantive_promotion`, `inspection_failure` and `stale_evidence`; `interruption` (a stop-and-save invocation) and `watch` (a re-run peer watch, `peers.md`) are recorded but never count against a build node's budget. Log the inspector's own dispatch too; it is not an extra build dispatch until the implementer is actually invoked again.

One immutable terminal record per node, after required inspection and reconciliation, or when stopping with the node incomplete:

```json
{"event":"terminal","slug":"widget","node":"N02-widget","at":"2026-11-07T10:05:00Z","kind":"build","initial_tier":"medium","final_tier":"hard","model":"gpt-6.1-sol","dispatch_count":2,"outcome":"accepted","first_try_accepted":false,"reports":["reports/N02-widget.1.md","reports/N02-widget.2.md"],"inspection":{"node":"N03-inspect-widget","report":"reports/N03-inspect-widget.1.md","outcome":"PASS"},"promotions":1}
```

These two event types are the whole schema. Use exactly the keys shown, lower-case tiers, and model ids as passed to the runtime; a value you do not have is `null`, with a `null_reason` key. No other event types (`done`, `progress`, `failed`), no renamed keys (`kind` for `event`), and no batch of dispatch events written after the fact. An event reconstructed after a context loss carries `"reconstructed": true` and is never counted as exact in comparisons.

Before appending, read existing event keys: dispatch key is `(slug,node,attempt)`, terminal key is `(slug,node)`. Never append either twice after resume. `outcome` is `accepted`, `failed` or `incomplete`; `first_try_accepted` is true only for an accepted node with one dispatch, no failed required inspection, and no unresolved or stale evidence. An inspection failure makes it false even when a corrected order or reinspection later passes without an implementer retry. Missing evidence followed by a successful re-request also makes it false. `promotions` counts actual upward changes of the effective engineering tier after a failure, not initial availability substitutions or fresh worker identities. Include inspector failures and limitations in the plan log and the terminal record, rather than hiding them behind the final PASS.

Do not emit terminal records for intermediate failed attempts. If a completed node later becomes stale or receives follow-up work after its terminal record, leave history intact: create a successor with `origin_node` and `supersedes`, inherit any remaining retry budget for the same failed outcome, and invalidate dependent evidence. Do not silently turn a terminal record into a second terminal outcome.

For comparisons across runs, a read-only collector reads `<git-dir>/the-mister/*/metrics.jsonl` (including this run); no tracked or global duplicate metrics file is needed. Group terminal build records by initial/effective tier and model, join their dispatch events and inspection records, and report accepted/total, first-try accepted/total, dispatch counts and promotions. Include failed/incomplete nodes and unavailable telemetry; report sample sizes. Elapsed time and actual spend are optional observed fields, never estimated prices. A linked worktree has its own git dir; record additional git dirs explicitly when combining worktree runs.

## Fresh inspector

Require inspection before accepting **every Hard build node** and **every Medium build node with a command in its acceptance**. Easy command-only nodes are not inspected: their captured output is the evidence, and re-running the same literal command adds no independent evidence. An inspection executes the checks; a static reading that a command would pass is neither an inspection nor a node of its own. The work's purpose determines its kind; do not relabel a build/check node to evade inspection. Git, review, assessor, discovery, diagnosis, verify and inspector nodes are exempt from recursive inspection. Full-check/verify nodes still run their named checks and report raw evidence. Git-only acceptance criteria go to a separate literal Git-role node; an inspector never runs Git.

Dispatch a fresh inspector, on the Easy model (Haiku/Luna, with availability substitutions recorded), separate from the implementer and with no inherited conversation. Supply only the canonical Inspector preamble and this package: literal acceptance criteria, owned paths and necessary dependency paths, absolute working directory, exact allowed verification commands, execution permissions, and allowed test-output paths. Include relevant repository/user constraints. **Do not send Changes, the implementer's report, its claimed results, the mister's diagnosis or suggested fix.** In runtimes that cannot provide a fresh context, report inspection as unavailable rather than claim independence.

Inspection order:

```markdown
# Work order <id>: inspect <build id>
## Your role
<canonical Inspector preamble>
## Acceptance
<literal criteria, with Git-only criteria delegated to <git node>>
## Paths
<owned paths; dependencies available for read>
## Working directory
<absolute path>
## Commands and execution permissions
<exact commands, each carrying its directory; relevant access/network constraints>
## Allowed test outputs
<explicit temporary/build output paths under `<git-dir>/the-mister/<slug>/scratch/<id>/`, or None; toolchain caches stay at their shared defaults (plan-and-orders.md, Scratch and caches); no source edits>
## Report
### Verdict
<PASS or FAIL for each criterion; unavailable is FAIL/unverified>
### Verification output
<each command, directory, complete raw stdout/stderr, and exit status>
### Reasons to reject
<counterexamples, gaps and inconsistencies, or None>
### Evidence limits
<checks unavailable, state not covered, or None>
```

Before inspecting, bind criteria to a manifest of current owned files and relevant read dependencies: path, raw content digest, mode, symlink target or explicit deletion. An Easy collector can hash/read metadata; any Git command belongs to a Git node. Include command inputs/configuration and environment assumptions that affect the result. Do not hash only the diff or inspector report. Serialize inspection with writers of these paths/resources, then recompute the manifest after checks; a mismatch invalidates the result. Test outputs may be written only in the order's explicit output paths; they do not grant permission to repair source or rewrite lockfiles. A check whose outputs cannot be isolated is unverified until its execution permissions are resolved.

The mister persists and reads the inspector report, compares each result to the literal criterion, and logs reasons to reject. FAIL goes through Recover; unavailability stays unverified. Recheck the manifest before using acceptance downstream, on resume, and at preflight. Any changed input invalidates affected acceptance and requires new inspection; it also invalidates dependent review/check evidence. Passing independent inspection complements the whole-change review in `review.md`.

## Non-deterministic output

A criterion about what a model, a provider or any other non-deterministic system returns ("the reply makes no claim its input does not support") cannot be accepted from passing tests or a static reading of the prompt. Declare the campaign in the order before the first call:

- **Cases**: the fixed set of inputs, each one generation, in a stated order.
- **Stop rule**: the campaign stops at the first failing case. A failed sample is evidence about the change, not a retry of the same prompt.
- **Judge**: who decides pass or fail, from what. The full raw reply of each generation is captured to `captures/`, and the judge reads the capture, never a worker's paraphrase.
- **Pass**: what every case must show, and what is out of scope for this criterion (tone or voice, for example), so a side observation does not fail the campaign.
- **Ledger**: an append-only capture with one line per generation: case, model, capture path and verdict.

Each generation is one call, counted in metrics. After two failed campaigns with the same root cause, stop varying the prompt: ask the user for the product decision (what the system should do when the data cannot support the claim), and write the answer into the acceptance criterion.

## Optional run limits

Under Assumptions, record user-supplied deadlines, spend ceilings when observable, and the authorized destructive scope (for example no history rewriting or deletion beyond named generated outputs). Record `not specified` for absent limits and `unavailable` for telemetry the runtime does not expose. Do not invent model prices, cost estimates or new approval gates. Existing session authorization applies.

Before each dispatch, check deadline, available spend telemetry and destructive scope, plus the three-dispatch budget. At an observed limit, stop dispatching, preserve reports/metrics and report incomplete with the next action. If a requested spend ceiling cannot be observed, disclose that limit of enforcement before further paid work and obtain a usable bound; do not claim compliance from guessed costs. Do not expand destructive scope to recover a failed node. Final reporting includes limit status and unavailable telemetry.
