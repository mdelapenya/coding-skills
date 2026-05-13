---
name: pr-scribe
description: Generate a concise PR description and a Conventional Commits title from a GitHub pull request diff. Auto-detects remotes, honors PR templates, and updates both title and body via gh. Use when user says "describe this PR", "add PR description", "fill in PR body", "describe pull request", "summarize PR changes", or "update the PR title".
allowed-tools: Read Write Glob Bash(gh *) Bash(glab *) Bash(jq *) Bash(git remote*) Bash(git branch*) AskUserQuestion
metadata:
  author: mdelapenya
  version: "1.0.0"
---

# PR Scribe

Generate a concise description for a pull request by analyzing its diff.

## Supported Platforms

This skill supports multiple code hosting platforms. Each platform has its own reference file under `references/` with platform-specific commands.

Currently supported:
- **GitHub** — see `references/github.md`
- **GitLab** — see `references/gitlab.md`
- **biomelab** — see `references/biomelab.md` (special context: writes outputs to `.biomelab/` files instead of updating PRs remotely)

Planned:
- Bitbucket

When invoked, first detect the platform from `git remote -v` and check for biomelab context (`.biomelab/` directory), then load the corresponding reference file for platform-specific commands.

## Workflow

### Step 1: Detect platform and biomelab context

Check if `.biomelab/` directory exists in the repository root. If yes, load `.biomelab/topic.md` (which defines biomelab-specific instructions and naming conventions).

Then detect the platform from `git remote -v` and parse unique `org/repo` pairs from fetch URLs. Detect the platform (GitHub, GitLab, etc.) from the URL and load the matching reference file.

- **Single remote**: use it automatically.
- **Multiple remotes**: use `AskUserQuestion` to prompt with a numbered list, default to the first:
  > Multiple remotes found:
  > 1. origin  → org/repo
  > 2. upstream → org/repo
  > Which remote? [1]

If the platform is not yet supported, inform the user and stop.

### Step 2: Determine the PR number

If `$ARGUMENTS` contains a number, use it. Otherwise use `AskUserQuestion` to ask:

> PR number:

### Step 3: Fetch PR metadata and diff

Using the platform-specific commands from the loaded reference, fetch the PR metadata (title, body, base/head branches, commits) and the full diff.

Keep the full response — commit messages are reused in Step 5.

### Step 4: Check for a PR template

Using the platform-specific template paths from the loaded reference, look for a PR template.

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

### Step 5: Read existing biomelab context (if applicable)

If `.biomelab/` was detected in Step 1 and `.biomelab/note.md` exists, read its content. This file may contain user-refined description text from previous iterations that should inform the new generation.

Keep this content for reference during Step 6 (generating the description).

### Step 6: Look for related issues

Search for issues this PR might address using three signals:

1. **Branch name**: run `git branch --show-current` and extract issue numbers from patterns like `fix/123`, `issue-456`, `gh-789`, `feat/PROJ-42`
2. **Commit messages**: scan the commits data already fetched in Step 3 for `#<number>`, `fixes #`, `closes #`, `resolves #`
3. **Keyword search**: extract key terms from the PR title and diff, then use the platform-specific issue search command from the loaded reference

If related issues are found:
- Append a `## Related issues` section to the description (or fill the equivalent section if the PR template has one)
- Use closing keywords where the PR clearly resolves the issue: `Closes #123`, `Fixes #456`
- If the match is uncertain, use `Related to #123` instead of closing keywords
- For superseded PRs, use `Supersedes #789`

If no issues are found, do not add the section — no empty placeholders.

### Step 7: Generate the description

Analyze the diff and fill the template. If existing content from `.biomelab/note.md` (Step 5) is available, use it as context to inform the generation — preserve good user-refined sections and incorporate insights from the existing text.

Follow these rules:
- Lead with **what** and **why**, not how
- Group related changes together
- Mention breaking changes or migration steps if applicable
- Keep it concise — no filler, no restating the title
- Do not include the PR title in the body
- Use present tense ("Add", "Fix", "Update")

### Step 8: Resolve conflicts with existing biomelab content (if applicable)

If `.biomelab/` context was detected and existing content from Step 5 is available, compare the newly generated description with the existing `.biomelab/note.md` content.

Analyze the differences and identify specific conflicts:
- **Added sections** in existing: sections the user added that pr-scribe didn't generate
- **Removed sections** in existing: sections that were in the template but user deleted
- **Rewording conflicts**: same sections but significantly different language or structure
- **Missing sections**: sections pr-scribe generated but don't exist in the existing content

If there are significant differences, use `AskUserQuestion` to interview the user about specific conflicts. Ask targeted questions, not generic choices:

- For each added section: "I found a custom '[Section Name]' section in the existing content. Keep it?"
- For each removed section: "The generated description includes '[Section Name]', but it's not in your existing content. Add it?"
- For each rewording conflict: "The '[Section Name]' section has been rewritten. Which version do you prefer?"

Collect user answers and merge intelligently:
- Preserve user-added sections
- Omit user-removed sections
- Use user's preferred wording when there are rewording conflicts
- Incorporate new sections the user didn't object to

If there are no significant differences or the user confirms all changes, use the merged result for Step 9.

### Step 9: Generate the title (Conventional Commits)

Produce a title that follows the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <subject>
```

Rules:
- **Type** — pick one: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Infer from the diff (new behavior → `feat`, bug fix → `fix`, docs only → `docs`, etc.).
- **Scope** — optional. Use the primary affected area (package, module, skill name). Omit when the change spans many areas.
- **Subject** — imperative mood, lowercase, no trailing period, ≤72 chars total title length.
- **Breaking changes** — append `!` after the scope (e.g., `feat(api)!: ...`) when the change is breaking.

Examples (matching this repo's style):
- `feat(pr-scribe): generate Conventional Commits title`
- `fix(pr-nurse): handle missing CI runs`
- `chore: refine pr-lawyer responses`

If the existing PR title already follows Conventional Commits and accurately reflects the diff, keep it.

### Step 10: Output the results

**If `.biomelab/` was detected in Step 1:**
Write the results to the biomelab context directory without updating the PR remotely:
- Write the title to `.biomelab/pr-title.md`
- Write the (possibly merged) description to `.biomelab/note.md`
- Inform the user that outputs have been written for the biomelab GUI app to consume

**Otherwise:**
Show the generated title and description to the user, then immediately use the platform-specific update command from the loaded reference to apply both. Do not ask for confirmation.
