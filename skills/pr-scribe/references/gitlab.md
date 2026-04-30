# GitLab

Platform-specific commands for describing merge requests on GitLab using `glab`.

## Detect

The repository uses GitLab if `git remote -v` shows `gitlab.com` (or any self-managed GitLab) URLs.

## Notes on `glab`

- `glab api` does **not** support a `--jq` flag. Pipe to `jq` in the shell instead.
- Use `:fullpath` as the project identifier — `glab` auto-fills it from the current Git remote (e.g. `glab api projects/:fullpath/merge_requests/123`). Otherwise URL-encode `namespace/repo` as `org%2Frepo`.
- Most `glab mr` subcommands accept either `<iid>` or `<branch>`, and resolve the current branch's MR when called with no argument.
- `glab` uses `-O, --output json` (capital O) for machine-readable output. `glab issue list` uses `-P, --per-page` (no `--limit`).

## Fetch MR metadata and diff

```bash
glab mr view <iid> --output json
glab mr diff <iid> --raw
```

The MR JSON mirrors the GitLab REST [merge request object](https://docs.gitlab.com/ee/api/merge_requests.html) — useful fields include `title`, `description`, `source_branch`, `target_branch`, `web_url`, and `detailed_merge_status`.

For the commit list (not included in `glab mr view`):

```bash
glab api projects/:fullpath/merge_requests/<iid>/commits | jq '[.[] | {id, title, message}]'
```

## MR template paths

GitLab looks for templates in this order:

1. `.gitlab/merge_request_templates/*.md` — explicit named templates
2. `.gitlab/merge_request_templates/Default.md` — applied automatically when no template is selected (case-insensitive)

Group-level templates come from a designated template project; if the project doesn't override them, they apply but live outside the repo.

## Search for related issues

```bash
glab issue list --search "<terms>" --per-page 5 --output json
```

## Update MR title and description

`glab mr update` does **not** accept a description file flag. Read the description body via shell command substitution:

```bash
glab mr update <iid> \
  --title "<conventional-commits-title>" \
  --description "$(cat /tmp/pr-description-<iid>.md)"
```

To update only the title:

```bash
glab mr update <iid> --title "<conventional-commits-title>"
```
