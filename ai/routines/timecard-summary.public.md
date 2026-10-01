Produce my timecard summary. Run on Fridays and on the last weekday of each month; on any other day reply "Not a timecard day; skipping." and stop.

Window: from the day after my previous submission (the previous Friday or last weekday of a month, whichever is later, and never before the 1st of the current month) through today. Weekdays only.

1. Git: my repos live under ~/workspace, one folder per client. Treat every folder as a client except dotfiles, archive, and personal. In every repo at any depth (skip node_modules/.venv/vendor), run `git log --all --since=<window start>` and keep commits authored by me. Match my name and email variants, and be careful with other people who share my first name. Read commit bodies and diffs for substance, not just subjects. Spread multi-day infrastructure work across the days it plausibly happened, never before the window start.
2. Jira (best-effort): issues updated in the window where I'm assignee or reporter. Status changes, my comments, issues I closed. Skip silently if unavailable.
3. Non-code work (best-effort): dated entries in ~/workspace/worklog.md, and substantive work in recent chats.

Output: a one-line header with the date range, then one section per client with one short paragraph (2-4 sentences, no bullets) per weekday that had activity, in order. Summarize what was accomplished, grounded in the real technical content. Note decisions (mark inferred ones) and anything open or blocked.

Style: declarative, no pronouns ("Migrated Lambda secrets to Terraform-managed config"). Never cite ticket, issue, or MR numbers; describe the work instead. No hours; I fill those in. List any weekday with no activity at all at the top so I can fill it in, and never invent work.
