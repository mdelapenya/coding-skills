---
name: describe-pr
description: Generate a concise PR description from a GitHub pull request diff. Auto-detects remotes, honors PR templates, and updates the PR via gh. Use when user says "describe this PR", "add PR description", "fill in PR body", "describe pull request", or "summarize PR changes".
allowed-tools: Read Glob Bash(gh *) Bash(git remote*) Bash(git branch*) AskUserQuestion
metadata:
  author: mdelapenya
  version: "1.0.0"
---

# Describe PR

Generate a concise description for a GitHub pull request by analyzing its diff.

## Workflow

### Step 1: Determine the repository

Run `git remote -v` and parse unique `org/repo` pairs from fetch URLs.

- **Single remote**: use it automatically.
- **Multiple remotes**: prompt the user with a numbered list, default to the first:
  ```
  Multiple remotes found:
  1. origin  → org/repo
  2. upstream → org/repo
  Which remote? [1]:
  ```

### Step 2: Get the PR number

If `$ARGUMENTS` contains a number, use it. Otherwise ask:
```
PR number:
```

### Step 3: Fetch PR metadata and diff

Run in sequence:
```bash
gh pr view <number> --repo <org>/<repo> --json title,body,baseRefName,headRefName,commits
gh pr diff <number> --repo <org>/<repo>
```

Keep the full response — commit messages from `commits` are reused in Step 5.

### Step 4: Check for a PR template

Look for a template in this order:
1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. `PULL_REQUEST_TEMPLATE.md`
4. `pull_request_template.md`
5. `.github/PULL_REQUEST_TEMPLATE/` directory (use first `.md` file)

If found, use its structure (headings, sections, checkboxes) as the skeleton. Fill each section from the diff analysis. Preserve checkbox items from the template.

If not found, use this default structure:
```markdown
## What's changed
<1-3 short paragraphs summarizing the PR's changes>

## Why is this important?
<1-2 paragraphs explaining the motivation and impact of the changes>

## Changes
<grouped by component/area>

## Test plan
<how to verify>
```

Do not include a `## Related issues` section in the template — Step 5 appends it only when issues are found.

### Step 5: Look for related issues

Search for issues this PR might address using three signals:

1. **Branch name**: run `git branch --show-current` and extract issue numbers from patterns like `fix/123`, `issue-456`, `gh-789`, `feat/PROJ-42`
2. **Commit messages**: scan the `commits` data already fetched in Step 3 for `#<number>`, `fixes #`, `closes #`, `resolves #`
3. **Keyword search**: extract key terms from the PR title and diff, then run `gh issue list --repo <org>/<repo> --state open --search "<terms>" --limit 5`

If related issues are found:
- Append a `## Related issues` section to the description (or fill the equivalent section if the PR template has one)
- Use closing keywords where the PR clearly resolves the issue: `Closes #123`, `Fixes #456`
- If the match is uncertain, use `Related to #123` instead of closing keywords
- For superseded PRs, use `Supersedes #789`

If no issues are found, do not add the section — no empty placeholders.

### Step 6: Generate the description

Analyze the diff and fill the template. Follow these rules:
- Lead with **what** and **why**, not how
- Group related changes together
- Mention breaking changes or migration steps if applicable
- Keep it concise — no filler, no restating the title
- Do not include the PR title in the body
- Use present tense ("Add", "Fix", "Update")

### Step 7: Preview and confirm

Show the generated description and ask:

```
Update PR #<number> with this description? [Y/n]:
```

- **Confirmed**: write the description to a temp file and run:
  ```bash
  gh pr edit <number> --repo <org>/<repo> --body-file /tmp/pr-description.md
  ```
- **Declined**: ask what to change and regenerate
