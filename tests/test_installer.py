"""Exercise enrollment/update in disposable homes with real Git and chezmoi."""
import hashlib
import errno
import fcntl
import pty
import select
import signal
import termios
import time
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import tomllib
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
        self.source = self.home / "dotfiles"
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
        self.assertFalse((self.home / ".local/share/chezmoi").exists())
        self.assert_fresh_shell_uses_visible_checkout()
        self.assertIn("Your dotfiles live in: ~/dotfiles — a git checkout. Edit files there, then run: chezmoi apply", first.stdout)
        self.assertNotIn("Source:", first.stdout)
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

    def assert_fresh_shell_uses_visible_checkout(self):
        config = tomllib.loads((self.home / ".config/chezmoi/chezmoi.toml").read_text())
        self.assertEqual(config["sourceDir"], str(self.source))
        # Only a home and an ordinary executable search path: no XDG/CHEZMOI
        # variables, per-command flags, or inherited shell functions/aliases.
        clean_env = {"HOME": str(self.home), "PATH": self.env["PATH"], "TERM": "dumb"}
        result = subprocess.run(
            ["bash", "-ic", 'cd /; chezmoi source-path && chezmoi status && chezmoi apply && chezmoi status'],
            env=clean_env, cwd=self.base, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout, str(self.source) + "\n")

    @staticmethod
    def tree_snapshot(root):
        # Compare all saved bytes, links, and modes, including Git metadata.
        snapshot = {}
        for path in sorted(root.rglob("*")):
            content = (os.readlink(path) if path.is_symlink() else
                       hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None)
            snapshot[str(path.relative_to(root))] = (stat.S_IMODE(path.lstat().st_mode), content)
        return snapshot

    def seed_legacy_install(self, explicit_source=False):
        legacy = self.home / ".local/share/chezmoi"
        legacy.parent.mkdir(parents=True)
        self.run_command(["git", "clone", REPO, str(legacy)])
        config = self.home / ".config/chezmoi/chezmoi.toml"
        config.parent.mkdir(parents=True)
        source_setting = f'sourceDir = "{legacy}"\n' if explicit_source else ""
        config.write_text(source_setting + 'umask = 0o077\n[data]\ndomain = "personal"\n'
                          'gitName = "Fixture Person"\ngitEmail = "fixture@example.invalid"\n')
        self.run_command(["chezmoi", "apply"])
        self.assertEqual(self.run_command(["chezmoi", "status"]).stdout, "")
        return legacy, config

    def check_legacy_migration(self, explicit_source):
        legacy, config = self.seed_legacy_install(explicit_source)
        saved_config = config.read_bytes()
        inode = legacy.stat().st_ino
        before = self.snapshot()
        archive = legacy.with_name("chezmoi.pre-reset-20261115")
        self.run_command(["git", "clone", str(legacy), str(archive)])
        (archive / "keep-this-file").write_text("Preserved archive\n")
        archived = self.tree_snapshot(archive)
        # Simulate pulling the update, with no changes to managed home outputs.
        with (self.seed / "README.md").open("a") as handle:
            handle.write("\nFixture upstream update.\n")
        self.commit("docs: exercise migration fast-forward")
        result = self.run_command(self.installer)
        self.assertIn("Moving your existing dotfiles checkout to ~/dotfiles", result.stdout)
        self.assertFalse(legacy.exists())
        self.assertEqual(self.source.stat().st_ino, inode)  # moved, not re-cloned
        self.assertEqual(self.run_command(["git", "-C", str(self.source), "rev-parse", "HEAD"]).stdout,
                         self.git("rev-parse", "HEAD"))
        self.assertEqual(self.tree_snapshot(archive), archived)
        self.assertEqual(self.snapshot(), before)
        self.assert_fresh_shell_uses_visible_checkout()
        data = tomllib.loads(config.read_text())["data"]
        self.assertEqual(data["domain"], "personal")
        self.assertEqual(data["gitName"], "Fixture Person")
        backup = next((self.home / "dotfleet-backups").iterdir())
        self.assertEqual((backup / "home/.config/chezmoi/chezmoi.toml").read_bytes(), saved_config)
        # Repeat after migration; neither the archive nor managed state changes.
        self.run_command(self.installer)
        self.assertEqual(self.snapshot(), before)
        self.assertEqual(self.tree_snapshot(archive), archived)

    def test_migrates_default_legacy_source_and_preserves_archive(self):
        self.check_legacy_migration(explicit_source=False)

    def test_migrates_explicit_legacy_source_config(self):
        self.check_legacy_migration(explicit_source=True)

    def test_occupied_visible_path_changes_nothing(self):
        legacy, _ = self.seed_legacy_install()
        for kind in ("directory", "file", "unrelated-repository", "symlink"):
            with self.subTest(kind=kind):
                if kind == "file":
                    self.source.write_text("Not dotfiles\n")
                elif kind == "symlink":
                    self.source.symlink_to(legacy, target_is_directory=True)
                else:
                    self.source.mkdir()
                    (self.source / "keep-me").write_text("Unrelated files\n")
                    if kind == "unrelated-repository":
                        self.run_command(["git", "-C", str(self.source), "init", "--quiet"])
                        self.run_command(["git", "-C", str(self.source), "remote", "add", "origin", "https://example.invalid/other.git"])
                before = self.tree_snapshot(self.home)
                result = self.run_command(self.installer, expected=1)
                self.assertIn(str(self.source), result.stderr)
                self.assertIn("must not be a symlink" if kind == "symlink" else "already exists and is not this repository's clone", result.stderr)
                self.assertEqual(self.tree_snapshot(self.home), before)
                self.assertTrue(legacy.is_dir())
                self.assertFalse((self.home / "dotfleet-backups").exists())
                if self.source.is_symlink() or self.source.is_file():
                    self.source.unlink()
                else:
                    shutil.rmtree(self.source)

    def test_bootstrap_domain_option_selects_each_documented_domain(self):
        for domain in ("personal", "work", "client", "core"):
            with self.subTest(domain=domain):
                # Each selection starts with no saved profile; updates preserve
                # existing profile data through promptStringOnce.
                config = self.home / ".config/chezmoi/chezmoi.toml"
                config.unlink(missing_ok=True)
                self.run_command(["bash", str(self.seed / "scripts/bootstrap.sh"), "--domain", domain])
                data = tomllib.loads(config.read_text())["data"]
                self.assertEqual(data["domain"], domain)
                self.run_command(["bash", str(self.seed / "scripts/bootstrap.sh"), "--domain", "core"])
                self.assertEqual(tomllib.loads(config.read_text())["data"]["domain"], domain)
                self.assertEqual(self.run_command(["chezmoi", "status"]).stdout, "")

    def installed_tool(self, tool, version, commands):
        # Use real Mise discovery/activation with tiny offline executables.
        binary_dir = self.home / ".local/share/mise/installs" / tool / version / "bin"
        binary_dir.mkdir(parents=True)
        for name in commands:
            binary = binary_dir / name
            binary.write_text(f"#!/bin/sh\nprintf '%s\\n' '{name}-{version}'\n")
            binary.chmod(0o755)
        return binary_dir

    def saved_tools(self):
        config = self.home / ".config/chezmoi/chezmoi.toml"
        return tomllib.loads(config.read_text())["data"]["miseTools"]

    def rendered_tools(self):
        return tomllib.loads((self.home / ".config/mise/config.toml").read_text())["tools"]

    def test_existing_mise_pins_survive_enrollment_apply_and_updates(self):
        self.installed_tool("node", "22.9.0", ["node", "codex"])
        self.installed_tool("node", "22.10.0", ["node", "codex"])
        config = self.home / ".config/mise/config.toml"
        config.parent.mkdir(parents=True)
        original = ('[tools]\nnode = "22.9.0"\npython = ["3.12.9", "3.11.9"]\n'
                    '"npm:example" = { version = "1.2.3", exe = "example" }\n'
                    '[settings]\nexperimental = false\n')
        config.write_text(original)
        expected = tomllib.loads(original)["tools"]
        result = self.run_command(self.installer + ["--defaults"])
        self.assertIn("initial source: existing global config", result.stdout)
        self.assertEqual(self.saved_tools(), expected)
        self.assertEqual(self.rendered_tools(), expected)
        backup = next((self.home / "dotfleet-backups").iterdir())
        self.assertEqual((backup / "home/.config/mise/config.toml").read_text(), original)
        self.run_command(["chezmoi", "apply"])
        self.run_command(self.installer + ["--defaults"])
        self.assertEqual(self.saved_tools(), expected)
        self.assertEqual(self.rendered_tools(), expected)
        # Machine data wins over old output, even when changing or clearing pins.
        data_file = self.home / ".config/chezmoi/chezmoi.toml"
        data_file.write_text(data_file.read_text().replace('node = "22.9.0"', 'node = "22.10.0"'))
        self.run_command(self.installer + ["--defaults"])
        self.assertEqual(self.rendered_tools()["node"], "22.10.0")
        data_file.write_text('sourceDir = "' + str(self.source) + '"\numask = 0o077\n'
                             '[data]\ndomain = "core"\n[data.miseTools]\n')
        self.run_command(self.installer + ["--defaults"])
        self.assertEqual(self.saved_tools(), {})
        self.assertEqual(self.rendered_tools(), {})
        self.assertEqual(self.run_command(["chezmoi", "status"]).stdout, "")

    def test_installed_defaults_resolve_node_and_global_executable_at_home(self):
        self.installed_tool("node", "22.9.0", ["node", "codex"])
        latest = self.installed_tool("node", "22.10.0", ["node", "codex"])
        self.installed_tool("python", "3.12.9", ["python"])
        self.installed_tool("python", "3.12.10", ["python"])
        # An existing settings-only file must still allow installed defaults.
        config = self.home / ".config/mise/config.toml"
        config.parent.mkdir(parents=True)
        config.write_text('[settings]\nexperimental = false\n')
        result = self.run_command(self.installer + ["--defaults"])
        expected = {"node": "22.10.0", "python": "3.12.10"}
        self.assertEqual(self.saved_tools(), expected)
        self.assertEqual(self.rendered_tools(), expected)
        summary = result.stdout.split("END SUMMARY", 1)[1]
        self.assertIn('Mise global pins: {"node":"22.10.0","python":"3.12.10"}', summary)
        self.assertIn("defaults from installed Node/Python; no downloads", summary)
        # Isolate PATH from the invoking user's installed Node and npm globals.
        mise_link = self.home / ".local/bin/mise"
        mise_link.symlink_to(shutil.which("mise"))
        env = {"HOME": str(self.home), "PATH": "/usr/local/bin:/usr/bin:/bin", "TERM": "dumb"}
        for shell in ("bash", "zsh"):
            with self.subTest(shell=shell):
                result = subprocess.run(
                    [shell, "-eic", 'cd "$HOME"; command -v node; command -v codex; node; codex'],
                    cwd=self.home, env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(result.stdout.splitlines(),
                                 [str(latest / "node"), str(latest / "codex"), "node-22.10.0", "codex-22.10.0"])
        # Newly installed versions must not silently replace saved defaults.
        self.installed_tool("node", "24.0.0", ["node", "codex"])
        self.run_command(self.installer + ["--defaults"])
        self.run_command(["chezmoi", "apply"])
        self.assertEqual(self.saved_tools(), expected)
        self.assertEqual(self.rendered_tools(), expected)

    def test_no_installed_tools_records_empty_defaults(self):
        result = self.run_command(self.installer + ["--defaults"])
        self.assertEqual(self.saved_tools(), {})
        self.assertEqual(self.rendered_tools(), {})
        self.assertIn("Mise global pins: none (initial source: defaults from installed Node/Python; no downloads)", result.stdout)

    def test_invalid_existing_mise_config_stops_before_apply(self):
        config = self.home / ".config/mise/config.toml"
        config.parent.mkdir(parents=True)
        original = '[tools]\nnode = [broken TOML\n'
        config.write_text(original)
        result = self.run_command(self.installer + ["--defaults"], expected=1)
        self.assertIn("fromToml", result.stderr)
        self.assertEqual(config.read_text(), original)
        self.assertFalse((self.home / ".zshrc").exists())

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
        self.assertIn("already exists and is not this repository\'s clone", result.stderr)
        self.assertEqual(self.snapshot(), before)

    def run_conflict_terminal(self, answers, expected=0):
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
        # The installer must read decisions from the terminal, never this pipe.
        process.stdin.write(b"all-overwrite\n")
        process.stdin.close()
        transcript = b""
        answered = 0
        cursor = 0
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
            elif process.poll() is not None:
                break
            prompt = transcript.find(b"Choose [d/o/a/s/S/q]:", cursor)
            if prompt >= 0 and answered < len(answers):
                self.assertIn(b"Type one letter, then press Enter.", transcript[cursor:])
                os.write(master, answers[answered])
                cursor = len(transcript)
                answered += 1
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGKILL)
        process.wait(timeout=5)
        output = transcript.decode(errors="replace")
        self.assertEqual(process.returncode, expected, output)
        self.assertEqual(answered, len(answers), output)
        self.assertNotIn("diff/overwrite/all-overwrite/skip/Skip-conflicts/quit", output)
        return output

    def test_managed_mise_conflict_explains_keys_diff_then_overwrite(self):
        # Match the reported upgrade: chezmoi wrote the file, then mise changed it.
        # The old machine data has no saved tool table yet.
        self.seed_legacy_install()
        config = self.home / ".config/mise/config.toml"
        original = '# Local pin\n[tools]\nnode = "latest"\n[settings]\nexperimental = false\n'
        config.write_text(original)
        output = self.run_conflict_terminal([b"x\n", b"d\n", b"o\n"])
        self.assertEqual(output.count("Choose [d/o/a/s/S/q]:"), 3)
        self.assertIn("diff --git", output)
        for explanation in (
                "d  Show changes for this file, then ask again.",
                "o  Overwrite this file with the generated version.",
                "a  Overwrite this file and all remaining conflicts without asking again.",
                "s  Keep this file unchanged; continue with other files.",
                "S  Keep all conflicting files unchanged; apply other changes.",
                "q  Stop applying. Changes already made remain in place."):
            self.assertIn(explanation, output)
        self.assertEqual(self.saved_tools(), {"node": "latest"})
        self.assertEqual(self.rendered_tools(), {"node": "latest"})
        self.assertEqual(self.run_command(["chezmoi", "status"]).stdout, "")
        self.assertIn("Result: SUCCESS", output)
        backup = next((self.home / "dotfleet-backups").iterdir())
        self.assertEqual((backup / "home/.config/mise/config.toml").read_text(), original)

    def test_conflict_skip_all_and_quit_preserve_edits(self):
        self.run_command(self.installer + ["--defaults"])
        paths = [self.home / ".aliases", self.home / ".bashrc"]
        for path in paths:
            path.write_text(path.read_text() + "\n# Keep this local edit\n")
        contents = [path.read_bytes() for path in paths]
        for answer in (b"S\n", b"q\n"):
            with self.subTest(answer=answer):
                output = self.run_conflict_terminal([answer], expected=1)
                self.assertIn("chezmoi status: DRIFT", output)
                self.assertEqual([path.read_bytes() for path in paths], contents)
        # Lowercase s skips one file; the next conflict still needs a decision.
        self.run_conflict_terminal([b"s\n", b"o\n"], expected=1)
        self.assertEqual(paths[0].read_bytes(), contents[0])
        self.assertNotEqual(paths[1].read_bytes(), contents[1])
        # all-overwrite belongs to chezmoi; one answer must handle both conflicts.
        paths[1].write_bytes(contents[1])
        output = self.run_conflict_terminal([b"a\n"])
        self.assertEqual(output.count("Choose [d/o/a/s/S/q]:"), 1)
        self.assertEqual(self.run_command(["chezmoi", "status"]).stdout, "")

    def test_unattended_conflict_stops_without_consuming_pipe_or_overwriting(self):
        self.run_command(self.installer + ["--defaults"])
        path = self.home / ".aliases"
        path.write_text(path.read_text() + "\n# Preserve this edit\n")
        before = path.read_bytes()
        result = self.run_command(self.installer + ["--defaults"], expected=1, input="all-overwrite\n")
        self.assertIn("Apply stopped. Review changes in a terminal", result.stderr)
        self.assertEqual(path.read_bytes(), before)

    def run_on_terminal(self, responses):
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
                if not responses and b"Domain (core: shared; personal: shared+personal; work: shared+employer; client: shared+client)" in transcript:
                    break  # An update must not ask for the profile again.
            elif process.poll() is not None:
                break
            if answered < len(responses):
                prompt = transcript.rfind(responses[answered][0])
                # The question is printed before the editor enters raw mode.
                # Sending Enter then races ICRNL and turns it into a newline
                # the editor ignores. Wait for both the rendered input field
                # and raw terminal state, not an arbitrary sleep.
                ready_for_input = (prompt >= 0 and b"> " in transcript[prompt:]
                                   and not termios.tcgetattr(master)[3] & termios.ICANON)
                if ready_for_input:
                    os.write(master, responses[answered][1])
                    answered += 1
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGKILL)
        process.wait(timeout=5)
        self.assertEqual(process.returncode, 0, transcript.decode(errors="replace"))
        self.assertEqual(answered, len(responses), transcript.decode(errors="replace"))

    def test_first_run_prompts_on_terminal_and_reuses_personal_identity(self):
        responses = [(b"Domain (core: shared; personal: shared+personal; work: shared+employer; client: shared+client)", b"personal\r"),
                     (b"Git name (commit author; blank=unset)", b"Fixture Person\r"),
                     (b"Git email (commit author email; blank=unset)", b"fixture@example.invalid\r")]
        self.run_on_terminal(responses)
        config = (self.home / ".config/chezmoi/chezmoi.toml").read_text()
        self.assertIn('domain = "personal"', config)
        identity = ["git", "config", "--file", str(self.home / ".gitconfig")]
        self.assertEqual(self.run_command(identity + ["user.name"]).stdout.strip(), "Fixture Person")
        self.assertEqual(self.run_command(identity + ["user.email"]).stdout.strip(), "fixture@example.invalid")
        # Both terminal and unattended updates must reuse the saved profile.
        self.run_on_terminal([])
        self.assertEqual((self.home / ".config/chezmoi/chezmoi.toml").read_text(), config)
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
