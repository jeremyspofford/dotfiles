# Code style

Use [WRITING.md](WRITING.md) for headers, help, comments, and documentation.

1. Start every script with its purpose and usage.
2. Give Bash scripts a `usage()` function. Connect it to `--help` and `-h`.
3. Use argparse for Python help. Argparse reads command arguments and prints help. Give each command a useful description.
4. Format shell scripts with shfmt and tabs. Format Python with Ruff, the repository’s Python formatter, at 100 columns.
5. Separate logical blocks with blank lines. Split long statements. Keep one action per line.
6. Explain reasons in comments. Do not repeat obvious code. Remove stale comments and commented-out code.
7. Keep functions small. Give each function one job. Put the main flow after its helpers.
8. End Python files with a main guard. This condition runs entry code only when the file is executed directly.
9. Use names that explain their purpose. Avoid abbreviations that a new reader must decode.

Use Prettier, the JavaScript formatter, for release helpers.

## Preserve behavior

Run the same tests after a style change. Keep output, exit codes, and golden files unchanged.
Golden files store expected output. Add missing help without changing other behavior.
Record any file that needs a behavior change before it can meet these rules.

Imported helper modules may provide help only. Keep their existing behavior when called without help.
Sourced shell configuration is not a command. Do not add argument parsing that changes the caller’s shell.
