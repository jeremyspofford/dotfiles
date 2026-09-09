---
name: jira
description: Jira + git workflows for VC and FT via Atlassian MCP. Workflows — create-issue (new tickets with acceptance criteria), start-branch (branch from origin/dev + In Progress), and update-issue (comments, fields, transitions, commits). Use for /start-jira, /update-jira, /jira with free text, or keys like VC-201 / FT-3309.
---

# Jira — Atlassian MCP

Orchestrate **GitLab/Jira** conventions using Atlassian MCP tools. Pair with **atlassian-defaults** (cloud site, default project).

**MCP server:** `plugin-atlassian-atlassian` (not `atlassian`). Tools include `getJiraIssue`, `editJiraIssue`, `transitionJiraIssue`, `getTransitionsForJiraIssue`, `getJiraIssueTypeMetaWithFields`, `addCommentToJiraIssue`, `createJiraIssue`.

## Workflows at a glance

| Workflow | Purpose | Typical invocation |
| --- | --- | --- |
| **create-issue** | Create a new VC issue or sub-task with acceptance criteria | `/jira create`, `/jira new ticket`, "create a ticket for …" |
| **start-branch** | Branch from `origin/dev` from ticket summary; then **In Progress** if available | `/start-jira`, `/jira start`, `/jira start-branch` |
| **update-issue** | Comments, field edits, status transitions, commit snippets as comments | `/update-jira`, `/jira update`, `/jira move to done`, … |

Resolve which workflow applies from the user message: "create / new ticket / make a ticket" → **create-issue**; "start work / branch / ticket" → **start-branch**; "comment / update field / transition / sync commits / move to X" → **update-issue**. If both could apply, ask once.

## Dispatch: `/jira` with free text after the command

When the user runs **`/jira`** (or **`/jira …`**) with natural language and no explicit subcommand:

1. **Parse intent** from the remainder of the message (case-insensitive). Examples:
   - **create-issue:** "create a ticket", "new ticket for", "make a jira for", "open a task for …"
   - **start-branch:** "start", "begin", "branch", "check out ticket", plus a key like `201` / `VC-201`, or "start work on …"
   - **update-issue — transition:** "move to done", "mark done", "close", "transition to in review", "set status to to do" → target is the **destination status** or **transition name** (infer **Done**, **In Review**, **To Do**, **In Progress**, etc.)
   - **update-issue — comment / sync:** "comment", "note", "post commits", "sync commits"
   - **update-issue — fields:** "assign to …", "due date", "update description"
2. **Resolve issue key**
   - If the message contains `VC-###`, `FT-###`, or lowercase variants, normalize and use that key.
   - Bare digits only: prepend the project prefix — `FT-` in **ft-quoting** (or when the user/context implies Flying Tools); otherwise `VC-` per **atlassian-defaults**.
   - Otherwise, for **update-issue** (including status-only phrases like "move to done"), **infer from git:** `git branch --show-current`; if it matches `vc-<digits>-...` → `VC-<digits>`, or `ft-<digits>-...` → `FT-<digits>`.
   - If the key is still unknown, ask once before calling Jira.
3. **Execute** the matching workflow (**create-issue**, **start-branch**, or **update-issue**). For transitions, use **Change status** under **update-issue**: `getTransitionsForJiraIssue`, map the user's phrase to an available transition's **destination** `to.name` (or transition `name`), then `transitionJiraIssue`. If several transitions match, list them and confirm.
4. **Start date:** For **update-issue** and **start-branch** (when Jira is mutated), apply **Start date (set to today)** below unless the exception applies.
5. **Single-issue assumption:** "move to done" with no key means **the ticket implied by the current branch**, not every open issue.

---

## Shared: defaults and issue key

### Defaults

- Jira cloud ID: `alertventure.atlassian.net`
- Default Jira project: `VC` (VividCloud); **`FT`** (Flying Tools) when working in **ft-quoting** or the user names an `FT-` key
- Branch format: `<project-key-lower>-###-description` (e.g. `vc-201-…`, `ft-3309-…`)
- Browse URL pattern: `https://alertventure.atlassian.net/browse/<ISSUE_KEY>`

### Normalize the issue key

1. Trim whitespace.
2. If input is digits only, prepend `FT-` (ft-quoting context) or `VC-` (default).
3. Uppercase the final key.
4. Validate with `^(VC|FT)-[0-9]+$`. If invalid, ask for correction.

### Resolve key when missing (**update-issue** or `/jira` dispatch)

1. Run `git branch --show-current`.
2. If the branch matches `vc-<digits>-...` → `VC-<digits>`; if `ft-<digits>-...` → `FT-<digits>`.
3. If still unknown, ask for a key or ticket number before calling Jira.

### Project-specific field semantics (FT Work Element)

Flying Tools **Work Element** issues use different fields than VC Tasks. Discover ids via `getJiraIssueTypeMetaWithFields` — do not assume VC field names apply.

| Field | Purpose | Where to put content |
| --- | --- | --- |
| **Description** | Context only — why, scope, references | `## Scope`, `## Reference`, background. **No checklist.** |
| **Definition of Done** (`customfield_10367`) | Testable completion criteria | Same substance as "acceptance criteria" — bullets, prose, or checkboxes |
| **Work Element Estimate** (`customfield_10103`) | Points estimate | Numeric (e.g. `8`) |

**Do not** duplicate the checklist in Description **and** Definition of Done. **Do not** post Definition of Done as a comment — Jira gates **In Progress** on the custom field.

#### Creating an FT Work Element (field-by-field reliability)

`createJiraIssue` reliably sets `summary`, `issueTypeName`, `parent`, `assignee_account_id`, and `description` (Markdown is fine with `contentFormat: "markdown"`). Set the FT custom fields in a **follow-up `editJiraIssue`**, then verify:

1. `createJiraIssue` — core fields above (issue lands in **To Do**).
2. `editJiraIssue` — `customfield_10367` (Definition of Done; ADF + `contentFormat: "adf"`) and `customfield_10103` (estimate; plain number).
3. `getJiraIssue` — confirm `parent`, `customfield_10103`, `customfield_10367`, and any `issuelinks` actually persisted.

**Gotcha — estimate at create time:** `customfield_10103` passed via `createJiraIssue.additional_fields` is **silently dropped** (no error; the field reads back `null`). Always set the estimate with a follow-up `editJiraIssue`.

#### Transition gate: FT Work Element → In Progress

Jira rejects the transition unless **Description**, **Definition of Done**, and **Work Element Estimate** are all set. Before `transitionJiraIssue`:

1. `editJiraIssue` — description (context only)
2. `editJiraIssue` — `customfield_10367` (Definition of Done) and `customfield_10103` (estimate)
3. `transitionJiraIssue` — `{ "transition": { "id": "<id>" } }` (not `transitionId` at top level)

#### ADF for Definition of Done (`customfield_10367`)

Via the API, this field requires **Atlassian Document Format**, not plain Markdown strings. **Pass the ADF object in `fields.customfield_10367` and set `contentFormat: "adf"`** on the `editJiraIssue` (or `createJiraIssue`) call. Two failure modes if you get this wrong:

- ADF **object** with the default / `markdown` content format → the tool returns **`INVALID_INPUT`**.
- Plain **Markdown string** (even with `contentFormat: "markdown"`) → Jira returns **`Operation value must be an Atlassian Document`**.

**Content shape is flexible** — use whatever reads best:

- **`bulletList`** — simple criteria bullets (common default)
- **`taskList` / `taskItem`** — interactive checkboxes; convenient when copy-pasting acceptance criteria from a `- [ ]` list
- **Paragraphs** — short prose when a checklist is overkill

Example (`taskList` — optional, not required):

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "taskList",
      "attrs": { "localId": "" },
      "content": [
        {
          "type": "taskItem",
          "attrs": { "localId": "", "state": "TODO" },
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "Specific testable criterion" }]
            }
          ]
        }
      ]
    }
  ]
}
```

Build ADF in a temp JSON file or script when `editJiraIssue` cannot accept deeply nested inline JSON. Pasting into the Jira UI is fine — the UI picks the format.

If ADF updates fail via MCP, tell the user which fields are missing and paste the criteria for manual entry into **Definition of Done** — do not substitute a comment.

### Start date (set to today)

When Jira is updated via **update-issue** or **start-branch**, set the issue **Start date** custom field to **today** so active work is reflected on the timeline.

#### Today's value

- Prefer the chat/session **Today's date** when the environment provides it (use that calendar day).
- Otherwise use the current date in `YYYY-MM-DD` (agent environment).

#### Field id

- Do **not** hard-code. From `getJiraIssue`, read `fields.issuetype.id`, then call `getJiraIssueTypeMetaWithFields` with `cloudId`, `projectIdOrKey: VC`, and `issueTypeId`. Find the field whose name is **Start date** (or the project's equivalent) and use its `key` (e.g. `customfield_…`) in `editJiraIssue.fields`.
- If the issue type has no Start date field or it is not editable, skip and mention that in the summary.

#### When to set (update-issue)

- **Do not set** when the **only** Jira write is `addCommentToJiraIssue` (**comment-only**).
- **Do not set** when the batch includes a transition **to Done** (preserve Start date when closing the issue, even if other fields are edited in the same batch).
- **Set** Start date to today in **all** other **update-issue** batches (assignee, sprint, other field edits, transitions to **In Progress**, **In Review**, **To Do**, etc.).

Apply Start date with **`editJiraIssue`** in the same **field edits before transitions** order as **update-issue**.

#### When to set (start-branch)

- After git checkout succeeds and **before** transitioning to **In Progress**, set Start date to today (same discovery as above).
- If the issue is **already** In Progress (transition skipped), **do not** change Start date.

---

## Workflow: create-issue

Create a new issue (Task, Story, Bug, Sub-task) in the VC project using Atlassian MCP. **Acceptance criteria are mandatory on every ticket.**

### Supported input

- `/jira create` — gather details interactively.
- `/jira create a ticket for <description>` — use description as starting context; draft details and present for approval.
- Any phrasing that expresses creating a new ticket ("new Jira for …", "open a task for …").

### Steps

1. **Gather required fields** — ask the user for any missing information before drafting:
   - **Summary** (title) — one concise sentence.
   - **Issue type** — Task, Story, Bug, or Sub-task (if Sub-task, ask for the parent key).
   - **Assignee** — default to current user if inferable from git context; otherwise ask. Use `lookupJiraAccountId` to resolve a display name to an account ID.
   - **Acceptance criteria** — at least one measurable condition (see template below). **Required. Never omit.**

2. **Draft the full description** using the **Mandatory description template** below. Present the complete draft to the user and ask for approval or edits before creating.

3. **Confirm before creating** — show: summary, issue type, assignee, acceptance criteria, and description preview. Ask explicit yes/no.

4. **Create** via `createJiraIssue`:
   - `cloudId`: `8f1abd7d-02dc-4ded-a289-e6ed5d773344`
   - `projectKey`: `VC`
   - `issueTypeName`: as chosen
   - `summary`: confirmed summary
   - `description`: full description using the mandatory template
   - `assignee_account_id`: resolved account ID (if provided)
   - `parent`: parent key as string (Sub-tasks only)
   - `contentFormat`: `markdown`

5. **Report** the created issue key and browse URL: `https://alertventure.atlassian.net/browse/<KEY>`.

### Mandatory description template

**Rule:** Every new issue MUST use this structure. Do not omit sections; use `N/A` or `None` when not applicable. Acceptance criteria is NEVER optional.

```markdown
### Summary

(One paragraph describing the work, its context, and why it matters.)

### Context

(Background: what problem does this solve, what system/component is affected, any relevant prior work or tickets.)

### Acceptance criteria

- [ ] (Specific, testable condition 1)
- [ ] (Specific, testable condition 2)
- [ ] (Add more as needed — at least one is required)

### Other information

(Dependencies, risks, links to docs, related tickets, or N/A.)
```

### Acceptance criteria guidelines

- Each criterion must be **specific and testable** — someone should be able to verify it as pass/fail.
- Prefer "Given/When/Then" phrasing for behavioural criteria, or direct assertions for technical ones.
- Minimum one criterion per ticket. Aim for 2–5; split the ticket if more are needed.

#### Examples of good acceptance criteria

```markdown
- [ ] `npm audit --audit-level=high` exits 0 with no critical or high findings.
- [ ] The CI `dependency-audit` job passes on all MRs targeting dev.
- [ ] A non-root USER is specified in apps/usdz-converter/Dockerfile and the container build succeeds.
- [ ] CloudFront distributions have a WAF web ACL attached (verified via `terraform plan` showing no diff).
```

#### Examples of bad acceptance criteria (too vague)

```markdown
- [ ] It works.
- [ ] Security is improved.
- [ ] Done.
```

### Safety (**create-issue**)

- Never create a ticket without user approval of the draft.
- Never omit acceptance criteria — ask the user to provide them if they have not.
- If issue type is Sub-task, validate the parent key exists (`getJiraIssue`) before creating.

---

## Workflow: start-branch

Create a local git branch from `origin/dev` using the Jira issue key and issue summary, then set the issue to **In Progress** when that transition is available.

### Supported input

- `/start-jira VC-201`, `vc-201`, or `201`
- `/jira start …` or `/jira start-branch …` with the same key forms

If no argument is provided, ask for a Jira key or ticket number before continuing.

### Target status after git succeeds

**In Progress** — match **destination** status name case-insensitively; prefer the exact name `In Progress` if multiple candidates exist.

### Steps

1. **Normalize** the issue key (shared rules above).
2. **Fetch** the Jira issue — tool: `getJiraIssue` — `cloudId`, `issueIdOrKey`, `fields`: `["summary", "status", "assignee"]`.
3. **Build slug** from `summary`:
   - Lowercase; replace `&` with `and`; replace non-alphanumeric runs with `-`; collapse repeated hyphens; trim leading/trailing hyphens; limit to ~50 characters at a hyphen boundary; if empty use `work-item`.
4. **Branch name** — lowercase key + slug: `VC-201` → `vc-201-<slug>`.
5. **Confirm** before changing git: show key, summary, status, proposed branch name, and that Jira will move to **In Progress** after a successful git step when the workflow allows. Ask explicit yes/no (or numbered choice if an existing branch conflicts — see safety).
6. **Git** — on approval, run:

```bash
git fetch origin dev
git checkout -b <branch-name> origin/dev
```

After checkout succeeds:

1. **Re-read status** — `getJiraIssue` with `fields`: `["status"]`. If already **In Progress** (case-insensitive), skip steps 2–3 and go to **Report**.
2. **Start date** — set **Start date** to today via `editJiraIssue` per **Start date (set to today)** (before the transition).
3. **Transition** to **In Progress** — `getTransitionsForJiraIssue` → pick transition whose **to.name** is **In Progress** (do **not** guess ids); if none exist, report git success and list transitions. If found: `transitionJiraIssue` with `transition`: `{ "id": "<id>" }`.
4. **Report** current branch (`git branch --show-current`), Jira URL, whether Start date was set, and whether Jira was set to In Progress, skipped, or could not be transitioned.

### Safety (**start-branch**)

- Issue not found → stop.
- Summary missing → stop; ask for a manual branch suffix.
- Branch exists locally → ask switch vs create new (do not assume).
- Branch exists on remote → ask track vs different suffix.
- **If git branch creation fails, do not transition Jira.**

---

## Workflow: update-issue

Apply changes to an existing Jira issue using Atlassian MCP.

### Supported input

- `/update-jira` — resolve key from current branch when possible, else ask.
- `/update-jira VC-201`, `vc-201`, or `201`
- `/jira update …`, `/jira update-issue …`, or free text such as `/jira move to done` (see **Dispatch** above)

### Steps

1. **Normalize** the issue key (shared rules + optional branch inference above).
2. **Confirm intent** before mutating Jira: list operations (comment, transition, field updates, commit summary, **Start date → today** when applicable). If ambiguous (which status, which date field other than Start date), ask once.
3. **Load** current issue (recommended) — `getJiraIssue` with `fields` as needed (e.g. `summary`, `status`, `assignee`, `issuetype`, `description`, `duedate`, custom fields).
4. **Execute** updates in order: field edits (including **Start date** per **Start date (set to today)** when applicable) → transitions → comments, unless the user specified otherwise.

#### Add a comment

- Tool: `addCommentToJiraIssue` — `cloudId`, `issueIdOrKey`, `commentBody`; use `contentFormat`: `markdown` for Markdown bodies.

#### Post recent git commits

Jira has no native "commits" field in this path — **post a comment** with a concise list.

```bash
git log --oneline -20
```

or since `origin/dev`:

```bash
git log --oneline origin/dev..HEAD
```

Build a short comment (subjects + SHAs); strip secrets/tokens/private URLs.

#### Edit fields

- Tool: `editJiraIssue` — `cloudId`, `issueIdOrKey`, `fields` per Jira REST edit shape.
- **Order:** field edits (including transition prerequisites) **before** `transitionJiraIssue`.
- **Description:** Markdown/plain text is fine for `description`.
- **Rich-text custom fields** (e.g. FT Definition of Done): ADF object in `fields`, not Markdown — see **ADF for Definition of Done** above.

#### Enrich an existing issue (update-issue pattern)

When the user asks to add description, definition of done, estimate, and move to **In Progress**:

1. `getJiraIssue` + `getJiraIssueTypeMetaWithFields` for the issue's project and type.
2. Draft **description** (context) and **definition of done** (checklist) separately; confirm with user if ambiguous.
3. `editJiraIssue` with description, DoD field, and estimate in one or two calls.
4. `getTransitionsForJiraIssue` → `transitionJiraIssue` to **In Progress**.
5. Report browse URL and which fields were set. If transition fails, quote Jira's required-field error and fix fields — do not leave a redundant DoD comment as a workaround.

#### Common patterns

- **Due date:** `fields.duedate` as `YYYY-MM-DD` when present on the issue type.
- **Start date:** required on qualifying updates — see **Start date (set to today)** in Shared; discover the field key via `getJiraIssueTypeMetaWithFields` and set `fields.<key>` to `YYYY-MM-DD`.
- **Assignee:** `lookupJiraAccountId` (team names in **atlassian-defaults**), then set per API shape (often object with `id`).

#### Change status

Never guess transition ids.

1. `getTransitionsForJiraIssue` — `cloudId`, `issueIdOrKey`.
2. Match the user's target to an available transition (case-insensitive; confirm if several match).
3. `transitionJiraIssue` — `cloudId`, `issueIdOrKey`, `transition`: `{ "id": "<id>" }`.
4. If transition fails with required-field errors, load field metadata, set missing fields, retry once.
5. If the desired state is not available, report options and stop.

### Safety (**update-issue**)

- Issue not found → stop and report.
- Do not paste credentials or private URLs into comments.
- After updates, share `https://alertventure.atlassian.net/browse/<ISSUE_KEY>`.
