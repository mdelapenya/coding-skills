---
name: ci-detective
description: Investigate CI failures on a PR by cross-referencing failing tests against other recent runs to determine if failures are pre-existing or caused by the PR's changes. Use when user says "investigate CI failure", "is this test flaky", "why is this test failing", "cross-reference builds", "check if failure is pre-existing", or "ci detective".
allowed-tools: Read Grep Glob Bash(gh *) Bash(git *)
metadata:
  author: mdelapenya
  version: "1.0.0"
---

# CI Detective

Investigate CI failures on a PR by cross-referencing failing tests against other recent runs to determine whether failures are pre-existing or introduced by the PR.

**Do not assume failures are pre-existing or infrastructure-related.** Always gather evidence first.

## Supported CI Systems

This skill supports multiple CI platforms. Each platform has its own reference file under `references/` with platform-specific commands and patterns.

Currently supported:
- **GitHub Actions** — see `references/github-actions.md`

Planned:
- GitLab CI
- Jenkins

When investigating, first detect which CI system the repository uses, then load the corresponding reference file for platform-specific commands.

## Arguments

- `$1` — Number of recent runs to query (default: **10**). Example: `/ci-detective 20`

## Workflow

### Step 1: Detect the CI system

Check the repository for CI configuration:
- `.github/workflows/` → GitHub Actions (load `references/github-actions.md`)

If the CI system is not yet supported, inform the user and stop.

### Step 2: Get failing job and test names from the current PR's run

Using the platform-specific commands from the loaded reference, identify the current branch's PR and its most recent failing workflow run. Record the **workflow name**, **failing job names**, and **failing test names**.

### Step 3: Find recent completed runs of the same workflow on other branches

Query the last **`$1`** runs (default: 10) and filter to completed runs on branches other than the current PR's branch. Select 3–5 from the results with a mix of conclusions (prefer at least one passing and one failing if available).

### Step 4: Check if the same jobs/tests fail in those runs

For each selected run, check whether the same jobs failed. If a job failed in another run, fetch its logs to confirm the same test is failing.

### Step 5: Classify each failure

- **Pre-existing**: The same test fails in runs on other branches. Flag it and note which tests.
- **Introduced by this PR**: A test only fails on our PR's run and passes elsewhere. This is the suspect — proceed to Step 6.

### Step 6: Investigate PR-introduced failures

For each failure classified as introduced by this PR:

1. Fetch the full failure output using platform-specific commands.
2. Get the PR diff.
3. Compare the diff against the error output to identify the causal link between the PR's changes and the test failure.
4. Report the root cause and suggest a fix.

### Step 7: Report

Present a summary table:

```
| Test Name | Our PR | Run <id1> (<branch1>) | Run <id2> (<branch2>) | Run <id3> (<branch3>) | Verdict |
|-----------|--------|-----------------------|-----------------------|-----------------------|---------|
| test_foo  | FAIL   | FAIL                  | FAIL                  | FAIL                  | Pre-existing |
| test_bar  | FAIL   | PASS                  | PASS                  | PASS                  | Introduced by PR |
```

For each introduced failure, include:
- The failing test name and error message
- The relevant lines from the PR diff
- A brief explanation of the causal link
- Suggested fix
