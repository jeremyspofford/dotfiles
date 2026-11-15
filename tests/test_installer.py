"""Exercise enrollment/update in disposable homes with real Git and chezmoi."""
import hashlib
import errno
import fcntl
import pty
import select
import termios
import time
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
REPO = "https://github.com/jeremyspofford/dotfiles.git"


@unittest.skipUnless(shutil.which("chezmoi") and shutil.which("mise"), "chezmoi/mise required")
class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.home = self.base / "home"
        self.home.mkdir()
        self.seed = self.base / "seed"
        self.seed.mkdir()
        self.env = {
            "PATH": os.environ["PATH"], "HOME": str(self.home), "NO_COLOR": "1",
            "TERM": "dumb", "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull,
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_DATA_HOME": str(self.home / ".local/share"),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
            "XDG_CACHE_HOME": str(self.home / ".cache"),
            # Keep real Git transport/fast-forward behavior without GitHub I/O.
            "GIT_CONFIG_COUNT": "1", "GIT_CONFIG_KEY_0": f"url.file://{self.seed}.insteadOf",
            "GIT_CONFIG_VALUE_0": REPO,
        }
        tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
        for relative in filter(None, tracked):
            target = self.seed / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, target)
        self.git("init", "--quiet", "--initial-branch=main")
        self.git("remote", "add", "origin", REPO)
        self.commit("test: seed installer fixture")
        self.source = self.home / ".local/share/chezmoi"
        self.installer = ["bash", str(self.seed / "install.sh")]

    def run_command(self, command, expected=0, **kwargs):
        result = subprocess.run(command, env=self.env, cwd=self.base, capture_output=True,
                                text=True, start_new_session=True, **kwargs)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def git(self, *arguments):
        return self.run_command(["git", "-C", str(self.seed), *arguments]).stdout

    def commit(self, message):
        self.git("add", ".")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                 "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", message)

    def snapshot(self):
        managed = self.run_command(["chezmoi", "managed", "-0"]).stdout.split("\0")
        result = {}
        for relative in filter(None, managed):
            path = self.home / relative
            content = (os.readlink(path) if path.is_symlink() else
                       hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None)
            result[relative] = (stat.S_IMODE(path.lstat().st_mode), content)
        return result

    def test_backup_idempotence_and_fast_forward_update(self):
        (self.home / ".zshrc").write_text("# Original zsh\n")
        external = self.base / "outside aliases"
        external.write_text("# Original aliases\n")
        (self.home / ".aliases").symlink_to(external)
        (self.home / "old-bashrc").write_text("# Original bash\n")
        (self.home / ".bashrc").symlink_to("old-bashrc")
        (self.home / ".zprofile").symlink_to("absent-target")
        first = self.run_command(self.installer + ["--defaults"], umask=0o077)
        self.assertIn("END SUMMARY", first.stdout)
        self.assertIn("chezmoi status: CLEAN", first.stdout)
        backups = list((self.home / "dotfleet-backups").iterdir())
        self.assertEqual(len(backups), 1)
        backup = backups[0]
        self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o700)
        self.assertEqual((backup / "home/.zshrc").read_text(), "# Original zsh\n")
        self.assertEqual(os.readlink(backup / "home/.aliases"), str(external))
        self.assertEqual(os.readlink(backup / "home/.bashrc"), "old-bashrc")
        self.assertEqual(os.readlink(backup / "home/.zprofile"), "absent-target")
        self.assertEqual((backup / "external" / str(external).lstrip("/")).read_bytes(), external.read_bytes())
        self.assertIn("symlink", (backup / "MANIFEST").read_text())
        self.assertIn("external", (backup / "MANIFEST").read_text())
        self.assertEqual(external.read_text(), "# Original aliases\n")
        for name in (".zshrc", ".zprofile", ".zshenv", ".aliases", ".gitconfig", ".secrets"):
            self.assertTrue((self.home / name).is_file(), name)
            self.assertFalse((self.home / name).is_symlink(), name)
        self.assertEqual(stat.S_IMODE((self.home / ".secrets").stat().st_mode), 0o600)
        self.assertFalse((self.home / "install.sh").exists())
        before = self.snapshot()
        # Compare managed content/modes, not chezmoi's mutable state database.
        self.run_command(self.installer + ["--defaults"], umask=0o022)
        self.assertEqual(self.snapshot(), before)
        self.assertEqual(self.run_command(["chezmoi", "status"], umask=0o022).stdout, "")
        self.assertEqual(len(list((self.home / "dotfleet-backups").iterdir())), 2)
        self.assertEqual(self.run_command(["git", "-C", str(self.source), "status", "--porcelain"]).stdout, "")
        self.assertEqual(self.run_command(["git", "-C", str(self.source), "ls-files", ".secrets"]).stdout, "")
        # A later upstream commit must actually be pulled and applied.
        with (self.seed / "dot_zprofile").open("a") as handle:
            handle.write("\n# Fixture update\n")
        self.commit("fix: exercise installer update")
        self.run_command(self.installer + ["--defaults"])
        self.assertIn("# Fixture update", (self.home / ".zprofile").read_text())
        self.assertEqual(self.run_command(["git", "-C", str(self.source), "rev-parse", "HEAD"]).stdout,
                         self.git("rev-parse", "HEAD"))
        self.assertEqual(self.run_command(["chezmoi", "status"]).stdout, "")

    def test_missing_git_or_curl_fails_with_summary_before_changes(self):
        for missing in ("git", "curl"):
            with self.subTest(missing=missing):
                binary_dir = self.base / ("without-" + missing)
                binary_dir.mkdir()
                for tool in ("dirname", "cat", "tar", "git", "curl"):
                    if tool != missing:
                        (binary_dir / tool).symlink_to(shutil.which(tool))
                env = {**self.env, "PATH": str(binary_dir)}
                result = subprocess.run([shutil.which("bash"), str(self.seed / "install.sh"), "--defaults"],
                                        env=env, cwd=self.base, capture_output=True, text=True)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                self.assertIn("Missing required commands: " + missing, result.stderr)
                self.assertIn("END SUMMARY", result.stdout)
                self.assertFalse(self.source.exists())
                self.assertFalse((self.home / "dotfleet-backups").exists())

    def test_first_install_from_detached_checkout(self):
        self.git("checkout", "--detach")
        expected = self.git("rev-parse", "HEAD")
        self.run_command(self.installer + ["--defaults"])
        self.assertEqual(self.run_command(["git", "-C", str(self.source), "rev-parse", "HEAD"]).stdout, expected)
        self.assertEqual(self.run_command(["git", "-C", str(self.source), "branch", "--show-current"]).stdout, "main\n")
        self.assertEqual(self.git("branch", "--show-current"), "")

    def test_refuses_dirty_source_and_unrelated_repository(self):
        self.run_command(self.installer + ["--defaults"])
        before = self.snapshot()
        (self.source / "dot_zshrc").write_text("# local edits\n")
        result = self.run_command(self.installer + ["--defaults"], expected=1)
        self.assertIn("Checkout has local changes", result.stderr)
        self.assertIn("END SUMMARY", result.stdout)
        self.assertEqual((self.home / ".zshrc").read_text(), (self.seed / "dot_zshrc").read_text())
        self.run_command(["git", "-C", str(self.source), "remote", "set-url", "origin", "https://example.invalid/other.git"])
        result = self.run_command(self.installer + ["--defaults"], expected=1)
        self.assertIn("Source belongs to another repository", result.stderr)
        self.assertEqual(self.snapshot(), before)

    def test_first_run_prompts_on_terminal_and_reuses_personal_identity(self):
        master, slave = pty.openpty()

        def controlling_terminal():
            os.setsid()
            fcntl.ioctl(slave, termios.TIOCSCTTY, 0)

        process = subprocess.Popen(self.installer, cwd=self.base, env=self.env,
                                   stdin=subprocess.PIPE, stdout=slave, stderr=slave,
                                   preexec_fn=controlling_terminal)
        os.close(slave)
        self.addCleanup(os.close, master)
        self.addCleanup(lambda: process.poll() is None and process.kill())
        # If initialization ever reads stdin, these invalid answers break it.
        process.stdin.write(b"NOT-A-DOMAIN\nWRONG NAME\nwrong@example.invalid\n")
        process.stdin.close()
        responses = [(b"Domain (core, personal, work, client)", b"personal\r"),
                     (b"Git name (optional)", b"Fixture Person\r"),
                     (b"Git email (optional)", b"fixture@example.invalid\r")]
        transcript = b""
        answered = 0
        deadline = time.monotonic() + 45
        while time.monotonic() < deadline:
            ready, _, _ = select.select([master], [], [], 0.1)
            if ready:
                try:
                    chunk = os.read(master, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        break
                    raise
                if not chunk:
                    break
                transcript += chunk
                if answered < len(responses) and responses[answered][0] in transcript:
                    os.write(master, responses[answered][1])
                    answered += 1
            elif process.poll() is not None:
                break
        if process.poll() is None:
            process.kill()
        process.wait(timeout=5)
        self.assertEqual(process.returncode, 0, transcript.decode(errors="replace"))
        self.assertEqual(answered, 3, transcript.decode(errors="replace"))
        config = (self.home / ".config/chezmoi/chezmoi.toml").read_text()
        self.assertIn('domain = "personal"', config)
        identity = ["git", "config", "--file", str(self.home / ".gitconfig")]
        self.assertEqual(self.run_command(identity + ["user.name"]).stdout.strip(), "Fixture Person")
        self.assertEqual(self.run_command(identity + ["user.email"]).stdout.strip(), "fixture@example.invalid")
        # Updates must succeed without a TTY and retain the chosen identity.
        self.run_command(self.installer)
        self.assertEqual((self.home / ".config/chezmoi/chezmoi.toml").read_text(), config)
        self.assertEqual(self.run_command(["chezmoi", "status"]).stdout, "")

    def test_no_terminal_never_consumes_piped_answers(self):
        (self.home / ".zshrc").write_text("# Preserve until prompted\n")
        result = self.run_command(self.installer, expected=1, input="personal\nWrong Person\nwrong@example.invalid\n")
        self.assertIn("First enrollment needs a terminal", result.stderr)
        self.assertIn("Result: FAILED", result.stdout)
        self.assertEqual((self.home / ".zshrc").read_text(), "# Preserve until prompted\n")
        self.assertFalse((self.home / ".config/chezmoi/chezmoi.toml").exists())


if __name__ == "__main__":
    unittest.main()
