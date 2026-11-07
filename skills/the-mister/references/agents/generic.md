# Other runtimes

Not yet exercised on any runtime. For Copilot, Gemini CLI, and anything without a "spawn a subagent with model X" primitive. Record `generic` and the model names you chose under Assumptions in `plan.md`.

## Models

| Tier | Requirement |
|---|---|
| Hard | the strongest model below the mister |
| Medium | a mid-cost model |
| Easy, Git | the cheapest available; Git never signs |

With one model only, tiering is moot but the DAG, disjoint ownership, and the orders still apply; say so in Assumptions.

## Dispatch

1. **Native sub-tasks or agent mode with model selection**, if the runtime has them: the order above the cut line is the prompt; record the model you selected in evidence.
2. **One CLI session per node**, launched by the user or a wrapper script with the tier's model flag and the order file as input. The launcher captures the session's returned report to `<git-dir>/the-mister/<slug>/reports/<id>.<attempt>.md`; workers return their reports; they do not write report files, which keeps the Git operator's no-file-creation rule intact. The launcher uses the reserved dispatch number, refuses to replace an existing report, and preserves failed returns too. The mister reads reports from there, and on resume reads them and metrics before reconciling.

Without either, the mister produces the plan and the orders and stops. It does not perform the nodes itself.

## State and independent verification

Use the shared [evidence lifecycle](../evidence.md): the mister or launcher persists reports, and the mister persists dispatch and terminal metrics inside the git-dir state, never in the tracked root. No worker writes its own report. If no durable state writer/launcher exists, report that limitation and stop at the inline plan/orders. The same content-binding, committed-baseline preflight and protected dirty-baseline rules apply here.

For each required inspection, use a new isolated sub-task or CLI session on the cheapest available model. Supply the canonical Inspector preamble, literal criteria, owned/dependency paths, absolute directory, exact allowed commands, execution permissions and allowed test-output paths. Send no Changes, implementer report, claimed outcome or prior diagnosis. A session that inherits implementation conversation is not independent; report inspection unavailable if context cannot be separated. Run checks only within the authorized permissions, report raw output/exit status and PASS/FAIL, and never repair source. Git-only criteria go to Git-role orders; inspectors, Git, review, discovery, diagnosis and verify nodes do not recurse. These restrictions are instructions unless the runtime's actual tool surface demonstrates enforcement.

Record the actual dispatched model/tier, all started evidence continuations and promotions, and unavailable spend/model telemetry. Restore dispatch counts and read attempt reports on resume. Use observable supplied limits without inventing prices or expanding destructive scope.
