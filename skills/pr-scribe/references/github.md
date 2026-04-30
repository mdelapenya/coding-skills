# GitHub

Platform-specific commands for describing pull requests on GitHub.

## Detect

The repository uses GitHub if `git remote -v` shows `github.com` URLs.

## Fetch PR metadata and diff

```bash
gh pr view <number> --repo <org>/<repo> --json title,body,baseRefName,headRefName,commits
gh pr diff <number> --repo <org>/<repo>
```

## PR template paths

Check in this order:
1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. `PULL_REQUEST_TEMPLATE.md`
4. `pull_request_template.md`
5. `.github/PULL_REQUEST_TEMPLATE/` directory (use first `.md` file)

## Search for related issues

```bash
gh issue list --repo <org>/<repo> --state open --search "<terms>" --limit 5
```

## Update PR description

Write the description to a temp file named with the PR number to avoid collisions, then:
```bash
gh pr edit <number> --repo <org>/<repo> --body-file /tmp/pr-description-<number>.md
```
