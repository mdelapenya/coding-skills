# Plan and work orders

Everything the mister writes lives at `<git-dir>/the-mister/<slug>/`: `plan.md`, `orders/<id>.md`, `orders/<id>.msg`. Nothing else.

## plan.md

Written once the plan is approved; its existence means approval. If it already exists for the slug, resume it.

```markdown
# <Task title>

**Slug**: <slug>   **Git dir**: <output of `git rev-parse --absolute-git-dir`>
**Base branch**: <branch>   **Work branch**: <branch or "current">

## Request
<verbatim>

## Assumptions
- <each choice made without asking: base branch, reading of the request, runtime and the model names used in trailers>

## Baseline
<`git status --porcelain`, then `git diff` and `git diff --cached` when not clean, then the content of any untracked file a node may touch; or "clean". Protected user content, never committed by the squad.>

## Nodes

- id: N02-widget-model
  title: Add Widget model and its tests
  tier: medium              # hard | medium | easy | git; edited in place if the node is re-tiered
  deps: [N01-git-baseline]
  owns: [internal/widget/widget.go, internal/widget/widget_test.go]
  reads: [internal/gadget/gadget.go]
  acceptance:
    - "widget.go defines `type Widget struct` with fields ID string, Name string, CreatedAt time.Time"
    - "`go test ./internal/widget/...` from the repo root exits 0"
  status: pending           # pending | running | done | failed
  evidence: ~               # on done: dispatched model identity (alias or id, plus role), acceptance results, commit hash if any

## Log
- N02-widget-model dispatched (1/3, general-purpose, sonnet).
- N02-widget-model failed: acceptance 1, CreatedAt missing. Cause: order gap, the field list was prose. Order v2 shows the struct verbatim. Dispatched (2/3, general-purpose, sonnet).
```

Rules:

- Ids are `N<nn>-<kebab-slug>` in creation order; order file `orders/<id>.md`, message `orders/<id>.msg`.
- `owns` is exclusive among `running` nodes. A committing Git node owns the paths it stages; read-only Git nodes own nothing. A permitted dependency's manifest and lock files belong to the node allowed to add it.
- Git mutations are serialized. A Git node that rewrites the worktree (`switch`, `checkout --`, `clean`, `worktree add`, `merge`) dispatches only when nothing is `running`.
- A node is ready when every dependency is `done` with still-valid evidence; if a prerequisite is redone, re-check its dependents' evidence.
- Every dispatch is logged with its count so the three-dispatch budget survives resume. The Log is append-only; order is the timestamp.
- `evidence` records the model identity as dispatched (Claude Code: the `model` alias and `subagent_type`; Codex: the `model` passed, or the role's configured model), never the worker's self-description and never `tier` after the fact. Trailers derive from it.

## Preambles

Canonical role texts. The shipped agents and any Codex TOML quote them; change them here first. They are instructions: a worker whose tools include spawning or a shell is not structurally prevented from disobeying. Only the shipped agents' tool lists enforce (see the runtime file).

**Engineer** (Hard and Medium):

```
You are a <tier> engineer on a squad. You do exactly what this order says, nothing more.
You never run `git`, `gh`, or `glab`, not even read-only commands like `git status` or `git diff`, and not indirectly through a script, a make target, or an MCP tool. You run the verification commands this order lists yourself and paste their output. You never spawn agents.
If part of this order needs more capacity or judgment than you have, or if anything in it turns out to be false (a file is missing, a function has a different signature, a test already exists), STOP and report it under "Deviations". Do not improvise around it.
```

**Mechanic** (Easy):

```
You are the squad's mechanic. You do exactly what this order says, nothing more, and you run the listed commands and edits yourself.
You never run `git`, `gh`, or `glab`, not even indirectly through a script, a make target, or an MCP tool, and you never spawn children. This order contains no git command; if completing it would require one, STOP and report it under "Deviations".
If anything in this order turns out to be false, STOP and report it under "Deviations". Do not improvise around it.
```

**Explorer** (discovery):

```
You are a read-only explorer on a squad. You answer exactly the question in this order, with file paths and line ranges as evidence, and you do not summarise away the evidence.
You never edit, create, or delete a file, and you never run `git`, `gh`, or `glab`, directly or indirectly. If the question cannot be answered without git, say so under "Deviations" and stop.
```

**Git operator** (Git nodes):

```
You are the squad's git operator. You run the `git`, `gh`, and `glab` commands listed under "Commands", exactly as written, in order, from the directory given, and nothing else.
You paste the complete, verbatim output of every command in your report, labelled by command. You never summarise, excerpt, or paraphrase output.
You never edit, create, or delete a file, and you do not work around that with shell redirection. You never run `git add -A` or `git add .`; you stage only the paths listed. You never type a commit message: commits use `git commit -F <path>` with a file someone else wrote, which you do not alter.
If any command fails, STOP immediately, paste the full error under "Deviations", and do not attempt a recovery, a retry, or an alternative command. You do not spawn children and you do not invoke skills.
```

## Full template

For Hard, Medium, Easy edit nodes, and explorers. Everything above the cut line goes to the worker verbatim. The worker has no memory of the plan or the codebase and cannot see this skill directory: inline every fact.

```markdown
# Work order <id>: <title>

## Your role
<preamble>

## Outcome
<one sentence: what exists when you are done that does not exist now>

## Context
<2–6 sentences: why, what the surrounding code does, what runs in parallel so you know the boundaries. Paths and line ranges.>

## Files you own (create or edit these, and only these)
- <path>   <for a baseline-dirty file: "preserve the existing changes at lines a–b as they are">

## Files you may read
- <path> — <what to look at, e.g. "follow the handler shape at lines 40–88">

## Constraints
- Do not edit any file outside "Files you own"; do not refactor or reformat what you were not asked to change.
- Dependencies: <"Add none." | "You may add `<dep>@<version>`; you own <manifest and lock paths>.">
- Do not commit; a Git node will.
- <node-specific>

## Changes
<Numbered steps. Code verbatim when the edit is mechanical or fragile; otherwise the target precisely: signature, behaviour, examples.>

## Acceptance
- [ ] <file> contains <symbol or text>
- [ ] `<command>` run from `<dir>` exits 0
- [ ] <behaviour with a concrete input and expected output>

## Verification
Run yourself, from `<dir>`: `<the command named above>`. Expected: <output>. Paste the last 30 lines.

## Report
Reply with exactly these sections:
### Changed files
- <path> — <what changed>
### Acceptance
- [x] or [ ] per criterion, in order, one line of evidence each
### Verification output
<pasted output, or "not run: <reason>">
### Deviations
<anything done differently, found false, or unclear; "None." otherwise>

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
Run from `<dir>`, in this order:
1. `<command>`
2. `<command>`

## Expected
<e.g. "step 3 prints `## feat/x...origin/main`">

## Report
### Command output
<each command line, then its complete output; "(no output)" when empty>
### Deviations
<"None." or the first failing command with its full error>

<!-- ===== cut line ===== -->
## Revisions
- v1: initial
```

## Standard command lists

All run from the explicit repository directory; quote literal paths in real orders.

- **Baseline** (first Git node): `git rev-parse --absolute-git-dir`, `git status --porcelain`, `git diff`, `git diff --cached`, plus any read-only discovery (`git log -10 --oneline`, `gh issue view <n>`). These show no untracked file contents: the mister `Read`s relevant untracked files itself.
- **Branch** (only when the approved plan creates one): `git fetch --prune origin`, `git remote set-head origin -a`, `git switch -c <branch> --track origin/<base>` (or `origin/HEAD`), `git status -sb`.
- **Preflight** (read-only, workers idle): `git status --porcelain`, `git diff`, `git diff --cached`. The full unstaged diff, so an out-of-scope edit inside an already-dirty file cannot escape the comparison.
- **Commit** (after the preflight passes, workers still idle): `git add <explicit paths>`, `git commit -F <git-dir>/the-mister/<slug>/orders/<id>.msg`, `git log -1 --format='%H%n%B'`.
- **Push**: `git push -u origin <branch>`, `git status -sb`. **PR**: `gh pr create --title <title> --body-file <path the mister wrote>` (or `glab mr create`), then `gh pr view --json url`.

## The .msg file

Conventional Commits subject and body, a blank line, then one `Co-Authored-By: <display name> <address>` per distinct implementing model recorded in the accepted nodes' `evidence`, with display names and address from the runtime file. Never derive it from `tier` and never invent an identity; if the runtime reports no model, record what you dispatched under Assumptions and use that. The operator never types or edits this file. The reported `git log` body must equal it. When a report's rendering is in doubt, `git log -1 --format=%B | grep -c '<address>'` is a narrow diagnostic for escaped angle brackets only; for whole-message equality use `git log -1 --format=format:%B | diff - '<git-dir>/the-mister/<slug>/orders/<id>.msg'`, which prints nothing and exits 0 when they match (`format:` suppresses the extra terminator that plain `--format=%B` appends; write the `.msg` with one final newline and no trailing blank lines, since `git commit` strips them).

## Writing orders

- **Verbatim beats described** for mechanical or fragile edits. Describing costs a retry; writing costs a minute.
- **Name the pattern by path and line.** "Follow the existing pattern" fails; "copy the shape of `internal/api/gadget_handler.go:40-88`" succeeds.
- **A permitted dependency owns its manifests**, or the preflight fails the node for doing what it was allowed to do.
