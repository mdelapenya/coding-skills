# GitLab

Platform-specific commands for responding to merge request review comments on GitLab.

## Detect

The repository uses GitLab if `git remote -v` shows `gitlab.com` URLs.

## Fetch unresolved discussion threads

```bash
glab api projects/<project-id>/merge_requests/<iid>/discussions \
  --jq '[.[] | select(.resolved == false) | {id, notes: [.notes[] | {id, body, author: .author.username, resolvable, resolved}]}]'
```

Where `<project-id>` is the URL-encoded `namespace/repo` (e.g. `org%2Frepo`).

## Fetch MR diff for context

```bash
glab mr diff <iid>
```

## Reply to a discussion thread

```bash
glab api projects/<project-id>/merge_requests/<iid>/discussions/<discussion-id>/notes \
  --method POST \
  --field body="<reply>"
```

## Resolve a discussion thread

```bash
glab api projects/<project-id>/merge_requests/<iid>/discussions/<discussion-id> \
  --method PUT \
  --field resolved=true
```

Resolve a thread after fixing the related code to signal the issue is addressed.
