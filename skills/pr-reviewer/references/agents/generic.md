# Generic / Unknown Agent

Fallback topic file for any agent that does not have a dedicated entry under `references/agents/`.

## Fetch tooling

The skill drives its own fetch. If the agent has shell access, `gh` (GitHub) and `glab` (GitLab) are the canonical tools. If the agent only has an MCP server for the host (e.g., GitHub MCP), use that for metadata/diff/issues — but `git clone` for Step 2c of the skill still requires shell access. If the agent has neither shell nor a relevant MCP, the user must check out the PR before invoking; the skill cannot manufacture data.

## Looping primitive

Most coding agents do not have a built-in loop primitive today (Claude Code is the exception — see `claude.md`). For everything else, pick the most automation-friendly option your agent supports, in increasing order of automation:

1. **Manual** — the user re-invokes `/pr-reviewer [<num>]` after each round until the skill reports convergence or `--rounds=N` is hit.
2. **Agent task description** — tell the agent in plain language: "Run `/pr-reviewer [<num>]` up to 3 times, stopping early on `converged: true`." Multi-step agents will sequence this correctly.
3. **External shell driver** — drive the agent from a shell `for` / `while` that breaks on the convergence marker:
   ```bash
   for i in $(seq 1 3); do
     <agent-invocation-here> "/pr-reviewer [<num>]"
     grep -q '^- converged: true$' "<base-dir>/findings.md" && break
   done
   ```

`--rounds=N` is the universal hard stop. Always pass it.

## Posting the final report

The skill prints the report by default. If the agent has the ability to post to the source platform, confirm with the user first, then use whichever tool the agent provides. Otherwise print the report and let the user post it manually.
