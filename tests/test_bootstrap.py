"""bootstrap.sh end to end in a disposable HOME, with recording stubs for brew and mise."""
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "bootstrap.sh"


def real_chezmoi_dir():
    found = subprocess.run(["mise", "which", "chezmoi"], capture_output=True, text=True)
    return str(Path(found.stdout.strip()).parent) if found.returncode == 0 else None


@unittest.skipUnless(real_chezmoi_dir(), "chezmoi is not installed through mise")
class BootstrapTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory(prefix="workbench-bootstrap-")
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name).resolve()
        self.home = self.root / "home"
        self.home.mkdir()
        self.log = self.root / "calls.log"
        stubs = self.root / "stubs"
        stubs.mkdir()
        # mise: record every call; `exec chezmoi@V -- cmd` runs cmd with the real chezmoi.
        self.stub(stubs / "mise", f'''#!/bin/sh
echo "mise $*" >> "{self.log}"
case $1 in
  exec) shift 2; PATH="{real_chezmoi_dir()}:$PATH" exec "$@" ;;
  ls) echo '{{}}' ;;
esac
''')
        self.stub(stubs / "brew", f'#!/bin/sh\necho "brew $*" >> "{self.log}"\n')
        self.env = {"HOME": str(self.home), "PATH": f"{stubs}:/usr/bin:/bin", "LANG": "en_US.UTF-8"}

    def stub(self, path, text):
        path.write_text(text)
        path.chmod(0o755)

    def bootstrap(self, *args):
        return subprocess.run([str(SCRIPT), *args], env=self.env, capture_output=True, text=True,
                              stdin=subprocess.DEVNULL, timeout=120)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_fresh_machine_reaches_baseline_and_rerun_is_a_no_op(self):
        result = self.bootstrap("--yes", "--name", "Test User", "--email", "you@example.com")
        output = result.stdout + result.stderr
        identity = self.home / ".config/git/local.gitconfig"
        self.assertEqual(stat.S_IMODE(identity.stat().st_mode), 0o600)
        self.assertIn('email = "you@example.com"', identity.read_text())
        self.assertTrue((self.home / ".zshrc").is_file())
        self.assertIn("include", (self.home / ".gitconfig").read_text())
        self.assertFalse((self.home / ".config/mise/conf.d").exists(), "optional tools stay opt-in")
        self.assertIn("Applied and verified.", output)
        self.assertIn("Configuration: all managed files match.", output)
        self.assertIn("sets user.email", output)
        self.assertIn("brew bundle check --no-upgrade --file", "\n".join(self.calls()))
        self.assertIn("mise install chezmoi@", "\n".join(self.calls()))
        self.assertIn("mise install", self.calls())
        checkpoints = list((self.home / ".local/state/workbench/checkpoints").glob("*/checkpoint.json"))
        self.assertEqual(len(checkpoints), 1)

        again = self.bootstrap("--yes", "--email", "other@example.com")
        self.assertIn("Configuration already matches.", again.stdout)
        self.assertIn("Keeping existing", again.stdout)
        self.assertIn('email = "you@example.com"', identity.read_text())
        self.assertEqual(len(list((self.home / ".local/state/workbench/checkpoints").glob("*/checkpoint.json"))), 1)

    def test_identity_carries_over_from_an_existing_gitconfig(self):
        (self.home / ".gitconfig").write_text('[user]\n    name = "Old Name"\n    email = "old@example.com"\n')
        result = self.bootstrap("--yes")
        identity = (self.home / ".config/git/local.gitconfig").read_text()
        self.assertIn('name = "Old Name"', identity)
        self.assertIn('email = "old@example.com"', identity)
        self.assertNotIn("old@example.com", (self.home / ".gitconfig").read_text())
        self.assertIn("Applied and verified.", result.stdout)

    def test_existing_files_are_kept_with_skip(self):
        (self.home / ".zshrc").write_text("# mine\n")
        self.bootstrap("--yes", "--existing", "skip", "--name", "T", "--email", "t@example.com")
        self.assertEqual((self.home / ".zshrc").read_text(), "# mine\n")

    def test_declining_prompts_changes_nothing(self):
        (self.home / ".gitconfig").write_text('[user]\n    name = "N"\n    email = "n@example.com"\n')
        result = subprocess.run([str(SCRIPT)], env=self.env, capture_output=True, text=True,
                                input="\n\nn\nn\n", timeout=120)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("nothing changed", result.stderr)
        self.assertFalse((self.home / ".zshrc").exists())
        self.assertEqual((self.home / ".gitconfig").read_text(), '[user]\n    name = "N"\n    email = "n@example.com"\n')

    def test_missing_identity_without_prompting_fails_before_changes(self):
        result = self.bootstrap("--yes")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Git name and email are required", result.stderr)
        self.assertFalse((self.home / ".zshrc").exists())

    def test_rejects_unknown_options(self):
        self.assertEqual(self.bootstrap("--nope").returncode, 2)
