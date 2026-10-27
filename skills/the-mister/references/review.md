# Review and checks

Step 7 of the workflow. Per-node acceptance checks what the mister thought of; this step checks the whole change for what nobody thought of, before anything leaves the machine. Skip it only when every node is Easy or Git, all literal.

## 1. Full checks

An Easy node first collects the evidence literally: the CI workflow files, the Makefile and package scripts, and the tool versions and environment variables those checks name. You decide from it which checks can run here (or, when that needs judgment about services or platforms, a read-only explorer node does). Then an Easy node runs, literally, every check that can: the whole lint, vet or type check, and test suite, not only the nodes' focused tests. A required check that cannot run here (a service, credentials, a platform) is recorded as **unverified** in `## Review`, never as a pass, and is never a reason to reach an external system without the user's authorisation. Failures go through Recover like any other.

## 2. The review package

Everything the reviewer reads is the **assembled content**, not `HEAD`, since a commit id says nothing about uncommitted work. With the captures directory created (`plan-and-orders.md`, Captures), Git nodes capture:

- `git -C <dir> diff <base>...HEAD --output=<captures>/<id>.committed.diff`, when the work branch has commits;
- `git -C <dir> diff --cached --output=<captures>/<id>.staged.diff` and `git -C <dir> diff --output=<captures>/<id>.unstaged.diff`;
- `git -C <dir> status --porcelain`, whose `??` task paths are new files the reviewer reads directly, and whose `D` paths are deletions.

Unrelated Baseline changes are named in the order as out of scope, not reviewed.

## 3. The content manifest

The review is bound to file content, not to the captures. Before the reviewer is dispatched, a read-only Git node runs `git -C <dir> config --type=bool --default true --get core.filemode` (plain `--get` exits 1 when the key is unset, which would stop the operator) and `git -C <dir> check-attr filter -- <task paths>`, and you record in `## Review`, for every task path:

| Path | Mode | Raw identity (what was reviewed and tested) | Staged identity (what `git add` will store) |
|---|---|---|---|
| regular or executable file | see below | `git -C <dir> hash-object --no-filters <path>` | `git -C <dir> hash-object <path>` (applies the repository's filters, so line-ending normalisation matches the index) |
| symlink | `120000` | the link target, from an Easy node's `readlink <path>` | the same target; `hash-object` follows the link and hashes the wrong thing |
| deleted | `deleted` | none | none |

**Mode** follows git's own rule. With `core.filemode` true (the POSIX default, or unset), it is `100755` or `100644` from an Easy node's `ls -l <paths>`. With it false, git ignores the executable bit: tracked paths keep their current index mode (`git ls-files -s`) and new paths are staged `100644`. If the change needs a mode git will not record that way, the mode is **unverified**.

**Filters.** Line-ending normalisation (`text`, `eol`) is safe: raw and staged identities differ predictably. Any other clean filter (`check-attr` reports `filter: <name>`) can map different working bytes to one blob, so a matching staged blob would not prove the reviewed bytes were committed; such paths are **unverified** unless the user accepts the filter.

Checked on git 2.54: a CRLF file under `eol=lf` has the staged identity `git add` stores; a symlink's `hash-object` is its target file's blob while the index holds a blob of the target path; with `core.filemode=false` a tracked `100644` file made executable, and a new executable file, are staged `100644`, while a tracked `100755` file stays `100755`; a deterministic clean filter mapped `limit=20` and `limit=30` to the same blob while their raw identities differed. Anything else the manifest cannot express losslessly (a submodule, mode `160000`; a filter that is not installed or not deterministic; a path git ignores; a path or link target containing a newline, a tab, or bytes that do not survive the report as text) is **unverified**. Any unverified path stops the commit until the user decides. The preflight never stages to find out.

Capture SHA-256s remain transport integrity only: they prove a capture did not change, not that the source still matches it. Any change to a task path after the manifest, or to a source or dependency the reviewed behaviour relies on, invalidates the review.

## 4. Reviewers

- **Default: one broad reviewer**, Hard, on the Reviewer preamble. Medium only for a small, low-risk change, with the reason written in the order and in `## Review`. Hard is a provisional default until synthetic comparisons settle it.
- **Extra lenses only on risk or recurrence**, each justified in `## Review`: **boundaries** (credentials, auth, capability or backend differences), **composition** (several nodes touching one behaviour), **tests** (multi-backend or variant matrices). Use them when the change is in that risk class or an earlier round of this review found that class.
- The reviewer gets: the request verbatim; the constraints; the captures and the new files to read; verification evidence from accepted nodes; the repository's review and lint guidance verbatim (whatever instructions it gives its reviewers, human or automated: review guidelines, contribution rules, review-tool configuration, lint configs). It does **not** get the plan, the orders, or your diagnosis.
- With more than one reviewer, one Hard **assessor** merges the findings and steel-mans each one against the current content: `confirmed`, `weakened`, or `refuted`, with the reason. With one reviewer, you do that yourself, from evidence.
- A finding that needs a command to confirm becomes a **verify** node (Easy if the command is literal), never a write by the reviewer.
- Review, assessor and verify nodes are not downgraded by the downgrade question. They do not consume a build node's dispatch budget, but each keeps its own three-dispatch budget, and a replacement node for the same question inherits the count of the one it replaces; the two-round cap above still applies.

Review order (Full-template shape, these sections):

```markdown
# Work order <id>: review <task title>
## Your role
<Reviewer preamble>
## Request
<verbatim>
## Constraints
<the user's constraints that bind the change; out-of-scope Baseline paths>
## The change
<capture paths to read; new and deleted task paths>
## Repository guidance
<the repository's reviewer instructions, contribution rules and lint configs, verbatim>
## Verification so far
<commands the engineers ran and their results; what is unverified>
## Report
### Findings
- <severity> <path:line>: <what goes wrong, with which input or state>; confidence <high|medium|low>
### Tests that could not fail
### Verification needed
### Not checked
```

## 5. Rounds

Confirmed findings become build nodes with behavioural orders, owning what they need to fix. After they are accepted, take a new manifest and review again; the next review covers the delta and its interactions with the rest. A round converges only when no confirmed finding is unresolved, not merely when it found nothing new. Before the stage node, and before reporting `complete`, two things must hold: every confirmed correctness finding is fixed and re-reviewed, or the user accepted it; and every required check that is unverified has the user's explicit acceptance. If either fails after the second round, dispatch a read-only diagnosis node and re-plan, or report `incomplete` with the open findings and their severity; never continue to commit quietly.

## 6. Commit against the manifest

The preflight (read-only) recomputes the raw identities, modes and symlink targets of the task paths and compares them with the manifest, without touching the index: a raw mismatch means the bytes changed after review. The **stage** node runs `git add <explicit paths>`, then `git ls-files -s <task paths>` and `git diff --cached --name-status`; for staged symlinks it also runs `git cat-file -p <blob>` to print the target. Compare additions, deletions, modes and staged blobs with the manifest's staged identities, and dispatch the **commit** node only on a match and with no unverified path left. A mismatch at either step means the change moved after review: it goes back to review, and a mismatch after staging is reported to the user with the staged state.
