# GitLab

Platform-specific commands for nursing merge requests on GitLab using `glab`.

## Detect

The repository uses GitLab if `git remote -v` shows `gitlab.com` (or any self-managed GitLab) URLs.

## Notes on `glab`

- `glab api` does **not** support `--jq`. Pipe to `jq` in the shell instead.
- Use `:fullpath` as the project identifier — `glab` auto-fills it from the current Git remote (e.g. `glab api projects/:fullpath/...`).
- `glab mr` subcommands resolve the current branch's MR when called with no argument.
- Aliases for the CI subcommand: `glab ci` ≡ `glab pipe` ≡ `glab pipeline`.

## Identify the MR

```bash
glab mr view --output json
```

The MR JSON mirrors the GitLab REST [merge request object](https://docs.gitlab.com/ee/api/merge_requests.html). Useful fields: `iid`, `title`, `source_branch`, `target_branch`, `web_url`, `detailed_merge_status`, `has_conflicts`.

## Check mergeable status

The `detailed_merge_status` field (preferred since GitLab 15.6) returns:

- `mergeable` — no conflicts, ready to merge
- `conflict` — merge conflicts exist (also exposed as `has_conflicts: true`)
- `checking` / `unchecked` / `preparing` — GitLab is still computing (retry after a few seconds)
- other states (`ci_must_pass`, `discussions_not_resolved`, `draft_status`, etc.) — see [API docs](https://docs.gitlab.com/ee/api/merge_requests.html)

The legacy `merge_status` field uses `can_be_merged` / `cannot_be_merged` / `checking` / `unchecked`.

## Get the latest pipeline for the MR's branch

```bash
glab ci status --branch <head-branch> --output json
```

JSON mode is incompatible with `--live` and `--compact`.

## List jobs for a pipeline (with status)

```bash
glab api projects/:fullpath/pipelines/<pipeline-id>/jobs \
  | jq '[.[] | {id, name, stage, status}]'
```

To filter to only failing jobs:

```bash
glab api projects/:fullpath/pipelines/<pipeline-id>/jobs \
  | jq '[.[] | select(.status == "failed") | {id, name, stage}]'
```

## Get failing job logs

`glab` has no `--log-failed` shorthand. Trace each failing job individually by `id` or `name`:

```bash
glab ci trace <job-id-or-name>
```
