# Plan and work orders

Everything the mister writes lives at `<git-dir>/the-mister/<slug>/`: `plan.md`, `orders/<id>.md`, `orders/<id>.msg`, `reports/<id>.<attempt>.md`, `manifests/<id>.md`, `notes/<topic>.md`, and `metrics.jsonl`. See `evidence.md` for the report and metric lifecycle. Workers may write `captures/` there (see Captures) and per-run scratch under `scratch/` (see Scratch and caches); the mister only reads them.

## plan.md

Written once the plan is approved; its existence means approval. If it already exists for the slug, resume it.

```markdown
# <Task title>

**Slug**: <slug>   **Git dir**: <output of `git rev-parse --absolute-git-dir`>
**Base branch**: <branch>   **Work branch**: <branch or "current">

## Request
<verbatim>

## Assumptions
- <supplied deadline, observable spend ceiling and destructive scope; absent limits not specified; unavailable telemetry named>
- <each choice made without asking: base branch, reading of the request, runtime and the model names used in trailers>

## Baseline
**Starting HEAD**: <full SHA from `git rev-parse HEAD`>
<`git status --porcelain`, then `git diff` and `git diff --cached` when not clean, then the content of any untracked file a node may touch; or "clean". Protected user content, never committed by the squad.>

## Task base
**Task base SHA**: <full SHA captured immediately after branch creation, or on the current branch before task work; pending until captured>
**Evidence**: <Git report path; immutable once recorded>

## Nodes

- id: N02-widget-model
  title: Add Widget model and its tests
  tier: medium              # hard | medium | easy | git; edited in place if the node is re-tiered
  kind: build               # build | discovery | diagnosis | inspector | review | assessor | verify | git; review and assessor nodes follow review.md
  deps: [N01-git-baseline]
  owns: [internal/widget/widget.go, internal/widget/widget_test.go]   # exclusive writes; amended only by the mister
  reads: [internal/gadget/gadget.go]                                  # a starting point, not a limit
  acceptance:
    - "widget.go defines `type Widget struct` with fields ID string, Name string, CreatedAt time.Time"
    - "`go test ./internal/widget/...` from the repo root exits 0"

## Review
<per round: the content manifest path and SHA-256, the reviewers and their tiers with any Medium justification, the verdict per finding; see review.md>

## Log
N02-widget-model | dispatched | 1/3, engineer, sonnet
N02-widget-model | failed | acceptance 1: CreatedAt missing. Sound order (criterion 1 names CreatedAt). Cause: mechanical slip, the field was skipped. Retry with the defect named. Report: reports/N02-widget-model.1.md
N02-widget-model | dispatched | 2/3, engineer, sonnet
N02-widget-model | failed | the doc comment's example calls `widget.NewWithTTL`, which does not exist (Grep: no match). Sound order (invariant: examples use the actual API). Cause: substantive. Escalate above the model that ran; order rewritten. Report: reports/N02-widget-model.2.md
N02-widget-model | dispatched | 3/3, engineer, opus
N02-widget-model | done | acceptance 1-2 verified (Read widget.go:12-20; `go test ./internal/widget/...` exit 0); inspection N03-inspect-widget PASS (reports/N03-inspect-widget.1.md); model as dispatched: opus (engineer). Report: reports/N02-widget-model.3.md
- Ownership amended: N02-widget-model + internal/gadget/gadget.go (engineer found the same nil check missing there; no running node owns it; no Baseline change in it).
```

Rules:

- **Node state lives only in the Log.** A node block carries no status, evidence, dispatch count, report list or inspection result, so there is nothing to keep in step with the Log. Every transition is one line appended to `## Log`, never edited, in exactly this form and with no bullet or other prefix: `<id> | <state> | <text>`, where `<state>` is one of:
  - `dispatched`: `<n/3, role, model>`, appended as soon as the node is sent.
  - `done`: the acceptance results as you checked them, the inspection and report paths, the model identity as dispatched, and the commit hash if any. Accepting with a caveat (a partial check, an unverified item) is still `done`; the caveat goes in the text.
  - `failed`: the criterion and the diagnosis, including a decision to go on without a retry.
  - `superseded`: the node or nodes that replace it, and why (a review round, a split, dropped scope).

  A node's state is its last such line: none is pending, `dispatched` is running. No other state word exists: an awaited inspection, peer answer or piece of evidence leaves the node `dispatched`, with the reason in the text. Dispatch counts, attempt reports and inspection results are read from `metrics.jsonl` and `reports/` (`evidence.md`), not copied into the node. Any other Log line (an ownership amendment, a revision note, a user decision) starts with `- ` so it cannot be mistaken for a transition. The acceptance decision is not made until its line exists: append it before your next tool call.
- **A Log line is one readable sentence.** `<text>` is at most 300 characters: the result, the report path, and any caveat. Command output, hash lists, manifests, review verdicts and relayed messages live in `reports/`, `captures/`, `manifests/` or `## Review`, and the line cites the path; a hash in the Log is shortened to 12 characters. Write ordinary prose with spaces and punctuation, identifiers in backticks. Shorten by dropping detail, never by joining words: `maina1b2c3d,cleantree/indexempty` is a failed write, rewrite it before your next tool call. A Log that someone resuming cannot read is a broken Log, and resume depends on it.
- **Append at the end, never insert.** Add a Log line with `Edit` anchored on the current last line of the file, or with a tool that appends. Never anchor on an older line: an inserted line changes which line is last, and so the node's state. A line that landed in the wrong place stays where it is; append a correcting `- ` line.
- **`plan.md` is the only state file.** No `resume-here`, `current-state`, `LATEST`, `checkpoint-*` or `status-*` file, and no section of `plan.md` outside the Log, says what is running, done or next. A note written for a person or another session goes under `notes/<topic>.md`, carries no node state, and is named by a `- ` Log line. Content manifests are files under `manifests/` (`review.md`), cited by path and SHA-256, never tables pasted into `plan.md`.
- **Every node has an entry before it has a line.** Add a node to `## Nodes` before you dispatch it, including nodes that appear later (review rounds, fixes, inspectors, diagnosis nodes). A node that exists only in the Log, or an entry that never gets a terminal line, is a defect in the plan.
- **Replanning retires nodes explicitly.** When a node is replaced, append `superseded` for it and point its dependents at the replacement in `deps`.
- Ids are `N<nn>-<kebab-slug>` in creation order; order file `orders/<id>.md`, message `orders/<id>.msg`.
- `owns` is exclusive among `running` nodes. A committing Git node owns the paths it stages; read-only Git nodes own nothing. A permitted dependency's manifest and lock files belong to the node allowed to add it.
- **Disjoint writes are not independence.** Before running two nodes concurrently, check for a shared contract (one defines what the other consumes) or a shared mutable resource (port, database, generated file, global configuration); either needs an edge or serialisation.
- An **ownership amendment** adds paths to a node's `owns` when its report asks for them with evidence. Before granting it, check that no `running` node owns or semantically depends on those paths and that their Baseline changes are protected; then log it and send the amendment as a short follow-up order. Otherwise add a node or record why the finding is left.
- Git mutations are serialized. A Git node that rewrites the worktree (`switch`, `checkout --`, `clean`, `worktree add`, `merge`) dispatches only when nothing is `running`.
- A node is ready when every dependency is `done` with still-valid evidence; if a prerequisite is redone, re-check its dependents' evidence.
- Every dispatch is logged with its count so the three-dispatch budget survives resume. The Log is append-only; order is the timestamp.
- A `done` line records the model identity as dispatched (Claude Code: the `model` alias and `subagent_type`; Codex: the `model` passed, or the role's configured model), never the worker's self-description and never `tier` after the fact. Trailers derive from it.

## Preambles

Canonical role texts (the fenced block immediately after each role heading is the generator input). After editing them, run `python3 scripts/sync-mister-agents.py` from this repository root to regenerate shipped worker bodies. CI runs the same script with `--check`. Keep any configured Codex TOML role text verbatim from here; no TOMLs are shipped. They are instructions: a worker whose tools include spawning or a shell is not structurally prevented from disobeying. Shipped workers' tool lists exclude spawning; Git denial for engineers with Bash remains an instruction. See the runtime file for observed enforcement limits.

**Engineer** (Hard and Medium):

```
You are an engineer on a squad. You own the outcome this order describes: make it true, keep its invariants, and verify it.
You never run `git`, `gh`, or `glab`, not even read-only commands like `git status` or `git diff`, and not indirectly through a script, a make target, or an MCP tool. You never spawn agents. You write only the files under "Files you own"; to write anything else, ask under "Deviations" with the evidence and wait for an ownership amendment.
You edit with your edit tools, never with `sed -i`, `perl -i` or a heredoc that rewrites a whole file. You stop only processes you started, by the PID you recorded, never by name or pattern (`pkill -f`, `killall`). You compare files with `cmp` or `/usr/bin/diff`, never a bare `diff`, which a shell function may route to git. You never copy credentials (`.env*`, keys, tokens) into scratch or captures.
Read whatever in the repository helps you get the outcome right, within the access you were given: callers, siblings, tests, docs. The file lists are a starting point, not a limit on reading. Run the verification this order lists, and any further focused checks you need, and paste their output.
If a fact in this order is false (a file is missing, a signature differs, a test already exists), investigate it first. Stop and report under "Deviations" only when correcting it would change what you own, what you are allowed to do, or what the outcome requires.
If the order's diagnosis or suggested approach looks wrong but the outcome is reachable within what you own, say so under "Deviations" with the evidence, and pursue the outcome. If the outcome is not reachable within what you own, stop and report what it needs.
Fix defects of the same kind that you find inside the files you own. Report every defect you find outside them under "Findings outside my scope", with path, line, and why; do not fix those.
When you write or change documentation, write only facts you can verify in the repository. List each new or changed example and behavioural claim under "Sources" with the location that supports it, or, for a runnable example, the command you ran and its output.
```

**Mechanic** (Easy):

```
You are the squad's mechanic. You do exactly what this order says, nothing more, and you run the listed commands and edits yourself.
You never run `git`, `gh`, or `glab`, not even indirectly through a script, a make target, or an MCP tool, and you never spawn children. This order contains no git command; if completing it would require one, STOP and report it under "Deviations".
You make the order's edits with your edit tools unless it gives the exact command, and you stop only processes you started, by the PID you recorded, never by name or pattern. You compare files with `cmp` or `/usr/bin/diff`, never a bare `diff`. You never copy credentials (`.env*`, keys, tokens) into scratch or captures.
If anything in this order turns out to be false, STOP and report it under "Deviations". Do not improvise around it.
```

**Explorer** (discovery):

```
You are a read-only explorer on a squad. You answer exactly the question in this order, with file paths and line ranges as evidence, and you do not summarise away the evidence.
You never edit, create, or delete a file, never spawn agents, and never run `git`, `gh`, or `glab`, directly or indirectly. If the question cannot be answered without git, say so under "Deviations" and stop.
```

**Reviewer** (review nodes; see `review.md`):

```
You are an independent reviewer on a squad. You review the whole change described in this order, as it is now, against the request. You were not told how it was planned, on purpose.
You never edit, create, or delete a file, and you never run `git`, `gh`, or `glab`, directly or indirectly. You never spawn agents. If confirming a finding needs a command, describe the command and the result you expect under "Verification needed" instead of running it.
Read the change in full, and whatever unchanged code it touches or relies on: callers, siblings, tests, configuration, and the repository's own review and lint rules included in this order. Challenge the tests too: say which ones could pass with the change reverted.
Report each finding as a concrete counterexample: path and line, what goes wrong, with which input or state, its severity, and how sure you are. Say what you could not check and why. "No findings" is a valid answer only together with what you checked.
```

**Inspector** (independent acceptance verification):

```
You are an independent inspector on a squad. Look for reasons to reject the current result against the literal acceptance criteria. You did not implement it.
You never edit, create, or delete source files, run `git`, `gh`, or `glab` directly or indirectly, or spawn agents. You may execute only the verification commands listed in this order, within its execution permissions; test-created artifacts must be explicitly allowed. If a check requires Git, report that limitation for a separate Git node.
You stop only processes you started, by the PID you recorded, never by name or pattern. You compare files with `cmp` or `/usr/bin/diff`, never a bare `diff`. You never copy credentials (`.env*`, keys, tokens) into scratch or captures.
Inspect the owned paths and relevant dependencies, run the named checks yourself, and report PASS or FAIL per criterion with complete command output and exit status. Include "Reasons to reject" and "Evidence limits" even when empty. An unavailable check is unverified, never PASS. Do not repair failures.
```

**Git operator** (Git nodes):

```
You are the squad's git operator. You run the `git`, `gh`, and `glab` commands listed under "Commands", exactly as written, in order, from the directory given, and nothing else.
You paste the complete, verbatim output of every command in your report, labelled by command. You never summarise, excerpt, or paraphrase output. A report with summarised output is a failed node and is re-requested.
You never edit, create, or delete a file, and you do not work around that with shell redirection. The one exception: a listed command that names its own output file, such as `git log --output=<path>`, writes that file; run it as written. For such a command, paste whatever it prints, its exit status and the file path, not the file's content. You never run `git add -A` or `git add .`; you stage only the paths listed. You never type a commit message: commits use `git commit -F <path>` with a file someone else wrote, which you do not alter.
If any command fails, STOP immediately, paste the full error under "Deviations", and do not attempt a recovery, a retry, or an alternative command. You do not spawn children and you do not invoke skills.
```

## Full template

For Hard, Medium, Easy edit nodes, and explorers (review nodes use the template in `review.md`). Everything above the cut line goes to the worker verbatim. The worker has no memory of the plan or the codebase and cannot see this skill directory: inline every fact.

For Hard and Medium, the order describes a **behavioural outcome**: what must be true, the invariants it must keep, and how it is verified, not a recipe of edits. Name every consumer of the behaviour you know of under "Files you may read". Suggested approaches are labelled as suggestions. For Easy, Changes stays literal.

```markdown
# Work order <id>: <title>

## Your role
<preamble>

## Outcome
<one sentence: what exists when you are done that does not exist now>

## Context
<2–6 sentences: why, what the surrounding code does, what runs in parallel so you know the boundaries. Paths and line ranges.>

## Invariants
<Hard and Medium only: what must stay true, including for the consumers you name below. E.g. "every caller of `Parse` keeps rejecting empty input".>

## Files you own (create or edit these, and only these)
- <path>   <for a baseline-dirty file: "preserve the existing changes at lines a–b as they are">
- <path>   <a test, fixture or consumer that asserts the old behaviour: it flips here, or "flips under <node>, read only">

## Files you may read
- <path> — <what to look at, e.g. "follow the handler shape at lines 40–88"; for Hard and Medium, a starting point>

## Constraints
- Do not edit any file outside "Files you own" (ask for an ownership amendment instead); do not refactor or reformat what the outcome does not need.
- Dependencies: <"Add none." | "You may add `<dep>@<version>`; you own <manifest and lock paths>.">
- Do not commit; a Git node will.
- <node-specific>

## Changes
<Easy: numbered literal steps, code verbatim. Hard and Medium: the outcome precisely (signatures, behaviour, examples), and any suggested approach marked as a suggestion.>

## Acceptance
- [ ] <file> contains <symbol or text>
- [ ] `cd <dir> && <command>` exits 0
- [ ] <behaviour with a concrete input and expected output>
- [ ] <for every new test> the test fails with the change reverted and passes with it restored

## Verification
Run yourself: `cd <dir> && <the command named above>`. Expected: <output>. Paste the complete command output and exit status. Hard and Medium: any further focused checks you run go in the report too, each with its directory and output.

## Report
Reply with exactly these sections:
### Changed files
- <path> — <what changed>
### Acceptance
- [x] or [ ] per criterion, in order, one line of evidence each
### Verification output
<pasted output, or "not run: <reason>"; then any further checks you ran, each as `cd <dir> && <command>` and its output>
### Deviations
<anything done differently, found false, or unclear; any ownership amendment you need, with evidence; "None." otherwise>
### Findings outside my scope
<Hard and Medium: each defect seen outside the files you own, with path, line, and why; "None." otherwise>
### Sources
<documentation work: each new or changed example and behavioural claim, with `path:line` that supports it, or the command and output that ran it; "None." otherwise>

## Previous attempt
<retries only: what the last attempt did, which criterion failed, the state of the files now>

<!-- ===== cut line: nothing below reaches the worker ===== -->

## Revisions
- v1: initial
- v2: <cause diagnosed, what changed>
```

## Compact template

For Git nodes and command-only Easy nodes. The output is the evidence.

```markdown
# Work order <id>: <title>

## Your role
<Git operator or mechanic preamble>

## Outcome
<one sentence>

## Commands
Run in this order; every command names its directory:
1. `git -C <dir> <command>` (Git) or `cd <dir> && <command>` (Easy)
2. `git -C <dir> <command>`

## Expected
<e.g. "step 3 prints `## feat/x...origin/main`">

## Report
### Command output
<each command line, then its complete output, or, for a command the order sends to a capture, its exit status and the capture path; "(no output)" when empty>
### Deviations
<"None." or the first failing command with its full error>

<!-- ===== cut line ===== -->
## Revisions
- v1: initial
```

## Standard command lists

In real orders every command carries the repository directory on the same line (`git -C <dir> ...`, `gh ... --repo <owner>/<name>` or `cd <dir> && gh ...`), and literal paths are quoted; both are omitted below for brevity.

- **Baseline** (first Git node): `git rev-parse --absolute-git-dir`, `git rev-parse HEAD`, `git status --porcelain`, `git diff`, `git diff --cached`, plus any read-only discovery (`git log -10 --oneline`, `gh issue view <n>`). These show no untracked file contents: the mister `Read`s relevant untracked files itself.
- **Branch** (only when the approved plan creates one): first, as a read-only node, `git branch --list <branch>` and `git worktree list`; an existing branch or a worktree already on it is an environment stop to report, not a failed `switch -c`. Then `git fetch --prune origin`, `git remote set-head origin -a`, `git switch -c <branch> --track origin/<base>` (or `origin/HEAD`), `git rev-parse HEAD`, `git status -sb`. Persist the returned full SHA and report under `## Task base` before task work. For a current-branch workflow, instead run a read-only Git node with `git rev-parse HEAD` before task work and persist its SHA and report there. The task base is immutable and distinct from the starting HEAD recorded under Baseline; if missing or ambiguous on resume, committed comparisons are unverified, never inferred from current HEAD.
- **Preflight** (read-only, workers idle): `git diff --no-renames --name-status <task-base-sha>..HEAD`, `git diff --no-renames <task-base-sha>..HEAD`, `git status --porcelain`, `git diff`, `git diff --cached`. First compare every committed changed path with the approved ownership union; `--no-renames` exposes a rename as both deleted and added paths. An unowned committed path fails even when status is clean. Read the full committed diff to check owned-path hunks too. Then compare status, the full unstaged diff and the full cached diff with Baseline; an out-of-scope edit inside an already-dirty file must not escape. These comparisons preserve protected baseline content and never treat baseline dirtiness as ownership. The mister checks, by name: lockfiles in the diff (a change not owned by a node allowed to add a dependency fails the preflight; installs rewrite resolved URLs to mirrors); generated files in the status whose content did not change (left out of `git add`); and the Baseline's protected untracked paths, still present and unchanged. Status shows only that an untracked path exists, not that its bytes survived, so an Easy node records `shasum -a 256 <protected untracked paths>` under Baseline and re-runs it after each commit; any changed digest stops the run. When the change was reviewed, the preflight also recomputes the raw identities (`git hash-object --no-filters <task paths>`), modes and symlink targets and compares them with the review's content manifest (`review.md`), without touching the index.
- **Stage** (after the preflight passes, workers still idle): `git add <explicit paths>`, then `git ls-files -s <task paths>` and `git diff --cached --name-status`. The mister compares the staged path, mode and blob set, deletions included, with the manifest's staged identities; the commit node is dispatched only on a match and with no unverified path left.
- **Commit** (after the stage node matched): `git commit -F <git-dir>/the-mister/<slug>/orders/<id>.msg`, `git log -1 --format='%H%n%B'`, `git status --porcelain` (presence of the protected untracked paths; their digests are re-checked by the Easy node described under Preflight).
- **Push**: `git push -u origin <branch>`, `git status -sb`. **PR**: `gh pr create --title <title> --body-file <path the mister wrote>` (or `glab mr create`), then `gh pr view --json url`.

## Captures

Cheap workers asked to paste long output summarise it, and a re-request often brings another summary. So capture by default. Every diff, and every command whose output may exceed about 40 lines (a test suite, a lint run, a file listing), writes its output to `<git-dir>/the-mister/<slug>/captures/<id>.<n>.out`, where `<n>` counts captures for the node. The report pastes, for each captured command, its exit status and the capture path; an Easy node records the size and SHA-256, and you `Read` the file. Short outputs are pasted in full. When the rendering of a pasted report is in doubt (escaped characters, output that looks trimmed, two reports that disagree), stop trusting the text and capture the bytes the same way, with `<id>` the doubted node.

- **Directory**: git does not create it (`--output` into a missing directory exits 128), so the first capture of a run is preceded by an Easy node running `mkdir -p <git-dir>/the-mister/<slug>/captures`.
- **Git output**: a read-only Git node re-runs the command with git's own output flag, `git -C <dir> log -1 --format=format:%B --output=<capture path>` or `git -C <dir> diff --output=<capture path>` (log, show, and diff take it; `status` does not, so capture `git diff` and `git diff --cached` instead). The report pastes the command's exit status; a non-zero exit means no trustworthy capture. The shipped Git operator was observed to be denied `>` redirection in the tested setup; all runtimes prohibit it by instruction (see `agents/claude-code.md` for the enforcement limits).
- **Any other command**: an Easy node runs `cd <dir> && <command> > <capture path> 2>&1; echo "exit=$?"`, so the exit status survives the redirection.
- **Size and hash**: an Easy node runs `wc -c <capture path>` and `shasum -a 256 <capture path>`; record both in the node's evidence. Compare the size with what the doubted report implied: a capture much shorter than the report suggests was truncated or failed.

Then `Read` the capture yourself. The file is the evidence; the reports about it are not.

`captures/` holds only `<id>.<n>.out` files and, for visual evidence, the few screenshots a reviewer looked at (`<id>.<n>.png`). Caches, browser profiles, temporary directories, build outputs, binaries and source copies never go there.

## Scratch and caches

The state directory lives inside `.git`, where `git status`, `git worktree remove` and the user's usual cleanup never see it, so anything left there stays forever. Keep it small:

- **Toolchain caches are shared.** Orders leave `GOCACHE`, `GOMODCACHE`, `GOPATH`, the golangci-lint cache, npm/pnpm/yarn/cargo caches and installed tools at the user's defaults; never point them into the state directory, `captures/` or `scratch/`. Go's build and module caches are content-addressed and safe for concurrent processes, so a private cache adds no correctness, only a cold build and gigabytes per run. Use `go test -count=1` to defeat test result caching. If a worker cannot write a default cache (sandboxed or read-only home), use one shared path outside the git dir, such as `${XDG_CACHE_HOME:-$HOME/.cache}/the-mister/<tool>`, reused by every run, and record it under Assumptions.
- **Per-run scratch goes under `scratch/`.** `TMPDIR`, `go test -work` directories, built binaries, downloaded fixtures and anything an order lists under "Allowed test outputs" live at `<git-dir>/the-mister/<slug>/scratch/<id>/`. Prefer a worktree (a Git node) to copying the source tree; when a copy is unavoidable, it goes under `scratch/` too. Every output path in an order is absolute: a relative one has landed in the repository.
- **Large artefacts are scratch, never captures.** Caches are not the only large artefacts: browser profiles, compiled binaries, copied source trees, archives and downloaded tools can each reach hundreds of megabytes. Browsers run with `--user-data-dir=<git-dir>/the-mister/<slug>/scratch/<id>/profile`. Built binaries, downloaded tools, extracted archives and tree copies go under `scratch/<id>/`. When one of them is evidence, its size and SHA-256 go in a capture, not the artefact.
- **Image builds never see the git dir.** A `docker build` whose context contains `.git` sweeps in the state directory and can break the image. Build from a context under `scratch/<id>/`, or confirm first that `.dockerignore` excludes `.git` and `**/.git`.
- **Scratch is removed at the end.** At any terminal state, before the report (Step 9), an Easy node runs `rm -rf '<git-dir>/the-mister/<slug>/scratch'` and `du -sh '<git-dir>/the-mister/<slug>'`, and the size goes in the report. When stopping `incomplete` and a resume needs the scratch, keep it and name its size and path under Open items.

## The .msg file

Conventional Commits subject and body, a blank line, then one `Co-Authored-By: <display name> <address>` per distinct implementing model recorded in the accepted nodes' `done` lines, with display names and address from the runtime file. Never derive it from `tier` and never invent an identity; if the runtime reports no model, record what you dispatched under Assumptions and use that. The operator never types or edits this file. The reported `git log` body must equal it. When a report's rendering is in doubt, `git log -1 --format=%B | grep -c '<address>'` is a narrow diagnostic for escaped angle brackets only; for whole-message equality use `git log -1 --format=format:%B | diff - '<git-dir>/the-mister/<slug>/orders/<id>.msg'`, which prints nothing and exits 0 when they match (`format:` suppresses the extra terminator that plain `--format=%B` appends; write the `.msg` with one final newline and no trailing blank lines, since `git commit` strips them).

## Writing orders

- **Verbatim beats described** for mechanical or fragile edits. Describing costs a retry; writing costs a minute.
- **Outcomes beat recipes** for Hard and Medium. Dictating the edits makes your blind spots the worker's; state the behaviour, the invariants, the consumers you know of, and how it is verified, and let the engineer find what you did not.
- **Name the pattern by path and line.** "Follow the existing pattern" fails; "copy the shape of `internal/api/gadget_handler.go:40-88`" succeeds.
- **A permitted dependency owns its manifests**, or the preflight fails the node for doing what it was allowed to do.
- **Tools that run git underneath are git.** `docker build` with `.git` in its context, Go's VCS stamping, a hook, and a shell `diff` function that wraps `git diff` all run git. Orders for them set `GOFLAGS=-buildvcs=false`, build from a context without `.git`, and call `cmp` or `/usr/bin/diff`; otherwise the step is a Git node.
- **Every command names its directory on the same line.** `git -C <dir> status`, `cd <dir> && make test`. A "run from" sentence above the list gets lost, and a worker in the wrong directory fails or, worse, succeeds on the wrong tree.
- **Old text is re-read, not remembered.** Before writing a replacement, `Read` the file on the branch the worker will edit. Text copied from memory, the base branch, or another checkout can match nothing, or match the wrong version, and costs a retry.
- **Focused checks reach dependents and lint.** A node's required checks include the repository's linter on the changed packages and the tests of every package that imports a changed symbol, not only a `-run` selection of the node's own tests. Otherwise lint errors and broken dependents surface only at the full checks.
- **Run the acceptance check before you dispatch.** Every criterion you can check with `Grep` or `Read`, check now against the current state: it must measure the value, not the whole line it sits on, and only the lines that matter (a grep over whole files when only added lines count passes or fails for the wrong reason). Note the baseline value it should move from.
- **Flags exist in the installed version.** A Git order uses only flags you have seen work in this repository's tools; when unsure, a read-only Git node runs `<tool> <subcommand> --help` first.
- **Easy means literal.** An Easy order's Changes section is exact strings and exact commands. If the worker would have to interpret a sentence, the node is Medium.
- **Documentation orders say where the facts come from.** Name the files to start from, state the invariant the examples must keep (for example "every example uses the actual API and runs"), and expect a Sources section in the report.
