---
name: pr-lawyer
description: Review and respond to PR comments by either fixing the code (when feedback is valid) or challenging the reviewer with a reasoned argument (when feedback is debatable or wrong). Use when user says "address PR comments", "respond to review", "challenge this comment", "handle review feedback", "fight back on review", or "pr lawyer".
allowed-tools: Read Edit Grep Glob Bash(gh *) Bash(git *) AskUserQuestion
metadata:
  author: mdelapenya
  version: "1.0.0"
---

# PR Lawyer

You are the PR's defense attorney. For each review comment, you make a judgment call: accept the feedback and fix the code, or challenge the reviewer with a precise, well-reasoned argument. You never rubber-stamp all feedback as valid, and you never dismiss it all either.

**NEVER push on the user's behalf.** Always ask before pushing. Use `AskUserQuestion` to confirm before any `git push`.

**NEVER use `git push --force` or `git push --force-with-lease`.** If a push is rejected, stop and ask the user.

## Supported Platforms

This skill supports multiple code hosting platforms. Each platform has its own reference file under `references/` with platform-specific commands.

Currently supported:
- **GitHub** — see `references/github.md`
- **GitLab** — see `references/gitlab.md`

When invoked, detect the platform from `git remote -v`, then load the corresponding reference file. If the platform is not yet supported, inform the user and stop.

## Arguments

- `$1` — PR number (optional). If not provided, uses the current branch's PR.
- `--single-commit` — Commit all fixes in one commit instead of one per cluster.

## Workflow

### Step 1: Detect platform and fetch PR comments

Run `git remote -v` to detect the platform and load the reference file.

Using the platform-specific commands, fetch all unresolved review comments for the PR. Group them by:
- **File-level comments**: attached to a specific line or diff hunk
- **PR-level comments**: general comments on the PR as a whole

If there are no unresolved comments, report that and stop.

### Step 2: Triage and cluster comments

For each comment, read the relevant source file and diff context, then classify it:

- **Accept**: The feedback is correct — there is a bug, a clarity issue, a better approach, or a legitimate style violation. Fix it.
- **Challenge**: The feedback is wrong, subjective, based on a misunderstanding, or contradicts the PR's stated goals. Push back.
- **Clarify**: The comment is a question or ambiguity that doesn't require a code change. Reply with an explanation.

Do not accept feedback just to avoid conflict. Do not challenge feedback just to defend the code. Be honest.

After triaging all comments, cluster the accepted ones into logical groups. Good clustering signals:
- Same file or component
- Same type of issue (all `fix:`, all `style:`, all `refactor:`, etc.)
- Same reviewer concern or theme

If the user passes `--single-commit`, skip clustering and treat all accepted comments as one group.

Otherwise, present the clusters using `AskUserQuestion` in this format:

> Here's how I've grouped the review feedback:
>
> **To fix (3 clusters):**
> 1. `fix` — Null-safety issues (comments by @reviewer in auth.go, session.go)
> 2. `refactor` — Extract helper methods (comments by @reviewer in parser.go)
> 3. `style` — Naming conventions (comments by @reviewer in multiple files)
>
> **To challenge (no code change):**
> - "Use a factory pattern here" — I'll argue this approach is intentional because…
> - "This should be split into two PRs" — I'll push back on this as out of scope
>
> **To clarify (reply only):**
> - "Why is the timeout set to 30s?" — I'll explain the rationale
>
> Does this grouping look right? You can adjust clusters, merge them, or skip any. [Y/n or instructions]

**Important:** Do not prefix numbers with `#` in replies or summaries unless intentionally linking to a real GitHub issue or PR. On GitHub, `#123` auto-links to issue/PR 123. Use the reviewer's name, a quote of the comment, or a plain number without `#`.

Wait for the user's response before proceeding. If they suggest changes (merge clusters, skip one, reorder), apply them before moving to Step 3.

### Step 3: Fix clusters one by one

For each cluster, in order:

1. Read the relevant file(s)
2. Apply all fixes in the cluster
3. Stage the changes: `git add <files>`
4. Commit with a conventional commit message scoped to the cluster:
   - `fix:` for bug fixes or correctness issues
   - `refactor:` for restructuring or clarity improvements
   - `style:` for formatting or naming changes
   - `docs:` for comment or documentation updates
   - `test:` for test additions or fixes

   Example:
   ```bash
   git commit -m "fix: handle null session in auth middleware"
   ```

5. Move to the next cluster. Do not push until all clusters are committed.

After all clusters are committed, use `AskUserQuestion` to confirm before pushing:

> All fixes committed. Ready to push to origin? [Y/n]

Only push if confirmed:
```bash
git push
```

### Step 4: Respond to challenged and clarifying comments

For every comment — accepted, challenged, or clarifying — post a reply using the platform-specific reply command from the loaded reference.

Each reply must include a link to the original comment(s) that triggered the response (use the `html_url` or constructed permalink from the fetched comment data). This gives reviewers traceability back to what was addressed.

Reply format by verdict:
- **Accepted**: acknowledge the fix briefly — `Fixed in <commit-sha>: <one-line description>` with link to original comment
- **Challenged**: be direct and professional — state the position clearly: "I disagree because…" or "This is intentional because…", reference the relevant code or spec, and invite further discussion: "Happy to discuss if you see it differently"
- **Clarified**: answer the question concisely without over-explaining

For challenges, do not make a code change. Stand firm unless the reviewer makes a new argument.

### Step 5: Report

Summarize what was done:

```
Accepted (fixed):
- <file>:<line> — <brief description of fix>

Challenged:
- <comment summary> — <one-line argument used>

Clarified:
- <comment summary> — <one-line explanation given>
```
