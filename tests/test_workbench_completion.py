"""Exercise native completion with real Tab presses in a disposable zsh terminal."""
import os
from pathlib import Path
import pty
import select
import shlex
import subprocess
import tempfile
import time
import unittest


COMPLETION = (Path(__file__).resolve().parents[1] /
              "chezmoi/dot_config/private_workbench/private_shell/completion.zsh")


class CompletionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix="workbench-completion-")
        cls.addClassCleanup(cls.tmp.cleanup)
        cls.home = Path(cls.tmp.name).resolve()
        cls.capture = cls.home / "captured"
        cls.invoked = cls.home / "invoked"
        cls.ready = cls.home / "ready"
        cls.checkpoint = "20261020T120000Z-1234abcd"
        cls.custom_checkpoint = "20261020T130000Z-abcd1234"
        cls.custom = cls.home / "custom state"
        for root, ident in ((cls.home / ".local/state/workbench", cls.checkpoint),
                            (cls.custom, cls.custom_checkpoint)):
            record = root / "checkpoints" / ident / "checkpoint.json"
            record.parent.mkdir(parents=True)
            record.write_text("{}\n")
        # Catch accidental execution without invoking any actual transactions.
        (cls.home / ".zshrc").write_text(f"""
autoload -Uz compinit
compinit -D
source {shlex.quote(str(COMPLETION))}
PROMPT='completion-test> '
RPROMPT=''
bindkey -e
bindkey '^I' expand-or-complete
workbench() {{ print invoked >> "$WB_INVOKED"; }}
_capture_buffer() {{
  print -rn -- "$BUFFER" > "$WB_CAPTURE"
  BUFFER=''
  zle reset-prompt
}}
zle -N _capture_buffer
bindkey '^X^T' _capture_buffer
print ready > "$WB_READY"
""")
        cls.master, slave = pty.openpty()
        cls.addClassCleanup(os.close, cls.master)
        try:
            cls.shell = subprocess.Popen(
                ["/bin/zsh", "-di"], stdin=slave, stdout=slave, stderr=slave,
                cwd=cls.home,
                env={"HOME": str(cls.home), "ZDOTDIR": str(cls.home),
                     "PATH": "/usr/bin:/bin", "TERM": "xterm-256color",
                     "WB_CAPTURE": str(cls.capture), "WB_INVOKED": str(cls.invoked),
                     "WB_READY": str(cls.ready)})
        finally:
            os.close(slave)
        cls.addClassCleanup(cls.stop_shell)
        cls.wait_for(cls.ready)

    @classmethod
    def stop_shell(cls):
        if cls.shell.poll() is None:
            cls.shell.terminate()
            try:
                cls.shell.wait(timeout=5)
            except subprocess.TimeoutExpired:
                cls.shell.kill()
                cls.shell.wait(timeout=5)

    @classmethod
    def wait_for(cls, path):
        output = b""
        deadline = time.monotonic() + 10
        while not path.exists():
            if time.monotonic() >= deadline or cls.shell.poll() is not None:
                raise AssertionError(f"Shell did not produce {path.name}: {output!r}")
            if select.select([cls.master], [], [], .02)[0]:
                output += os.read(cls.master, 65536)
        return output

    def complete(self, line):
        self.capture.unlink(missing_ok=True)
        os.write(self.master, line.encode() + b"\t\x18\x14")
        self.wait_for(self.capture)
        self.assertFalse(self.invoked.exists(), "Tab executed Workbench")
        return self.capture.read_text().rstrip()

    def test_subcommands_and_options(self):
        for line, expected in (
            ("workbench doc", "workbench doctor"),
            ("workbench --col", "workbench --color="),
            ("workbench --color al", "workbench --color always"),
            ("workbench --color never pl", "workbench --color never plan"),
            ("workbench plan --exi", "workbench plan --existing="),
            ("workbench plan --existing re", "workbench plan --existing replace"),
            ("workbench plan --format ht", "workbench plan --format html"),
            ("workbench apply --pl", "workbench apply --plan="),
            ("workbench rollback --replace-e", "workbench rollback --replace-edits"),
        ):
            with self.subTest(line=line):
                self.assertEqual(self.complete(line), expected)

    def test_multiple_components_and_following_options(self):
        for line, expected in (
            ("workbench plan --components sh", "workbench plan --components shell"),
            ("workbench plan --components shell gi", "workbench plan --components shell git"),
            ("workbench plan --components shell --exi", "workbench plan --components shell --existing="),
            ("workbench plan --components shell --existing re", "workbench plan --components shell --existing replace"),
            ("workbench checkpoint --components he", "workbench checkpoint --components herdr"),
            ("workbench plan --components zo", "workbench plan --components zoetrope"),
            ("workbench apply --inter", "workbench apply --interactive"),
        ):
            with self.subTest(line=line):
                self.assertEqual(self.complete(line), expected)

    def test_checkpoint_ids_and_custom_state_directory(self):
        line = "workbench rollback 2026"
        self.assertEqual(self.complete(line), "workbench rollback " + self.checkpoint)
        for flag in (f"--state-dir {shlex.quote(str(self.custom))}",
                     f"--state-dir={shlex.quote(str(self.custom))}",
                     "--state-dir '~/custom state'"):
            prefix = f"workbench {flag} rollback "
            with self.subTest(flag=flag):
                self.assertEqual(self.complete(prefix + "2026"), prefix + self.custom_checkpoint)

    def test_missing_state_directory_is_not_created(self):
        missing = self.home / "missing"
        line = f"workbench --state-dir {missing} rollback 2026"
        self.assertEqual(self.complete(line), line)
        self.assertFalse(missing.exists())

    def test_plan_hash_is_not_guessed(self):
        line = "workbench apply --plan "
        self.assertEqual(self.complete(line), line.rstrip())


if __name__ == "__main__":
    unittest.main()
