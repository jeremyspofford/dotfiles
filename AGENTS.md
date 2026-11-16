# Agent instructions

A pull request (PR) is a proposed repository change. A changelog records release changes.

## Documentation style — mandatory

All documentation work must follow [docs/WRITING.md](docs/WRITING.md).
This includes README files, docs/, script headers, --help text, changelog entries, and PR descriptions.

1. Use one idea per sentence. Aim for 20 words; use no more than 25.
2. Use active voice and imperative verbs. Number procedure steps.
3. Use plain words. Define terms at first use and choices where they appear.
4. Remove filler. Replace "in order to" with "to".
5. Preserve every fact, condition, warning, exit code, and limit.

A documentation change that ignores these rules is not done.

## Interactive commands — mandatory

Show accepted keys and each action's effect at the prompt. State whether Enter is required.
Do not expose an unexplained third-party menu. Define uppercase and lowercase keys when their actions differ.
Read user decisions from the terminal, never from piped script input. Never choose overwrite for unattended conflicts.
Test prompts through a pseudo-terminal, which simulates a user's terminal.
Include a previously managed file changed locally. A pre-existing unmanaged file does not test the same conflict path.
Verify invalid input, diff followed by another choice, overwrite, skip, skip-all, and quit when those actions exist.
A successful process exit alone does not prove that enrollment completed; check managed-file status.
