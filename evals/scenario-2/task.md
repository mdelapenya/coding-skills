# Review PR #847 before we merge it

Jane opened PR #847 on our Python data-access library. It adds connection-pool support to `QueryBuilder` and two new filtering methods. Nobody on the backend team has had time to look at it properly, and it touches how SQL gets built, so I want a careful review before anyone approves it.

This sandbox has no network access and no `gh`, so I exported everything you need into `inputs/`:

- `inputs/pr-metadata.json`: the PR's metadata as the GitHub API returned it
- `inputs/pr.diff`: the full diff
- `inputs/pr-commits.txt`: the branch's commit log

Write the review to `review-report.md` in the working directory. Don't post anything anywhere; I'll decide what to do with it after I've read it.
