# PR Review: User File Serving Feature

## Background

A backend developer on your team has submitted a pull request to add a user file serving feature to the application API. The PR has been sitting in the review queue for a couple of days and your tech lead needs it triaged before the week is out. You have been asked to conduct a thorough code review before the team decides whether to merge.

The PR materials are provided in the `inputs/` directory:

- `inputs/pr-metadata.json` — PR metadata including number, title, description, author, branch info, labels, and linked issues
- `inputs/pr.diff` — the unified diff of all code changes in the PR
- `inputs/pr-commits.txt` — the commit log for the feature branch

## Output Specification

Conduct a systematic code review of this pull request and produce the following files in your working directory:

- `review-plan.md` — your review approach before you begin: describe what reviewer passes you will use, what each pass will focus on, and how you will compile the final findings. Write this first, before examining the diff in detail.
- `review-report.md` — the final review report, containing all findings discovered across all passes. Each finding should include a description, severity, and evidence. Close the report with an "Open questions for the author" section listing any questions that need clarification before this can be merged.
