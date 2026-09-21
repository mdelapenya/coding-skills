---
name: pr-reviewer
description: Perform a rock-solid, multi-pass adversarial review of a pull request. Works from inside the matching repo (bare PR number, infers org/repo from git remote) or from a barebones directory (PR URL or org/repo#num shorthand). Clones the PR head into a temp dir, or uses the current branch when it is already the PR. Runs an adversarial first pass, then re-evaluates and challenges its own findings to drop false positives and confirm real ones. Designed to be invoked iteratively in a loop until findings converge. Use when user says "review this PR", "adversarial review", "deep PR review", "challenge this PR", "audit this pull request", "stress test the PR", or "pr reviewer".
allowed-tools: Read Grep Glob Bash(jq *) Bash(git *) Bash(gh *) Bash(glab *) Bash(mkdir *) Bash(test *) Bash(ls *) Bash(date *) Bash(basename *) Bash(dirname *) Bash(rm *) EnterPlanMode ExitPlanMode AskUserQuestion
metadata:
  author: mdelapenya
  version: "1.0.0"
---

# PR Reviewer

You are the PR's adversarial reviewer. Your job is to find real problems — bugs, regressions, missing tests, broken invariants, security issues, sloppy abstractions — and then **immediately challenge yourself** so the surviving findings are the ones that genuinely protect the quality of the project.

This skill is built around two ideas:

1. **A single review pass is biased.** First-pass adversarial reviews surface plenty of complaints, but many are wrong, irrelevant, or based on misreading the diff. A second self-challenging pass is what turns "noisy nitpicks" into a trustworthy report.
2. **Reviews get stronger with iteration.** Each loop refines confidence: false positives drop out, real issues get sharper, and new issues surface as you internalize the change.

## Where you can invoke this skill from

Two common ways:

- **From inside the matching repo** (recommended) — pass a bare PR number, or omit `$1` to review the currently checked-out PR branch. The skill takes platform / org / repo from `git remote -v`.
- **From a barebones directory** (no git repo) — pass a PR URL or `org/repo#num` / `group/project!num` shorthand. The skill clones the PR into the current directory (when it is empty) or into a temp dir.

The agent (Claude Code, Copilot, Codex, Gemini, …) drives `gh` / `glab` (or its equivalent MCP server) for fetch and clone. Each agent's topic file under `references/agents/` covers any agent-specific quirks and the loop primitive that agent supports.

## Arguments

- `$1` — PR identifier. **Optional**. Accepts any of:
  - **Bare PR number** (`123`) — requires being inside a git repo with the matching remote
  - **URL** — `https://github.com/<org>/<repo>/pull/<n>` or `https://gitlab.com/<group>/<project>/-/merge_requests/<n>` (self-managed GitLab hosts work too)
  - **Shorthand** — `<org>/<repo>#<n>` (GitHub) or `<group>/<project>!<n>` (GitLab)
  - **Omitted** — review the currently checked-out PR branch (requires being inside a git repo)
- `--rounds=N` — Maximum loop rounds (default: **3**). The loop also exits early on convergence.
- `--no-loop` — Run a single round (Steps 1–7) and stop, even if findings have not converged.

## State

`<base-dir>/findings.md` (resolved in Step 4) is the only persistent file this skill writes for its review state. It is the input to every round after the first — the source of truth for what has been claimed, challenged, confirmed, or retracted so far. If the file does not exist, this is round 1.

The base dir is computed, never gitignored — see Step 4.

## Workflow

### Step 1: Resolve platform / org / repo / number

Determine `(platform, org/repo, number)` from `$1` and the current directory. Three input shapes:

- **`$1` is a URL or shorthand** (`https://github.com/...`, `https://gitlab.com/...`, `<org>/<repo>#<n>`, `<group>/<project>!<n>`) → parse it directly. The current directory does not need to be a git repo. Detect platform from the URL host or the `#` vs `!` separator (`#` → GitHub, `!` → GitLab).
- **`$1` is a bare PR number** → the current directory must be inside a git repo. Run `git remote -v` and take the first fetch URL. Parse platform (`github.com` → GitHub, `gitlab.com` or self-managed → GitLab) and `org/repo` from it. Combine with `$1` as the number.
- **`$1` omitted** → the current directory must be inside a git repo. Resolve platform / org / repo as above, then discover the PR number from the currently checked-out branch (Step 2a).

Derive `repo-slug` as `basename` of `org/repo` for use in temp paths.

Stop with a clear error only when the inputs are genuinely incompatible:

- Bare number passed and the current directory is not a git repo → ask the user to either `cd` into the repo or re-run with a URL / shorthand.
- `$1` omitted and the current directory is not a git repo → ask the user to either `cd` into the repo or pass a URL / shorthand.

A URL / shorthand input **always works**, regardless of where you run the skill from.

### Step 2: Resolve the review tree

The steel-man (Step 6) and the cross-reference pass (Step 7a) read **actual source files**, not just the diff. Decide where those reads happen based on the inputs from Step 1 and the state of the current directory.

#### 2a. `$1` omitted — review the current branch

Query the platform to confirm the current branch is the head of a PR (`gh pr view --json number,headRefName` on GitHub, `glab mr view --output json` on GitLab).

If the current branch is **not** associated with any PR, **stop immediately** and tell the user:

```
The current branch "<branch>" is not associated with a pull request.
Either:
  1. Check out the PR you want to review (e.g., `gh pr checkout <num>`) and re-run, or
  2. Re-run with the PR number, URL, or shorthand: `/pr-reviewer <id>`.
```

The skill never invents a PR to review. A branch being ahead of `main` does not make it reviewable.

If the platform confirms a PR, verify `git rev-parse --abbrev-ref HEAD` matches the PR's head ref. If they differ, stop and surface the mismatch. Otherwise the **review tree** is the current working directory. Do not modify it.

#### 2b. `$1` provided — pick a clone target, then clone

Look up the PR's head ref via the platform (`gh pr view <num> --repo <org>/<repo> --json headRefName,headRefOid`, or the equivalent on GitLab) and resolve the remote URL (e.g., `gh repo view <org>/<repo> --json sshUrl,url`).

Pick the clone target based on the current directory:

1. **Cwd is empty (or barebones)** — entries are limited to ignorable junk like `.DS_Store`, or only an empty `.git` placeholder. Clone target = `.` (the current directory). This is the "I opened an empty folder to review a PR" workflow.
2. **Cwd is the matching repo, and the PR is already checked out** (`git rev-parse --abbrev-ref HEAD` matches the PR's head ref) — no clone needed. Review tree = current directory.
3. **Anything else** (cwd is the matching repo but PR not checked out, or cwd is an unrelated repo, or cwd has unrelated files) — clone into a temp dir keyed by repo and PR number:
   ```
   TARGET="${TMPDIR:-/tmp}/pr-reviewer/<repo-slug>/<num>/source"
   ```

Run the clone (cases 1 and 3 only):

```bash
mkdir -p "$(dirname "$TARGET")"
git clone --depth=50 --branch "<pr-head-ref>" "<REMOTE_URL>" "$TARGET"
```

`--depth=50` gives cross-reference grep some history to walk; bump it if a finding needs more. If `$TARGET` already exists from a previous round, **do not re-clone** — `cd` in and `git fetch --depth=50 origin "<pr-head-ref>" && git reset --hard FETCH_HEAD` to pick up any new commits.

The skill never deletes the clone automatically. Cleanup is `rm -rf` on the parent directory (or on the cwd itself, in case 1).

The **review tree** is `$TARGET` (cases 1 and 3) or the current directory (case 2). The user's surrounding state is never touched.

### Step 3: Fetch the PR context

From inside the review tree (or via the platform tool — both work), gather all of:

- **Metadata**: title, body, author, base branch, head branch, URL
- **Commits**: full subject + body for every commit (use `git log --format='%H %s%n%n%b'` on the cloned head ref; do **not** trust truncated subject-only lists)
- **Diff**: the unified diff against the base branch (`gh pr diff <num>` / `glab mr diff <iid>` / `git diff <base>...<head>`)
- **Linked issues**: extract `#N`, `Closes`, `Fixes`, `Resolves`, full URLs from the PR body and commit messages; fetch each issue's title and body (`gh issue view <n>` / `glab issue view <n>`)
- **Files touched**: list of paths the PR modifies (`gh pr view --json files` / extract from diff)

Modern coding agents are competent with `gh` and `glab`; pick the commands you prefer. The skill does not prescribe which tool — it only requires that the five categories above are loaded into your working context before Step 5.

If any category is unobtainable (e.g., outbound network is blocked and you have no cached copy), stop and tell the user exactly what is missing. Do not proceed with a partial review.

### Step 4: Resolve the base dir (for findings.md)

The base dir holds `findings.md`, and in the cloned-PR case it is the parent of the `source/` directory created in Step 2b.

1. If `.biomelab/` exists at the repository root → `.biomelab/pr-reviewer/<pr-number>/`
2. Otherwise → `${TMPDIR:-/tmp}/pr-reviewer/<repo-slug>/<pr-number>/`

Create it with `mkdir -p`. Determine the round number by checking whether `findings.md` exists. If it does, this is round N+1 where N is the highest round recorded in the file. Nothing is ever written into the review tree itself, so no `.gitignore` entry is needed.

### Step 5: Enter plan mode and perform the adversarial first pass

Call `EnterPlanMode`. The first pass is **adversarial by design**: assume the PR is wrong until proven otherwise.

Walk the diff hunk by hunk and interrogate each change against these axes. For every concern, write a finding even if you are not yet sure — Step 6 will challenge them.

- **Correctness**: off-by-one, null/undefined, error swallowing, unhandled branches, race conditions, ordering bugs, lost return values
- **Regression risk**: behavior changes not called out in the PR description; renamed/removed APIs without migration; silent default changes
- **Test coverage**: are the new branches actually executed by the new tests? Mocks that fake away the thing being tested? Asserts that always pass?
- **Security**: input validation, injection sinks, secret handling, authz/authn changes, deserialization, SSRF, path traversal
- **Performance**: N+1 queries, accidental O(n²), unbounded allocations, hot-path locks, sync calls in async contexts
- **API/contract**: backwards compatibility, breaking changes, public vs internal exposure, error shape changes
- **Maintainability**: dead code, premature abstraction, naming, scope creep, surprising coupling
- **Scope vs intent**: does the diff match the PR description and linked issues? Anything that looks unrelated?
- **Commit hygiene**: messages that contradict the diff, "wip"/"fix" without context, force-pushed history

Each finding must include:

```
- id: F-<short-stable-slug>
  file: <path>:<line-or-range>
  category: <correctness|regression|tests|security|performance|api|maintainability|scope|hygiene>
  severity: <blocker|major|minor|nit>
  claim: <one-sentence statement of the problem>
  evidence: <quote the exact code or behavior you are reacting to>
  reasoning: <why this is a problem in this codebase>
  status: pending-challenge
```

When you finish the pass, call `ExitPlanMode` with the list of findings as the plan. The user does not need to approve a code change — the plan *is* the first-pass review. Proceed to Step 6 once plan mode exits, regardless of whether the user explicitly approved, since the next steps are read-only analysis.

### Step 6: Self-challenge each finding (steel-man pass)

For every finding from Step 5, switch sides: become the PR author defending the change. For each finding, do **all** of the following. **All file reads happen inside the review tree** resolved in Step 2 — never against the user's untouched working directory unless that *is* the review tree.

1. **Re-read the surrounding code** — not just the diff, but the file and any callers/callees touched. Many first-pass findings collapse when you read 20 lines above and below.
2. **Check whether the concern already has a mitigation** elsewhere in the diff or codebase (a helper, a guard, an earlier validation, a framework default).
3. **Check the linked issues and PR description again** — the "scope creep" you flagged may be the explicit ask in the issue.
4. **Look at the tests** — is there a test that already exercises the path you claimed is uncovered?
5. **Construct the strongest defense** the PR author could give. Write it down verbatim.

Then re-classify the finding:

- `confirmed` — the steel-man failed; the concern is real and you have evidence
- `weakened` — partially correct but smaller than first claimed; rewrite the claim to be precise
- `retracted` — the steel-man wins; mark it retracted with a one-line reason
- `needs-info` — cannot be resolved without input from the author or runtime evidence; record what would resolve it

Update each finding's `status` and append a `challenge:` and `verdict:` block:

```
- id: F-null-session-handling
  ...
  status: confirmed
  challenge: "The middleware in auth/guard.go runs before this and rejects nil sessions."
  verdict: "Steel-man fails — guard.go is only mounted on /api/*, and this handler is also mounted on /webhook/*, where guard.go is not in the chain."
```

### Step 7: Cross-reference and convergence check

Two checks before writing the report:

**7a. Cross-reference across the codebase.** For each `confirmed` finding, `grep`/search **inside the review tree** for similar patterns. If the "problem" you flagged is the established convention, downgrade or retract — this codebase has spoken. If similar code elsewhere also has the bug, note it as a related risk but do not expand the PR's scope into a refactor.

**7b. Convergence check (only if this is round 2 or later).** Read the previous round's findings from `<base-dir>/findings.md`. Compare:

- Findings that survived unchanged across two rounds are **stable confirmed**.
- Findings that flipped between confirmed/retracted across rounds are **unstable** — re-read the code one more time and pick a side with explicit reasoning.
- New findings introduced this round are **fresh** — they will need their own steel-man on the next round.

If no findings changed category between this round and the previous, **the review has converged** — record that and skip directly to Step 8 with the loop exit flag set.

### Step 8: Write findings to the state file

Append (do not overwrite) this round's findings to `<base-dir>/findings.md`. Each round is a self-contained section:

```markdown
## Round <N> — <YYYY-MM-DD HH:MM>

### Confirmed (stable across rounds: yes/no)
- ...

### Weakened
- ...

### Retracted (with reason)
- ...

### Needs info
- ...

### Convergence
- changed-from-previous: <count>
- converged: <true|false>
```

If `converged: true`, `--no-loop` was passed, or the round count has reached `--rounds`, do **not** schedule another round. Otherwise, see Step 9.

### Step 9: Looping

This skill is built to be re-invoked. Each invocation runs one full pass (Steps 1–8) and reads/writes the same state file. The clone is reused (refreshed via `git fetch && git reset --hard`) on subsequent rounds.

The loop primitive depends on the agent. Read the relevant `references/agents/<agent>.md` for the exact syntax, where `<agent>` is `claude-code`, `codex`, `copilot`, `gemini`, or `generic`. The skill's job is only to **decide whether another round is warranted** — it never starts a loop automatically. After writing findings, present:

```
Round <N> finished — converged: <yes|no>, changed-from-previous: <count>.
To continue iterating, see references/agents/<agent>.md for the loop command.
```

If converged or `--no-loop` was passed, do not suggest the loop.

### Step 10: Final report (only on the last round)

When the loop exits (converged, hit `--rounds`, or `--no-loop`), produce the final report from the state file. Group findings by severity, then category:

```markdown
# Review of PR #<num>: <title>

**Rounds run**: <N>   **Converged**: <yes|no>

## Blockers
- [file:line] <claim>
  - Evidence: <quoted code>
  - Why it matters: <one line>
  - Suggested action: <one line>

## Major
...

## Minor / nits
...

## Retracted on review (transparency)
- <claim> — retracted because <reason>

## Open questions for the author
- <needs-info items>
```

**The report ends after "Open questions for the author."** It must **not** contain a "Posting this review", "Next steps", "How to post", or similar section. The report is the review — nothing more.

Posting is handled separately, **after** the report is printed:

1. Print the report exactly as structured above and stop.
2. Then call `AskUserQuestion`:
   > Post this review as a PR comment? [Y/n]
3. Only if the user confirms, run `gh pr review <num> --comment --body-file <path>` (or the agent equivalent). If declined, end the turn.

Do not mention posting inside the printed report. Do not add a section like `## Posting this review` to the report body. The posting prompt is a separate user-facing question, never part of the report markdown.

## Design notes

- **Why does the skill drive the fetch?** Earlier drafts framed fetching as a prerequisite the user satisfied manually, which made the simple case ("review PR #N from this repo") awkward. Modern coding agents are competent with `gh`/`glab`; the skill just tells them what to fetch and lets them choose the tool.
- **Why plan mode for round 1?** The first pass should produce *findings*, not edits. Plan mode is the safest way to enforce that: you cannot accidentally start "fixing" the PR mid-review.
- **Why steel-man instead of just "re-check"?** Re-checking your own work is biased toward confirming it. Forcing yourself to argue the *other side* is what surfaces the real false positives.
- **Why a state file?** Without one, every loop iteration starts from scratch and the review never compounds. The file is what lets convergence work.
- **Why does the skill not start its own loop?** Looping is an agent capability, not a review capability. The skill reports whether another round is warranted; the agent (or the user) decides how to iterate.
- **Why a clone instead of `git checkout` (or `git worktree`)?** Switching the user's working branch out from under them is a surprising side effect — that rules out `git checkout`. A shallow clone keeps the user's directory untouched, has no hidden coupling to the parent repo's object store, and cleans up with a plain `rm -rf` (no `git worktree remove` dance, no orphaned metadata). The disk and network cost of a `--depth=50 --branch=<head>` clone is negligible compared to the simplicity it buys.
- **Why support both "inside the repo" and "barebones dir"?** Running from inside the repo lets you pass a bare PR number — the most common case. Running from a barebones dir with a URL or shorthand handles the "I want to review a PR but I do not have the repo checked out anywhere" case without forcing the user to clone first. Both paths converge on the same review logic.
- **Why does the report never mention posting?** The report is the review artifact. A "Posting this review" section is workflow chatter that pollutes the artifact and tends to leak into copy-pastes. Posting is a separate `AskUserQuestion` after the report is printed.
