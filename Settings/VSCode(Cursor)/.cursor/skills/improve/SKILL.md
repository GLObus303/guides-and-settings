---
name: improve
description: Find recently merged PRs with unprocessed review comments and learn from them to improve skills, agents, and CURSOR.md. Run periodically to keep the knowledge base current.
---

# Improve Skills from PR Feedback

Finds merged PRs with review comments that haven't been processed yet, then runs `/learn-from-pr` on each to capture new patterns and update skills.

## How to Use

Run `/improve` periodically (weekly recommended) or when prompted by the session-start hook.

Optional arguments:

- `/improve` — Process all unprocessed PRs by the current user
- `/improve 5` — Process only the last 5 unprocessed PRs
- `/improve 15654` — Process a specific PR number

---

## Phase 1: Find Unprocessed PRs

1. Read the processed PRs tracker from memory (`processed_prs.md`)
2. Fetch recently merged PRs by the current user:

```bash
# Get GitHub username
gh api user --jq '.login'

# List merged PRs (last 50)
gh pr list --repo Ribbon-Experiences/momence-monorepo \
  --author <username> --state merged --limit 50 \
  --json number,title,mergedAt \
  --jq '.[] | "\(.number)\t\(.title)\t\(.mergedAt)"'
```

3. Filter out PRs already in the processed list
4. For each unprocessed PR, check if it has review comments:

```bash
gh api graphql -f query='
{
  repository(owner: "Ribbon-Experiences", name: "momence-monorepo") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 1) {
        totalCount
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.totalCount'
```

5. Skip PRs with 0 review comments (nothing to learn from)

---

## Phase 2: Present Findings

Show the user what was found:

```
## Unprocessed PRs with Review Comments

| PR | Title | Merged | Comments |
|----|-------|--------|----------|
| #15800 | feat: Add booking flow | 2026-03-20 | 8 |
| #15812 | fix: Subscription freeze | 2026-03-22 | 3 |

Process all 2 PRs? (or specify which ones)
```

---

## Phase 3: Learn from Each PR

For each PR the user approves:

1. **Run `/learn-from-pr` logic** — fetch all review threads, classify comments, match against existing knowledge, propose changes
2. **Apply approved changes** to skills, agents, or CURSOR.md
3. **Mark PR as processed** — append the PR number to `processed_prs.md` in memory

After processing each PR, immediately update the tracker so progress is saved even if the session is interrupted.

---

## Phase 4: Summary

After processing all PRs, show a summary:

```
## Improvement Summary

PRs processed: 2
Lessons found: 7
- 3 already covered
- 2 added to existing skills
- 1 added to CURSOR.md
- 1 added to review agent

### Changes Made
- `/validate` skill: Added check for X
- `review-backend` agent: Added Y pattern
- CURSOR.md: Added Z to coding standards

### Next Steps
- Run `/validate` on your current work to test the improved checks
- Next /improve recommended after 3-5 more PRs merge
```

---

## Tips

- **Run after merging PRs** — best while the review context is fresh
- **Review proposals carefully** — not all PR comments are generalizable patterns
- **Check for false positives** — one-off reviewer preferences vs team-wide standards
- **The session-start hook will remind you** when unprocessed PRs accumulate
