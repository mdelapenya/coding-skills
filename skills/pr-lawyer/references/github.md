# GitHub

Platform-specific commands for responding to PR review comments on GitHub.

## Detect

The repository uses GitHub if `git remote -v` shows `github.com` URLs.

## Fetch unresolved review comments

```bash
gh api repos/<org>/<repo>/pulls/<number>/comments \
  --jq '[.[] | {id, path, line, body, user: .user.login, in_reply_to_id}]'
```

For PR-level (issue) comments:
```bash
gh api repos/<org>/<repo>/issues/<number>/comments \
  --jq '[.[] | {id, body, user: .user.login}]'
```

## Fetch PR diff for context

```bash
gh pr diff <number> --repo <org>/<repo>
```

## Reply to a review comment

```bash
gh api repos/<org>/<repo>/pulls/<number>/comments \
  --method POST \
  --field body="<reply>" \
  --field in_reply_to=<comment-id>
```

## Reply to a PR-level comment

```bash
gh api repos/<org>/<repo>/issues/<number>/comments \
  --method POST \
  --field body="<reply>"
```

## Resolve a comment thread (mark as resolved)

GitHub does not support resolving individual comments via the API directly. Threads are resolved through the web UI or when a review is submitted. After pushing fixes, the reviewer typically resolves their own threads.
