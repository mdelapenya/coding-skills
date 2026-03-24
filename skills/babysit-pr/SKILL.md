---
name: babysit-pr
description: Monitor CI builds and mergeable status for the current branch's PR. Diagnoses failures, merges main to resolve conflicts or pick up fixes, and pushes. Use when user says "babysit this PR", "check CI", "fix the build", "why is CI failing", "merge main", or "resolve conflicts".
allowed-tools: Read Edit Grep Glob Bash(gh *) Bash(git *) Bash(cd *) AskUserQuestion
disable-model-invocation: true
metadata:
  author: mdelapenya
  version: "1.0.0"
---

# Babysit PR

Monitor and fix CI failures and merge conflicts for the current branch's pull request.

**NEVER use `git push --force` or `git push --force-with-lease`.** Always use a regular `git push`. If a push is rejected, stop and ask the user.

## Supported Platforms

This skill supports multiple code hosting platforms. Each platform has its own reference file under `references/` with platform-specific commands.

Currently supported:
- **GitHub** — see `references/github.md`

Planned:
- GitLab
- Bitbucket

When invoked, first detect the platform from `git remote -v`, then load the corresponding reference file for platform-specific commands. If the platform is not yet supported, inform the user and stop.

## Context: Worktree Setup

This skill is typically invoked from a **git worktree**, not the root repository. Understand the two paths:

- **Workspace** (current directory): the worktree where you are editing code — `pwd`
- **Root repo**: the main checkout where `main` branch lives — determined by `git worktree list | head -1 | awk '{print $1}'`

Always return to the workspace after any operation in the root repo.

## Looping

After completing a single run (Steps 1–5), start a `/loop 5m /babysit-pr` to continuously monitor the PR. This ensures CI re-runs and new merge conflicts are caught automatically.

If the user invokes this skill directly (not already inside a loop), ask:

```
Want me to keep babysitting this PR on a 5-minute loop? [Y/n]:
```

If confirmed, start the loop. If declined, run once and stop.

## Workflow

### Step 1: Detect platform and identify the PR

Run `git remote -v` to detect the platform, then load the corresponding reference file.

Using the platform-specific commands from the loaded reference, identify the current branch's PR and fetch its metadata (number, title, branches, mergeable status, CI status).

If no PR exists for the current branch, stop and inform the user.

### Step 2: Check CI status

Inspect the CI status from Step 1. Categorize each check as passing, failing, or pending.

- If all checks pass and the PR is mergeable, report success and stop.
- If checks are still pending, report which ones and stop — do not wait.
- If any checks are failing, proceed to Step 3.
- Regardless of CI status, if the PR has merge conflicts, proceed to Step 4 after handling CI.

### Step 3: Diagnose and fix CI failures

Using the platform-specific commands from the loaded reference, fetch the failing check logs.

Analyze the failure and determine the root cause:

#### 3a: Fix is likely in main (e.g., flaky infra, CI config change, dependency update merged upstream)

1. Save the workspace path: `WORKSPACE=$(pwd)`
2. Get the root repo: `ROOT=$(git worktree list | head -1 | awk '{print $1}')`
3. `cd "$ROOT"` and verify no local changes with `git status --porcelain`
   - If there are local changes, **stop** and ask the user — do not discard their work
4. `git pull`
5. `cd "$WORKSPACE"`
6. `git merge main --no-edit`
   - If there are conflicts, resolve them (see Step 4 for conflict resolution approach)
7. `git push`

#### 3b: Fix is in the branch (e.g., test failure, lint error, compilation error from PR changes)

1. Read the relevant source files and fix the issue
2. Stage and commit the fix with a descriptive message
3. `git push`

After fixing, report what was done. Do not re-check CI — the user can invoke the skill again later.

### Step 4: Resolve merge conflicts

If `mergeable` is `CONFLICTING` or the merge in Step 3a produced conflicts:

1. Save the workspace path: `WORKSPACE=$(pwd)`
2. Get the root repo: `ROOT=$(git worktree list | head -1 | awk '{print $1}')`
3. `cd "$ROOT"` and verify no local changes with `git status --porcelain`
   - If there are local changes, **stop** and ask the user
4. `git pull`
5. `cd "$WORKSPACE"`
6. `git merge main --no-edit`
7. For each conflicted file:
   - Read the file and understand both sides of the conflict
   - Resolve by preserving the intent of both the PR changes and the main branch updates
   - If the correct resolution is ambiguous, ask the user
8. Stage resolved files, commit the merge, and push:
   ```bash
   git add <resolved-files>
   git commit --no-edit
   git push
   ```

### Step 5: Report

Summarize what was done:
- Which CI checks were failing and why
- Whether main was merged in
- Which conflicts were resolved (if any)
- What code fixes were applied (if any)
- Current CI and mergeable status
