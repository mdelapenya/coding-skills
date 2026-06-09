# GitHub Copilot

Topic file for running `pr-reviewer` from inside GitHub Copilot (CLI agent mode, IDE chat, or Copilot Workspace).

## Fetch tooling

The skill drives its own fetch. Copilot can satisfy it through any of:

- Native GitHub awareness (Copilot Workspace) — confirm PR context is fully loaded; request full commit bodies if Copilot truncated them.
- GitHub MCP server — call `get_pull_request`, `list_pull_request_commits`, `get_pull_request_diff`, `get_pull_request_files`, `get_issue`.
- Shell with `gh` (GitHub) or `glab` (GitLab).

For the clone step (Step 2c of the skill), shell access is required regardless — `git clone` is the universal path.

## Looping primitive

As of writing, **GitHub Copilot CLI does not have a `/loop` or `/schedule` command** — a `/schedule` slash command is an open feature request ([copilot-cli#2056](https://github.com/github/copilot-cli/issues/2056)). Copilot CLI does ship an **autopilot mode** that runs a single task autonomously through multiple steps, but autopilot is "complete one task end-to-end," not "repeat a prompt on an interval." Don't conflate them.

Until a real loop primitive ships, use one of:

- **Manual re-invocation** — after each round, the skill reports whether convergence was reached. If not, type `/pr-reviewer [<num>]` again.
- **Multi-step task description (autopilot)** — phrase the request as: "Run `/pr-reviewer [<num>]` up to 3 times, stopping when `findings.md` records `converged: true`." Copilot's autopilot will sequence the rounds itself.
- **External shell driver** — wrap the agent invocation in a `while` loop that breaks on the convergence marker. Cap with `--rounds=N`.

The skill's `--rounds` argument is the universal safety net.

## Posting the final report

If the GitHub MCP server is connected, use its review-creation resource. Otherwise:

```bash
gh pr review <pr-number> --comment --body-file <path-the-skill-printed>
```

Always confirm with the user before posting.

## References

- [GitHub Copilot CLI: autopilot mode](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/autopilot)
- [Feature request: scheduled/recurring prompts (copilot-cli#2056)](https://github.com/github/copilot-cli/issues/2056)
