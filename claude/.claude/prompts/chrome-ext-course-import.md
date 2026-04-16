# Chrome Extension — Course Import Shortcut

Body for a Claude Chrome extension shortcut. Set up once via the extension's shortcut/prompt settings; trigger from any Udemy course page (video player or course overview) where the curriculum is visible.

## How to install in the Chrome extension

1. Open Claude Chrome extension settings → Shortcuts (or "Saved prompts")
2. Create a new shortcut named **course-import**
3. Paste the prompt body below
4. Save. Trigger from any Udemy page with the curriculum sidebar or curriculum section visible.

## Prompt body

---

You are helping me import a full Udemy course curriculum into my Obsidian study vault. I'm Jeremy Spofford — Senior DevOps engineer studying for cloud/DevOps certifications.

## Step 1: Read the curriculum

Read the full course curriculum from this page. It may appear in:
- The **sidebar** on the video player page (collapsible section list on the left)
- The **curriculum section** on the course overview/landing page (expandable section list)

Expand all collapsed sections before reading so you have the full list.

Include: video lectures, hands-on labs.
Skip: quizzes, coding exercises, practice tests — anything that is not a video lecture.

## Step 2: Infer the cert folder

From the course title, infer the cert folder name used in my Obsidian vault:
- "Ultimate AWS Certified Solutions Architect Associate" → `AWS SAA`
- "Certified Kubernetes Administrator (CKA)" → `CKA`
- Use your best judgment for other courses. I will confirm if wrong.

## Step 3: Output the curriculum table

Output a single markdown code block in this exact format:

\`\`\`markdown
## Course Import: <Course Title>
> cert: <cert-folder-name>
> platform: Udemy

| # | Title | Section | Duration |
|---|---|---|---|
| 31 | Budget Setup | 5 - EC2 Fundamentals | 3m |
| 32 | EC2 Basics | 5 - EC2 Fundamentals | 11m |
\`\`\`

Rules:
- Use Udemy's displayed lecture numbers if visible. If not, sequence from 1.
- Duration: normalize to whole minutes. `5:23` → `5m`. `1:02:15` → `62m`. Round up.
- Section: use the section number and title exactly as shown (e.g. `5 - EC2 Fundamentals`).
- Title: use the lecture title exactly as shown on Udemy.
- One row per lecture. Section name goes in the Section column — no section header rows.

## Step 4: Brief report

After the code block, 2 lines:
- Total lectures found
- Any sections where duration data was missing or unclear
