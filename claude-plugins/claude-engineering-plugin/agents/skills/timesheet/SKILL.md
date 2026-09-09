---
name: timesheet
description: Generate a human-written daily accomplishment summary for the week. Pulls from Jira (Atlassian MCP), commits merged to origin/dev, and open MRs targeting dev with activity this week. Use when the user types /timesheet.
---

# Timesheet — Weekly Accomplishment Summary

Gather work evidence from three sources (Jira, git history across all branches, and open MRs) and produce 1–4 plain-language sentences per working day. Includes commits from feature branches in progress and merged work on dev (excludes stage/prod).

## Prerequisites

- Atlassian MCP server connected (`alertventure.atlassian.net`)
- Git remote access to `origin` (GitLab)
- `glab` CLI authenticated — **or** `GITLAB_TOKEN` env var set as fallback
- `git fetch` access

---

## Step 1 — Establish date range

**CRITICAL:** Use the system-provided "Today's date" from the user context (e.g., "Friday Apr 3, 2026"). This is the source of truth.

Parse any explicit dates from the user message (e.g. `/timesheet 2026-03-17 2026-03-20`).

**Default when no dates supplied:** Monday of the current week through today (inclusive), using the provided system date.

**To compute Monday from the system date:**

- Parse the provided date (e.g., "Friday Apr 3, 2026")
- Convert to YYYY-MM-DD format
- Calculate Monday of that week: subtract (day_of_week - 1) days
- Example: Friday Apr 3 → Monday Mar 31

Store as `WEEK_START` (Monday 00:00) and `WEEK_END` (system date 23:59).

**Do NOT rely on shell `date` commands** — they may not match the provided system date. If you must verify, cross-check with the system-provided date.

---

## Step 2 — Identify the user

```bash
git config user.name
git config user.email
```

Use the name to call `lookupJiraAccountId` (cloudId: `alertventure.atlassian.net`) and obtain the Atlassian `accountId`. If multiple results are returned, pick the one matching the email. If still ambiguous, ask once.

---

## Step 3 — Gather Jira activity

Call `searchJiraIssuesUsingJql` (cloudId: `alertventure.atlassian.net`):

```text
project = VC
  AND assignee = "<accountId>"
  AND updated >= "<WEEK_START>"
  AND updated <= "<WEEK_END>"
ORDER BY updated ASC
```

Fields to request: `summary`, `status`, `updated`.

Note: `updated` is when Jira last touched the issue—it signals what you were working on each day, not just what closed.

---

## Step 4 — Gather work across all branches (excluding stage/prod)

```bash
git fetch origin
git log --all \
  --author="<git user name>" \
  --since="<WEEK_START>" \
  --until="<WEEK_END>" \
  --pretty=format:"%ci %s" \
  --date=iso \
  --exclude="refs/heads/stage" \
  --exclude="refs/heads/prod" \
  --exclude="refs/remotes/origin/stage" \
  --exclude="refs/remotes/origin/prod"
```

This captures:

- Commits merged to `origin/dev` (completed work)
- Commits on open feature branches (work in progress)
- Commits across all other branches except stage/prod

Group commits by calendar date. Merge commits (subject starts with `Merge branch`) indicate an MR landed; extract the branch name for theming. Feature branch commits appear as regular commits.

---

## Step 5 — Gather open MRs targeting `dev` with activity this week

Get the GitLab project path:

```bash
git remote get-url origin
# e.g. git@gitlab.com:alertventure/vividcloud/ft-quoting.git → alertventure/vividcloud/ft-quoting
```

### Preferred: `glab`

```bash
glab mr list --target-branch dev --state opened --per-page 50
```

For each open MR, fetch recent commits on its source branch:

```bash
git fetch origin <source-branch>
git log origin/<source-branch> \
  --author="<git user name>" \
  --since="<WEEK_START>" \
  --until="<WEEK_END>" \
  --pretty=format:"%ci %s"
```

Include an MR in the summary only if it has at least one qualifying commit.

### Fallback: GitLab REST API

If `glab` is unavailable, use:

```bash
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/alertventure%2Fvividcloud%2Fft-quoting/merge_requests?state=opened&target_branch=dev&per_page=50"
```

State in output that GitLab API fallback was used.

---

## Step 6 — Merge evidence by day

For each calendar day from `WEEK_START` through `WEEK_END` (skip Saturday/Sunday unless there is evidence):

1. Collect all commit subjects on `origin/dev` for that day.
2. Collect all commits on open MR branches for that day.
3. Collect all Jira issues whose `updated` date matches that day.
4. If the same work appears in both `dev` commits and an open MR branch, treat as one item—do not repeat.

---

## Step 7 — Write the output

For each day with evidence, produce **2–4 short sentences**:

- Describe **outcomes and accomplishments** in plain language—what shipped, what was built, what was fixed, what was improved.
- Do **not** include Jira keys (`VC-###`), MR numbers, branch names, or ticket numbers.
- Do **not** reference "morning", "afternoon", or time of day.
- Do **not** use AI filler phrases ("I successfully...", "Leveraged...", "Utilized..."). Write like a concise, professional human.
- Sentences should be independent—a reader with no context should understand what happened.

**Omit days with no evidence** (no commits, no MR activity, no Jira touches). If the user passes `--full-week`, include all weekdays and write "No recorded activity." for empty days.

### Example output shape

```text
Wednesday, March 18
Cleaned up CI configuration and removed a failed experiment that tried to pipe Terragrunt plan output through the deploy process. Replaced hardcoded AWS resource identifiers across all environments with dynamic Terragrunt dependency outputs so environments can be reproduced without manual lookups.

Thursday, March 19
Shipped AWS Secrets Manager integration for the backend, moving the Tripo API key out of CI variables and into a secrets service that loads and caches the value at Lambda cold start.

Friday, March 20
Added and iterated on security scanning tooling—configs, scripts, and CI wiring—for SAST, DAST, and container scanning, and refined the security report format to surface actionable findings. Improved the Cursor/Jira developer workflow by building MCP-backed skills for managing and transitioning Jira issues directly from the IDE.
```

---

## Notes

- Always `git fetch` before reading `origin/dev` or any source branches—local cache may be stale.
- If `lookupJiraAccountId` returns no match, fall back to querying Jira with `reporter = currentUser()` or prompt the user for their Jira account ID.
- Keep sentences grounded in the actual commit subjects and Jira summaries gathered—do not invent or embellish.
