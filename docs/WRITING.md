# Writing rules

Use plain technical English. ASD-STE100 is a standard for Simplified Technical English.
These local rules use a lighter form of that standard. They do not claim certification.

## Sentences and words

- Put one idea in each sentence. Aim for 20 words. Use no more than 25 words.
- Use active voice. Name who does the action.
- Start steps with imperative verbs: run, check, copy, or remove.
- Use numbered steps for procedures.
- Use plain words. Define each term at first use in each document.
- Define every prompt or command choice where you present it.
- Replace "in order to" with "to".
- Delete filler such as "please note that" and "it is important to".

## Keep the facts

Simplify sentences, never content. Preserve every fact, condition, warning, exit code, and limit.
Keep parameter names, examples, commands, paths, and version numbers correct.
State conditions next to the action they control. Do not hide warnings in another document.

## Check a change

1. List the original facts and conditions.
2. Rewrite the text with the rules above.
3. Match each original fact to the new text.
4. Check commands, choices, examples, exit codes, and limits against the code.
5. Record any corrected stale claim and its evidence. Do not silently drop it.
6. Update tests that depend on changed wording. Keep their original checks.

A pull request is a proposed repository change. A changelog records release changes.
Use these rules for README files, docs/, script headers, help text, changelog entries, and pull request descriptions. Do not rewrite historical records unless the owner requests it.
