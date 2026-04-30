# GitLab CI

Platform-specific commands for investigating CI failures on GitLab CI/CD using `glab`.

## Detect

The repository uses GitLab CI if `.gitlab-ci.yml` (or `.gitlab/ci/*.yml` referenced from it) exists at the repo root.

## Notes on `glab`

- `glab api` does **not** support a `--jq` flag. Pipe to `jq` in the shell instead.
- Use `:fullpath` as the project identifier — `glab` auto-fills it from the current Git remote (e.g. `glab api projects/:fullpath/...`).
- `glab ci` ≡ `glab pipe` ≡ `glab pipeline`. The `-O, --output json` flag is incompatible with `--live`/`--compact`.

## Get the MR and its latest pipeline

```bash
glab mr view --output json
glab ci status --branch <head-branch> --output json
```

The `glab mr view` JSON includes `head_pipeline` (when present) — its `id` and `status` are useful shortcuts.

## Get failing jobs from a pipeline

```bash
glab api projects/:fullpath/pipelines/<pipeline-id>/jobs \
  | jq '[.[] | select(.status == "failed") | {id, name, stage}]'
```

## Get failure logs

`glab` has no `--log-failed` shorthand. Trace each failing job by `id` (or `name`):

```bash
glab ci trace <job-id>
```

## List recent pipelines

Use `$1` (default: 10) as the `--per-page` value. To find pipelines on branches other than the current one, list and filter with `jq`:

```bash
glab ci list --per-page <$1 or 10> --output json \
  | jq '[.[] | select(.status != "running" and .status != "pending" and .ref != "<current-branch>")] | .[0:5]'
```

To pre-filter by status (e.g., only failed pipelines):

```bash
glab ci list --status failed --per-page <$1 or 10> --output json
```

Available statuses: `running`, `pending`, `success`, `failed`, `canceled`, `skipped`, `created`, `manual`, `scheduled`.

## Check specific jobs in a pipeline

```bash
glab api projects/:fullpath/pipelines/<pipeline-id>/jobs \
  | jq '[.[] | select(.name | test("<failing-job-pattern>")) | {id, name, status}]'
```

## Get MR diff

```bash
glab mr diff --raw
```
