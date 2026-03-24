# GitHub Actions

Platform-specific commands for investigating CI failures on GitHub Actions.

## Detect

The repository uses GitHub Actions if `.github/workflows/` exists.

## Get PR and failing checks

```bash
gh pr view --json number,title,headRefName,statusCheckRollup
```

## Get failing jobs from a run

```bash
gh run view <run-id> --json jobs --jq '.jobs[] | select(.conclusion == "failure") | {name, conclusion}'
```

## Get failure logs

```bash
gh run view <run-id> --log-failed
```

## List recent runs of a workflow

Use `$1` (default: 10) as the `--limit` value, filtering to completed runs on other branches:

```bash
gh run list --repo <org>/<repo> --limit <$1 or 10> \
  --json databaseId,conclusion,workflowName,headBranch \
  --jq '[.[] | select(.workflowName == "<workflow>" and .conclusion != "" and .headBranch != "<current-branch>")] | .[0:5]'
```

## Check specific jobs in a run

```bash
gh run view <id> --json jobs --jq '.jobs[] | select(.name | test("<failing-job-pattern>")) | {name, conclusion}'
```

## Get PR diff

```bash
gh pr diff
```
