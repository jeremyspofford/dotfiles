---
description: Generate a daily accomplishment summary for the week — pulls from Jira, commits across all branches, and open MRs targeting dev
---

# Timesheet

Follow `.cursor/skills/timesheet/SKILL.md`.

Generates 2–4 plain-language sentences per working day summarizing what was accomplished. Evidence is gathered from three sources: Jira issues assigned to you that were updated this week, commits across all branches (excluding stage/prod), and open MRs targeting `dev` with branch activity this week.

Optional: pass an explicit date range after the command (e.g. `/timesheet 2026-03-17 2026-03-20`). Defaults to Monday through today.

Requires Atlassian MCP, git remote access, and `glab` CLI (or `GITLAB_TOKEN`) for open MR listing.
