# Full and delta review scope

Pinning the target and selecting the work to review are separate decisions. Every pass verifies the current head/base/merge-base, including when its scope is a delta.

## Choose a baseline

- First review with no stored coverage and no `--since`: full `git diff <merge-base> <head>`. `--full` always selects this scope.
- Follow-up: use the latest earlier revision whose completed passes met the completion gate in `report.md` at its reviewed target (including an established full-review chain), and read its head and merge-base from `findings.md`. Later supersession does not erase that coverage. `finished: true` alone is insufficient: a round cap can finish an incomplete review. Never advance the baseline to an interrupted or partially inspected head; compare from the last completely reviewed head so no intervening change is skipped. If none qualifies, use a full review and say why.
- `--since <sha>` overrides that choice. Resolve it to a unique full commit SHA with `git rev-parse --verify <sha>^{commit}`. Treat the value as a commit identifier, never shell code or an option. Reject invalid values rather than silently choosing another baseline. Use the matching stored revision's merge-base when available. Otherwise, for an ancestor head with unchanged base history, compute `git merge-base <since> <base>`; for rewritten history obtain the old PR base from reliable historical metadata. Never guess an old base from the current base after a rebase. If it cannot be established, report a coverage gap; offer `--full` as the way to cover the PR.
- An explicit baseline without a stored complete review is allowed for a delta-only review. Record that prior coverage and prior findings are unknown. It cannot support a clean verdict or approval for the whole PR.
- Resolve legacy abbreviated SHAs uniquely in the clone. Missing or ambiguous automatic-baseline objects cause a full fallback with the reason recorded. For an explicit `--since`, unavailable objects cause an incomplete review, not an invented baseline.

Only fetch or deepen in the cache clone. If the user's clean checkout lacks baseline objects or sufficient ancestry, switch to that clone. Preserve full SHAs in state; short SHAs are for display.

## Select the comparison

For an ancestor baseline with the same PR merge-base, inspect all of:

```bash
git merge-base --is-ancestor <previous-head> <head>
git diff <previous-head>..<head>
git diff --name-only <previous-head>..<head>
```

If the PR merge-base changed (including merging the target branch), or the previous head is no longer an ancestor (rebase, force-push), compare the two PR commit series:

```bash
git range-diff <old-merge-base>..<previous-head> <merge-base>..<head>
git diff <old-merge-base> <previous-head>
git diff <merge-base> <head>
git diff <previous-head> <head>
```

Use `range-diff` to map unchanged patches and focus on added, removed or modified patches. It is a correspondence aid, not proof of identical behavior: it ignores merge commits and may pair commits heuristically. Reconcile the old and current PR patches with the tree delta to catch dropped changes, merge conflict resolutions and changes in how the PR interacts with the new base. Exclude unrelated upstream churn only after identifying it as such. Record the selected hunks/files and why any unchanged patch still needs attention. If the mapping cannot establish a reliable delta, fall back to full coverage and record why; unavailable explicit baseline history remains a coverage gap.

Read unchanged code only where the delta uses it or can break it: callers, callees, tests, contracts and base changes that affect those paths. Record each widening and the dependency that required it. An unchanged, unrelated defect does not become a new finding just because it is nearby.

An empty delta is a valid result: record the comparison and reconcile earlier findings; do not repeat the full scan. A base-only update still needs the interaction check above.

## Earlier findings

In full scope, re-verify all earlier surviving findings; none are carried as unreviewed.

Preserve stable finding ids. Re-verify a previous finding when its code, evidence, caller or mitigation is affected by the selected scope; a fix must survive the steel-man before it is marked retracted. Carry unaffected surviving findings into a separate report section, with their original reviewed head and status, and say they were not re-reviewed. They still block a clean verdict and approval when their severity warrants it. Do not count carried findings toward convergence; only findings assessed on this revision participate. Interrupted findings are hints, never established coverage or inherited verdicts.

## Reusing scope

Same target and same scope selection: continue the stored rounds, or render the finished report. An explicit `--full` on an existing delta revision, or a different explicit `--since`, opens a new revision at round 1 even on the same target; repeating an identical selection resumes it. Omitting scope flags on the same target resumes the stored scope. Automatic refresh on a moving PR retains `--full` or the explicit `--since` if supplied; otherwise it chooses the last completely reviewed baseline. The refresh budget still bounds automatic restarts, independently of how small the delta is.
