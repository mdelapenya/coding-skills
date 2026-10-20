# Report

## Completion gate

A revision's review is **complete** only when all of these hold. Check them before rendering; the summary agent receives the result as `PASS_STATUS`.

- Staged mode: round 1 of this revision had three distinct reviewer results with `coverage: full` and one assessor result, all on the same head/base/merge-base; every later round that ran a pass had an assessor result on the same target (a round skipped because nothing survived is not a gap). Single mode: your first pass and your steel-man on the same target with no partial coverage.
- No open coverage gap from Step 5 (metadata, commits, diff, files, linked issues all loaded). Hosted CI is optional and never a gap.
- Freshness verified `current` by a successful check after the last pass, or `--historical` was passed and the report says historical.
- A failed pass had at most one recovery attempt, and the attempt succeeded.

Anything else makes the review **incomplete**. An incomplete review is still rendered, but its verdict is `Review incomplete`, its findings are labelled provisional, and it never says "No findings". When freshness failed because the refresh budget ran out, the verdict is `Latest-state review incomplete`.

## Verdict rules

Evaluate top to bottom; the first matching row wins. "Finding" below means a finding whose latest status is `confirmed` or `weakened`; `needs-info` items are questions and never change the verdict.

| Situation | Verdict |
|---|---|
| Refresh budget exhausted, PR has moved past the reviewed revision | `Latest-state review incomplete` |
| Completion gate failed for any other reason | `Review incomplete` |
| At least one `blocker` or `major` finding, and at least one `minor` or `nit` finding | `Potential blockers; follow-ups` |
| At least one `blocker` or `major` finding | `Potential blockers` |
| At least one `minor` or `nit` finding | `Follow-ups` |
| No findings | `No findings` |

With `--historical` and a moved PR, append ` (historical)` to whichever verdict applies.

## Template

Render directly, headings and order preserved. Short SHAs are 12 characters.

```markdown
# Review of PR #NUMBER: TITLE

- **Author:** AUTHOR_DISPLAY (@AUTHOR_LOGIN)
- **Reviewed revision:** head `HEAD_SHA12`, base `BASE_SHA12`
- **Freshness:** current as of UTC_TIME | superseded at UTC_TIME by head `SHA12` base `SHA12` | unverified at UTC_TIME | refresh budget exhausted (REFRESHES_USED of MAX_REFRESH): reviewed head `SHA12` base `SHA12`, latest head `SHA12` base `SHA12` at UTC_TIME
- **Rounds:** N on this revision, mode MODE, converged YES_OR_NO
- **Verdict:** VERDICT

## Blockers
- [file:line] CLAIM (SOURCES, evidence: EVIDENCE_KIND)
  - Evidence: QUOTED_CODE
  - Why it matters: ONE_LINE
  - Suggested action: ONE_LINE

## Major
...

## Minor and nits
...

## Retracted on review
- CLAIM. Retracted: REASON

## Validation and limits
- Static inspection: WHAT_WAS_READ (full diff, surrounding code, tests, call sites)
- Executed locally (read-only): COMMANDS or "none"
- Hosted CI: STATUS for head `HEAD_SHA12`, or "not consulted"
- Unverified: CLAIMS_RESTING_ON_REASONING_ALONE, or "none"
- Coverage gaps: GAPS or "none"

## Open questions for the author
- NEEDS_INFO_ITEMS or "None"
```

`MODE` is one of `staged`, `single (requested)`, `single (fallback: REASON)`.

## Rendering rules

- Author comes from PR metadata. `AUTHOR_DISPLAY` is the display name when one was fetched, otherwise the login. If metadata could not be read, write `Author: unavailable (REASON)`; never fall back to a commit author.
- "Reviewed revision" is the pinned head, never a later one. If the PR has moved, say so in Freshness and nowhere else pretend otherwise. On GitLab, where a target-only move is invisible to the metadata, append `(head only)` to the Freshness line.
- Every section is present. Empty finding sections read `None identified`.
- Each finding shows which reviewers raised it and how its evidence was obtained, so the author can weigh a `static` claim from one reviewer differently from an `executed` claim three reviewers converged on.
- In "Validation and limits", separate the four kinds strictly. Nothing in the review tree was built or run, so "Executed locally" lists read-only git and grep commands only. A test that exists, is skipped, is pending, or ran against another head is not validation of this target. Hosted CI counts only when its result is tied to this exact head.
- Incomplete runs: prefix every finding with `(provisional)`, name the missing pass or gap in "Validation and limits", and record downstream passes as not run.
- The report ends after "Open questions for the author". No "Posting this review", "Next steps" or "How to use this" section, ever. Posting is Step 11 and is a question to the user, not part of the artifact.
