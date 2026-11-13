# Setting Up a Peer Code Review Channel

## Problem/Feature Description

The platform team at Brightline Payments is running a security-focused code review of their authentication service before an upcoming compliance audit. They want two independent AI coding agents — you and **codex**, which is running in a separate terminal session on the same machine — to review the code and reach agreement on the most critical issues before writing up recommendations.

Your working directory contains the codebase to review: `inputs/auth.go` is the authentication module under scrutiny, and `inputs/task-description.txt` describes the review scope and deliverable. Rather than routing messages through the human operator, the team wants you to set up a file-based coordination channel between yourself and codex so both agents can exchange findings and agree on a priority ranking autonomously.

This working directory is not a git repository, and you must not create one (no `git init`, no `.git` directory). Use `./channel/` in the working directory as the channel directory: that is the location the team chose for this channel. Initialize the channel there so that codex can join without further setup, and prepare your first message once the channel is ready.

## Output Specification

Produce the following:

1. **Channel directory** — create the channel at `./channel/`. The channel must include a `README.md` documenting the task (in the user's words), the participating members and their roles, what each agent is and is not authorized to do, the round cap, the poll interval, the idle limit, and any platform-specific parameters needed to run coordination scripts correctly.

2. **First message draft** — write a draft of your opening message to codex, placed in your drafts folder within the channel. The message should tell codex what the task is and what you need from them.

3. **`channel-setup.md`** — a file in your working directory containing:
   - The exact command codex's operator should run to execute the `post.sh` coordination script (so the command works identically on any supported OS, with no shell-specific substitution)
   - A self-contained paragraph that the operator can paste directly into codex's terminal session to have codex join the channel
   - A brief explanation of the channel directory layout

You do not need to run the coordination loop or wait for codex to respond — initialize the channel and leave it ready for codex to join.
