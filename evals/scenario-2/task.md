# PR Review: Query Builder Extension

## Problem Description

Your team maintains a Python data-access library used across several backend services. A colleague has opened a pull request to extend the `QueryBuilder` class with connection pool support and two new filtering methods. The PR has been sitting for a couple of days and nobody on the backend team has had time to review it carefully. You have been asked to do a thorough code review and produce a written report.

The PR materials are available locally — there is no need to contact GitHub or clone any repository. All the information you need is in the input files:

- `inputs/pr.diff` — the unified diff of all changes
- `inputs/pr-metadata.json` — PR title, description, author, head/base SHAs, and labels
- `inputs/pr-commits.txt` — the commit log for the branch

Your job is to read these files carefully and produce a thorough review report covering correctness, security, and test coverage. Pay particular attention to anything in the diff that could affect data integrity or allow unintended query construction.

## Output Specification

Write your findings to a file named `review-report.md` in the working directory.

The report must include the following sections in this order, using these exact headings:

1. `## Blockers`
2. `## Major`
3. `## Minor and nits`
4. `## Retracted on review`
5. `## Validation and limits`
6. `## Open questions for the author`

For each finding, include a short title, a description of the issue, the evidence for your conclusion (quoting relevant lines or explaining your reasoning), the severity of the defect, and your assessment of whether the vulnerable path is actually reachable. Record severity and reachability as distinct labelled fields for each finding.

Also include at the top of the report a one-word risk classification of the diff (routine, complex, or consequential).
