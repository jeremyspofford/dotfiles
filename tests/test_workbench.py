"""Integration tests use real chezmoi and isolated destination/state directories."""
import importlib.machinery
import importlib.util
import contextlib
import io
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
from unittest.mock import patch

CLI = Path(__file__).resolve().parents[1] / "bin/workbench"
loader = importlib.machinery.SourceFileLoader("workbench", str(CLI))
spec = importlib.util.spec_from_loader(loader.name, loader)
wb = importlib.util.module_from_spec(spec)
loader.exec_module(wb)


class WorkbenchTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="workbench-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.home = self.root / "home"
        self.home.mkdir()
        self.state = self.root / "state"

    def run_cli(self, *args, ok=True):
        result = subprocess.run([str(CLI), "--destination", str(self.home),
                                 "--state-dir", str(self.state), *args],
                                text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def token(self, *args):
        return re.search(r"Plan: ([a-f0-9]{64})", self.run_cli(*args).stdout)[1]

    def apply(self, *options):
        token = self.token("plan", *options)
        return self.run_cli("apply", *options, "--plan", token)

    def last_checkpoint(self):
        paths = sorted((self.state / "checkpoints").glob("*/checkpoint.json"))
        self.assertTrue(paths)
        return json.loads(paths[-1].read_text())

    def undo(self, ident):
        token = self.token("rollback", ident)
        self.run_cli("rollback", ident, "--plan", token)

    def test_doctor_matches_applied_configuration(self):
        self.apply()
        result = self.run_cli("doctor")
        self.assertIn("Configuration: all managed files match.", result.stdout)

    def test_doctor_reports_drift_without_changing_files_or_checkpoints(self):
        self.apply()
        herdr = self.home / ".config/herdr/config.toml"
        herdr.write_text(herdr.read_text() + "\n# private local preference\n")
        (self.home / ".zshrc").unlink()
        (self.home / ".tmux.conf").chmod(0o600)
        profile = self.home / ".profile"
        original = self.root / "original-profile"
        profile.rename(original)
        profile.symlink_to(original)
        before = {name: wb.file_state(self.home / name) for name in wb.ALLOWED}
        checkpoint_files = {p.relative_to(self.state): p.read_bytes()
                            for p in self.state.rglob("*") if p.is_file()}
        result = self.run_cli("doctor", ok=False)
        self.assertEqual(result.returncode, 1)
        self.assertRegex(result.stdout, r"DRIFT\s+\.config/herdr/config.toml")
        self.assertRegex(result.stdout, r"MISSING\s+\.zshrc")
        self.assertRegex(result.stdout, r"DRIFT\s+\.tmux.conf")
        self.assertRegex(result.stdout, r"DRIFT\s+\.profile")
        self.assertIn("4 managed file(s) need attention", result.stdout)
        self.assertIn("workbench plan --existing replace", result.stdout)
        self.assertNotIn("private local preference", result.stdout + result.stderr)
        self.assertEqual(before, {name: wb.file_state(self.home / name) for name in wb.ALLOWED})
        self.assertEqual(checkpoint_files, {p.relative_to(self.state): p.read_bytes()
                                           for p in self.state.rglob("*") if p.is_file()})

    def test_doctor_missing_tool_fails_even_when_configuration_matches(self):
        self.apply()
        real_which = wb.shutil.which
        output = io.StringIO()
        with patch.object(wb.shutil, "which", side_effect=lambda name: None if name == "herdr" else real_which(name)), contextlib.redirect_stdout(output):
            self.assertEqual(wb.doctor(self.home, self.state), 1)
        self.assertIn("herdr: not installed", output.getvalue())
        self.assertIn("Configuration: all managed files match.", output.getvalue())

    def test_doctor_without_chezmoi_reports_unchecked_configuration(self):
        output = io.StringIO()
        with patch.object(wb.shutil, "which", return_value=None), patch.object(wb, "render") as render, contextlib.redirect_stdout(output):
            self.assertEqual(wb.doctor(self.home, self.state), 1)
        render.assert_not_called()
        self.assertIn("Configuration: unable to check without chezmoi.", output.getvalue())
        self.assertFalse(self.state.exists())

    def test_doctor_refuses_redirected_parent(self):
        outside = self.root / "outside"
        outside.mkdir()
        (self.home / ".config").symlink_to(outside)
        result = self.run_cli("doctor", ok=False)
        self.assertIn("Refusing redirected parent", result.stderr)
        self.assertEqual(list(outside.iterdir()), [])
        self.assertFalse(self.state.exists())

    def test_fresh_apply_idempotence_rollback_preserves_unrelated(self):
        workspace = self.home / "workspace/client"
        workspace.mkdir(parents=True)
        (workspace / "important").write_text("keep me")
        result = self.apply()
        entry = self.last_checkpoint()
        self.assertIn("Applied and verified", result.stdout)
        self.assertEqual((self.home / ".tmux.conf").stat().st_mode & 0o777, 0o644)
        self.assertIn("No changes", self.apply().stdout)
        self.undo(entry["id"])
        self.assertFalse((self.home / ".tmux.conf").exists())
        self.assertFalse((self.home / ".config").exists())
        self.assertEqual((workspace / "important").read_text(), "keep me")

    def test_existing_files_skipped_by_default(self):
        (self.home / ".tmux.conf").write_text("my config\n")
        result = self.apply("--components", "tmux")
        self.assertIn("SKIP existing", result.stdout)
        self.assertEqual((self.home / ".tmux.conf").read_text(), "my config\n")
        self.assertFalse((self.state / "checkpoints").exists())

    def test_replace_restores_contents_and_permissions(self):
        path = self.home / ".tmux.conf"
        path.write_text("personal config\n")
        path.chmod(0o600)
        self.apply("--components", "tmux", "--existing", "replace")
        entry = self.last_checkpoint()
        self.assertEqual((self.state / "checkpoints" / entry["id"] / "checkpoint.json").stat().st_mode & 0o777, 0o600)
        self.undo(entry["id"])
        self.assertEqual(path.read_text(), "personal config\n")
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_stow_symlink_target_never_modified(self):
        source = self.root / "stow-source"
        source.write_text("original source\n")
        target = self.home / ".tmux.conf"
        target.symlink_to("../stow-source")
        self.apply("--components", "tmux", "--existing", "replace")
        self.assertFalse(target.is_symlink())
        self.assertEqual(source.read_text(), "original source\n")
        self.undo(self.last_checkpoint()["id"])
        self.assertTrue(target.is_symlink())
        self.assertEqual(os.readlink(target), "../stow-source")

    def test_stale_plan_rejected_before_checkpoint(self):
        token = self.token("plan", "--components", "tmux")
        (self.home / ".tmux.conf").write_text("concurrent change\n")
        result = self.run_cli("apply", "--components", "tmux", "--plan", token, ok=False)
        self.assertIn("stale", result.stderr)
        self.assertFalse((self.state / "checkpoints").exists())

    def test_wrong_options_invalidate_plan(self):
        token = self.token("plan", "--components", "tmux")
        self.run_cli("apply", "--components", "herdr", "--plan", token, ok=False)
        self.assertFalse((self.home / ".config").exists())

    def test_symlink_parent_rejected(self):
        outside = self.root / "outside"
        outside.mkdir()
        (self.home / ".config").symlink_to(outside)
        self.run_cli("plan", "--components", "herdr", ok=False)
        self.assertEqual(list(outside.iterdir()), [])

    def test_rollback_preserves_post_apply_edits(self):
        self.apply("--components", "tmux")
        ident = self.last_checkpoint()["id"]
        path = self.home / ".tmux.conf"
        path.write_text("new work after applying\n")
        self.run_cli("rollback", ident, ok=False)
        self.assertEqual(path.read_text(), "new work after applying\n")

    def test_rollback_refuses_modified_symlink_source(self):
        source = self.root / "original"
        source.write_text("before")
        (self.home / ".tmux.conf").symlink_to(source)
        self.apply("--components", "tmux", "--existing", "replace")
        source.write_text("later edit")
        self.run_cli("rollback", self.last_checkpoint()["id"], ok=False)
        self.assertEqual(source.read_text(), "later edit")

    def test_rollback_keeps_new_unrelated_files_in_created_directory(self):
        self.apply("--components", "herdr")
        ident = self.last_checkpoint()["id"]
        extra = self.home / ".config/herdr/new-user-file"
        extra.write_text("keep")
        self.undo(ident)
        self.assertEqual(extra.read_text(), "keep")
        self.assertFalse((extra.parent / "config.toml").exists())

    def test_injected_apply_failure_restores_all_files(self):
        plan = wb.make_plan(self.home, sorted(wb.ALLOWED), "replace")
        real_install = wb.install_state
        calls = 0

        def fail_once(path, state):
            nonlocal calls
            calls += 1
            if calls == 3:
                raise OSError("injected disk failure")
            return real_install(path, state)

        argv = [str(CLI), "--destination", str(self.home), "--state-dir", str(self.state),
                "apply", "--existing", "replace", "--plan", wb.digest(plan)]
        with patch("sys.argv", argv), patch.object(wb, "install_state", fail_once), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(OSError, "injected"):
                wb.main()
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertEqual(self.last_checkpoint()["status"], "failed-restored")

    def test_checkpoint_path_traversal_refused(self):
        self.run_cli("rollback", "../escape", ok=False)

    def test_manual_checkpoint_restore_requires_explicit_edit_replacement(self):
        path = self.home / ".tmux.conf"
        path.write_text("saved")
        self.run_cli("checkpoint", "--components", "tmux")
        ident = self.last_checkpoint()["id"]
        path.write_text("later edit")
        self.run_cli("rollback", ident, ok=False)
        token = self.token("rollback", ident, "--replace-edits")
        self.run_cli("rollback", ident, "--replace-edits", "--plan", token)
        self.assertEqual(path.read_text(), "saved")
        snapshots = [json.loads(p.read_text()) for p in (self.state / "checkpoints").glob("*/checkpoint.json")]
        recovery = next(s for s in snapshots if s["label"] == "before-rollback")
        self.undo(recovery["id"])
        self.assertEqual(path.read_text(), "later edit")


if __name__ == "__main__":
    unittest.main()
