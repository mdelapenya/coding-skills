# GitLab

The GitLab equivalent of the pinning call in Step 2.

GitLab: `glab api "projects/<url-encoded path>/merge_requests/<iid>"`, taking `title`, `description`, `state`, `draft`, `web_url`, `author.username`, `sha` as head, `diff_refs.start_sha` as base (not `base_sha`, which is already the merge base), and `target_branch`; the clone URL is `glab api "projects/<url-encoded path>" --jq .http_url_to_repo`. GitLab recomputes `diff_refs` on a push or rebase of the MR, not when the target branch moves, so freshness on GitLab may miss a target-only move; the report's freshness line says `(head only)` there.
