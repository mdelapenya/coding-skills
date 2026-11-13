# Adversarial review of PR #247

Alice's PR #247 adds endpoints to serve users' uploaded files. The mobile team is waiting on it for v2.3, and I keep getting asked to just approve it. Before I do, I want an adversarial review: assume it is wrong until the code shows otherwise.

There is no network or `gh` in this sandbox, so the PR is exported to `inputs/`:

- `inputs/pr-metadata.json`: PR metadata, including head and base SHAs and linked issues
- `inputs/pr.diff`: the full diff
- `inputs/pr-commits.txt`: the commit log

Put the review in `review-report.md` in the working directory. Do not approve or comment on the PR; I'll decide after reading the report.
