# Review PR #312 before it merges

Rosa's PR #312 adds retries with backoff to our HTTP client. It runs inside the billing sync, which processes payments, so I want a careful review before anyone approves it.

There is no network or `gh` in this sandbox, so the PR is exported to `inputs/`:

- `inputs/pr-metadata.json`: the PR metadata, including head and base SHAs
- `inputs/pr.diff`: the full diff
- `inputs/pr-commits.txt`: the commit log

Run the review in single mode (`--single`): one reviewer, no subagents. Write it to `review-report.md` in the working directory. Do not approve or post anything.
