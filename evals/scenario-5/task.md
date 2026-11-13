# Investigate CI Failures on the Checkout Refactor PR

## Background

Your team's backend engineer has opened a pull request (`feature/checkout-refactor`) to streamline the cart calculation logic in the storefront service. Before requesting code review, they want a thorough investigation of the three test failures that appeared on the PR's CI run. The goal is to separate any failures that exist on other branches (and therefore aren't the PR's fault) from genuine regressions introduced by this change — and for any new failures, trace them directly to what changed.

The engineer has already pulled down the relevant CI data into local files so the investigation can run offline:

- `inputs/pr-run.json` — the CI run results for the PR (`feature/checkout-refactor`), listing each failing test name, the file/line, and the full error output
- `inputs/other-runs.json` — CI run results from the most recent completed runs of the same workflow on other branches, showing which tests passed or failed in those runs
- `inputs/pr.diff` — the unified diff of all changes introduced by this PR

## Output Specification

Produce a file named `ci-report.md` in the working directory that covers:

1. A summary table showing each failing test, its result on the PR run, its result on each of the reference branch runs (identified by run ID and branch name), and an overall verdict on whether the failure is new to this PR.
2. For any failure that appears to be new to this PR: a root cause section that identifies exactly what in the diff caused it and gives a concrete suggestion for how to fix it.
3. For any failure where the available data is insufficient to reach a verdict: an explanation of why a determination cannot be made from the data provided.
