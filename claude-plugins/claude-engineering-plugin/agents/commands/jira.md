---
description: Jira + git for VC — create issues with acceptance criteria, start branches, or update statuses (Atlassian MCP)
---

# Jira (VC)

Follow `.cursor/skills/jira/SKILL.md`, especially **Dispatch: `/jira` with free text**.

Treat everything **after** `/jira` as user intent:

- **Create issue:** e.g. "create a task to …", "new issue about …" → workflow **create-issue**. Always includes acceptance criteria before creating.
- **Start work / branch:** e.g. `201`, `VC-201`, "start 201", "start work on …" → workflow **start-branch**.
- **Status change:** e.g. "move to done", "mark done", "transition to in review" → workflow **update-issue** → **Change status**. Resolve the issue from a key in the message if present; otherwise from the current branch name `vc-<digits>-...`.
- **Other updates:** comments, assignee, commits, fields → **update-issue**; infer key from message or branch as in the skill.

If the message is empty or ambiguous, ask once which workflow or which ticket.

Requires the Atlassian MCP server and Jira access for `alertventure.atlassian.net`.
