# Generate PR Description

## Background

The team has completed a performance improvement to reduce database load on user profile queries. The changes are ready for review and need a PR title and description written before the pull request is shared with reviewers.

The diff of all changes is in `pr.diff` and the commit history for this branch is in `commits.txt`. Use these to produce a complete PR title and description.

## Output Specification

Use the pr-scribe skill to generate the PR title and description from the diff and commits. Output them using whatever mechanism is appropriate for this repository's setup.

If you encounter conflicts between the generated description and any existing repository content, document your resolution decisions in a `conflicts.md` file.
