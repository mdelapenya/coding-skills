# Automate Worktree Sync for PR Development Workflow

## Background

Your engineering team has adopted a git worktree-based workflow for managing pull request development. Each engineer keeps a root repository directory tracking the `main` branch, and checks out each feature branch in its own sibling worktree directory. When engineers want to incorporate the latest upstream changes from `main` into their feature branch, they currently follow a manual multi-step process: navigating to the root repository, verifying it is in a clean state, pulling from origin, navigating back to the feature worktree, and then merging `main` into the feature branch.

This manual process is fragile and has led to several incidents. The most common issue: an engineer starts a pull while the root repository has uncommitted changes, leading to unexpected outcomes. The team also wants to eventually run the sync automatically on a recurring basis as part of a broader PR monitoring workflow — but only after the user has had a chance to decide whether continuous syncing makes sense for their situation.

You have been asked to write a reusable shell script, `sync-with-main.sh`, that any engineer can invoke from within their feature worktree directory to safely perform the sync. The script must discover the root repository's location automatically at runtime (the layout varies across machines and projects; no path should be hardcoded). It must verify the root is in a safe state before touching it, and bail out clearly if it is not. After successfully pulling and merging, the script should include commentary in the code or in a companion `notes.md` about how the user should be guided when the script is run interactively versus on an automated schedule.

## Output Specification

Write the following files:

- `sync-with-main.sh` — the shell script implementing the sync procedure. Include a shebang line (`#!/bin/sh` or `#!/bin/bash`) and make it executable (`chmod +x`). The script should print informative progress messages at each step.
- `notes.md` — brief documentation covering: how the script works step by step, what prerequisites the repository layout must satisfy, and how the script should behave when integrated into a monitoring loop versus invoked directly by a user.
