# Publication

Posting happens after the report is printed, as a separate question, and only by the coordinator. Invoking the skill, a clean report, a vague "looks good", or an instruction given before the report existed ("approve it if clean") authorizes nothing: the user must choose after seeing the exact text. Authorization from another workflow or another PR does not carry over. `allowed-tools` pre-approves `gh api`, so nothing in the tool layer stops a write; this procedure is the fence.

## 1. Revalidate

1. Repeat the Step 2 metadata call. If head or base moved since the reviewed revision, do not post against the old one: go back through the refresh logic (Step 3 and Step 8) within the remaining budget and come back here with the new report. An authorized body for an old revision does not authorize it for a new one. With `--historical`, or when the budget is exhausted, a comment may still be posted but must name the reviewed head, and **Approve is never offered**.
2. `gh api user --jq .login` (GitLab: `glab api user --jq .username`). Record the acting login and confirm it is the account the user intends to post from.
3. Approval is possible only if the PR is open, not a draft, the author login differs from the acting login, and the revision is current.
4. List the acting account's existing reviews and comments on this PR (`gh api repos/<org>/<repo>/pulls/<num>/reviews`, `gh api repos/<org>/<repo>/issues/<num>/comments`; GitLab: `glab api projects/<id>/merge_requests/<iid>/notes` and `.../approvals`). If an equivalent review on the same head already exists, do not duplicate it; say so and offer to post only what is new.

## 2. Draft and offer

Draft the exact text before asking. **Findings text** is the finding sections of the report, "Validation and limits", and "Open questions", plus the header lines (author, revision, freshness); "Retracted on review" only if the user wants it. **Summary text** is the header lines plus "Validation and limits" only. Write the draft to `<base-dir>/review-body.md`; never pass Markdown through shell interpolation.

Offer the options the evidence allows, recommending the first:

| Verdict | Options |
|---|---|
| `No findings` | **Approve** (bodyless by default), **Post summary text**, **Keep local** |
| `Follow-ups` | **Approve with the findings text** (one review submission that approves and carries the text), **Post findings text without approval**, **Keep local** |
| `Potential blockers` or `Potential blockers; follow-ups` | **Post findings text without approval** (a `COMMENT` review), **Keep local**. Approval is not offered. `REQUEST_CHANGES` only if the user asks for that state by name, separately from permission to post. |
| Any complete verdict with ` (historical)`, or a complete review whose revision has since moved | **Post findings text without approval** (names the reviewed head), **Keep local**. Approval is not offered. |
| `Review incomplete` / `Latest-state review incomplete` | **Keep local**, **Resume** (re-invoke for the missing pass or the new revision). Approval is not offered. If the user insists on posting partial findings, prefix the text with the missing coverage and label it provisional. |

Ask with `AskUserQuestion`, naming the PR, the reviewed head, the action and the draft path. "Approve" authorizes approval only, not unshown comments. "Post findings" does not authorize approval. If the user asks to approve despite blockers, an incomplete review or a stale revision, state that condition plainly and confirm the instruction knowingly covers it; never relabel the review as clean or current.

## 3. Submit

GitHub, one call, body from file, pinned to the reviewed head:

```bash
# with a body
jq -n --arg commit "<headRefOid>" --arg event "<APPROVE|COMMENT|REQUEST_CHANGES>" \
      --rawfile body <base-dir>/review-body.md \
      '{commit_id: $commit, event: $event, body: $body}' > <base-dir>/review.json
# bodyless approval
jq -n --arg commit "<headRefOid>" '{commit_id: $commit, event: "APPROVE"}' > <base-dir>/review.json

gh api -X POST "repos/<org>/<repo>/pulls/<num>/reviews" --input <base-dir>/review.json
```

GitLab (not exercised; check your `glab` version's flags first): a comment is `jq -n --rawfile body <base-dir>/review-body.md '{body: $body}' > <base-dir>/note.json && glab api -X POST "projects/<id>/merge_requests/<iid>/notes" --input <base-dir>/note.json`; approval is `glab mr approve <iid>`, pinned to the head with `--sha <headRefOid>` where supported, otherwise re-check the head immediately before the call.

Re-check head/base immediately before the call if any time passed waiting for the user. Submit only the text that was shown. If the platform rejects the write (branch protection, permissions), report the reason and stop; do not look for another route.

## 4. Verify

Read the review back (`gh api repos/<org>/<repo>/pulls/<num>/reviews/<id>`; GitLab: the notes or approvals list): state, `commit_id`, body. Re-check head/base once more; if the PR moved during the write, say the review targeted the reviewed head and claim nothing about the new one.

If the call timed out or the result is unknown, list the account's reviews on the PR before any retry and look for the one you tried to post. Retry at most once, and only after proving the first did not land. Never post a mutation twice on a guess.

Finish with the review URL and one line saying what was posted or approved. A publication failure does not undo the local review; the report and `findings.md` stand.
