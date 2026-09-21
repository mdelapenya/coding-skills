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
2. **One CLI session per node**, launched by the user or a wrapper script with the tier's model flag and the order file as input. The launcher captures the session's returned report to `<git-dir>/the-mister/<slug>/reports/<id>.md`; workers return their reports; they do not write report files, which keeps the Git operator's no-file-creation rule intact. The mister reads reports from there, and on resume reads them before reconciling.

Without either, the mister produces the plan and the orders and stops. It does not perform the nodes itself.
