# GitHub

Platform-specific commands for babysitting pull requests on GitHub.

## Detect

The repository uses GitHub if `git remote -v` shows `github.com` URLs.

## Identify the PR

```bash
gh pr view --json number,title,headRefName,baseRefName,mergeable,mergeStateStatus,statusCheckRollup
```

## Get failing check logs

```bash
gh run view <run-id> --log-failed
```

## Check mergeable status

The `mergeable` field from `gh pr view` returns:
- `MERGEABLE` — no conflicts
- `CONFLICTING` — merge conflicts exist
- `UNKNOWN` — GitHub is still computing (retry after a few seconds)
