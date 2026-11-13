# PR Documentation: Payments API Authentication Overhaul

## Background

The engineering team at Example Corp has just finished merging a significant change to the `payments-api` service (GitHub repository `example-corp/payments-api`). Before the pull request (PR #73) goes into final review, every PR must have a polished title and description — the team's standard for code review hygiene.

Your job is to write the PR title and description for PR #73 based on the diff and commit history provided. A PR template is already in the repository at `.github/PULL_REQUEST_TEMPLATE.md` — use it as your structure for the description. The description should give a reviewer enough context to understand what changed and why, without them needing to read every line of code.

The input files are:
- `inputs/pr.diff` — the full diff of the changes on this branch
- `inputs/commits.txt` — the commit messages on the feature branch

The remote for this repository is `github.com/example-corp/payments-api`.

## Output Specification

Write the following files to the working directory:

1. **`pr-title.md`** — the PR title on a single line, nothing else.
2. **`pr-description.md`** — the complete PR description, using the template structure from `.github/PULL_REQUEST_TEMPLATE.md`.
3. **`update-pr.sh`** — a shell script containing the GitHub CLI command(s) that would update PR #73's title and body on the remote repository. The script does not need to be runnable in this environment; write it as you would if you were running it against a live GitHub remote.
