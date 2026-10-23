"""Interactive apply: selection logic, the checklist with scripted keys, and a full run."""
import contextlib
import curses
import importlib.machinery
import importlib.util
import io
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

CLI = Path(__file__).resolve().parents[1] / "bin/workbench"
loader = importlib.machinery.SourceFileLoader("workbench_interactive", str(CLI))
spec = importlib.util.spec_from_loader(loader.name, loader)
wb = importlib.util.module_from_spec(spec)
loader.exec_module(wb)

ROWS = [
    {"component": None, "tool": "node", "pinned": "24.14.1", "latest": "26.12.1"},
    {"component": None, "tool": "jq", "pinned": "1.8.1", "latest": None},
    {"component": "herdr", "tool": "herdr", "pinned": "0.9.5", "latest": "0.9.6"},
    {"component": "zoetrope", "tool": "github:furkankly/zoetrope", "pinned": "0.2.0", "latest": None},
]


class FakeScreen:
    """Just enough of a curses window to drive checklist() with scripted keys."""

    def __init__(self, keys, size=(30, 100)):
        self.keys, self.size, self.frames = list(keys), size, []

    def getmaxyx(self):
        return self.size

    def erase(self):
        self.frames.append([])

    def addnstr(self, row, col, text, limit, attr=0):
        self.frames[-1].append(text[:limit])

    def refresh(self):
        pass

    def getch(self):
        return self.keys.pop(0)


class PinTests(unittest.TestCase):
    TEXT = '# tools\n[tools]\nnode = "24.14.1"\n"github:o/r" = "0.2.0"\n\n[settings]\nnode = "x"\n'

    def test_read_pins_only_reads_tools_section(self):
        path = Path(tempfile.mkdtemp()) / "config.toml"
        path.write_text(self.TEXT)
        self.assertEqual(wb.read_pins(path), {"node": "24.14.1", "github:o/r": "0.2.0"})

    def test_set_pin_changes_exactly_one_line(self):
        updated = wb.set_pin(self.TEXT, "github:o/r", "0.2.0", "0.3.0")
        self.assertIn('"github:o/r" = "0.3.0"', updated)
        self.assertEqual(updated.replace("0.3.0", "0.2.0"), self.TEXT)
        with self.assertRaisesRegex(ValueError, "found 0"):
            wb.set_pin(self.TEXT, "node", "1.0.0", "2.0.0")

    def test_inventory_marks_only_newer_releases(self):
        rows = wb.inventory({"node": {"bump": "99.0.0"}, "jq": {"bump": "1.8.1"}})
        by_tool = {r["tool"]: r for r in rows}
        self.assertEqual(by_tool["node"]["latest"], "99.0.0")
        self.assertIsNone(by_tool["jq"]["latest"])
        self.assertEqual(by_tool["herdr"]["component"], "herdr")


class SelectionTests(unittest.TestCase):
    def test_changes_add_remove_and_ignore_bumps_on_removed_components(self):
        changes = wb.selection_changes(["herdr"], {"herdr": False, "zoetrope": True},
                                       {"node", "herdr"}, ROWS)
        self.assertEqual(changes["add"], ["zoetrope"])
        self.assertEqual(changes["remove"], ["herdr"])
        self.assertEqual([r["tool"] for r in changes["bumps"]], ["node"])
        self.assertEqual(changes["touched"], ["mise", "zoetrope"])

    def test_checklist_keys_choose_component_and_mark_update(self):
        # Selectable rows: node (update), herdr (component), herdr tool (update), zoetrope.
        keys = [ord(" "), curses.KEY_DOWN, ord(" "), ord("j"), ord("j"), ord(" "), 10]
        screen = FakeScreen(keys)
        with patch.object(curses, "curs_set"):
            result = wb.checklist(screen, ROWS, {"herdr": False, "zoetrope": False}, "footer")
        self.assertEqual(result, ({"herdr": True, "zoetrope": True}, {"node"}))
        self.assertTrue(any("[u] node" in line for line in screen.frames[-1]))
        self.assertTrue(any("footer" in line for line in screen.frames[-1]))

    def test_checklist_cancel_and_tiny_terminal(self):
        with patch.object(curses, "curs_set"):
            self.assertIsNone(wb.checklist(FakeScreen([ord("q")], size=(3, 10)), ROWS,
                                           {"herdr": True, "zoetrope": False}, ""))


class InteractiveRunTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory(prefix="workbench-interactive-")
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name).resolve()
        self.home = self.root / "home"
        self.home.mkdir()
        self.state = self.root / "state"
        # A private copy of the source so pin bumps never touch the real repository.
        self.repo = self.root / "repo"
        shutil.copytree(wb.REPO / "chezmoi", self.repo / "chezmoi")
        for name, value in (("REPO", self.repo), ("MISE_SOURCE", self.repo / "chezmoi/dot_config/mise")):
            patcher = patch.object(wb, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def test_choose_then_remove_component_with_rollback(self):
        pin = self.home / ".config/mise/conf.d/zoetrope.toml"
        out, calls = self.run_interactive_without_mise(({"herdr": False, "zoetrope": True}, set()), "y")
        self.assertIn("CREATE         .config/mise/conf.d/zoetrope.toml", out)
        self.assertTrue(pin.is_file())
        self.assertEqual(wb.chosen(self.home), ["zoetrope"])
        self.assertIn(["mise", "install"], calls)
        out, calls = self.run_interactive_without_mise(({"herdr": False, "zoetrope": False}, set()), "y")
        self.assertIn("REMOVE         .config/mise/conf.d/zoetrope.toml", out)
        self.assertFalse(pin.exists())
        self.assertIn(["mise", "uninstall", "github:furkankly/zoetrope@0.2.0"], calls)
        checkpoint = wb.json.loads(sorted((self.state / "checkpoints").glob("*/checkpoint.json"))[-1].read_text())
        wb.restore(self.home, checkpoint)
        self.assertTrue(pin.is_file())

    def test_declining_review_restores_bumped_pin_and_home(self):
        source = self.repo / "chezmoi/dot_config/mise/config.toml"
        original = source.read_text()
        out, calls = self.run_interactive_without_mise(
            ({"herdr": False, "zoetrope": False}, {"node"}), "n",
            outdated={"node": {"bump": "99.0.0"}})
        self.assertIn('+node = "99.0.0"', out)
        self.assertIn("Cancelled; nothing changed.", out)
        self.assertEqual(source.read_text(), original)
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertEqual(calls, [])

    def test_confirmed_bump_updates_repository_pin_and_home(self):
        self.run_interactive_without_mise(({"herdr": False, "zoetrope": False}, set()), "y")
        out, calls = self.run_interactive_without_mise(
            ({"herdr": False, "zoetrope": False}, {"node"}), "y",
            outdated={"node": {"bump": "99.0.0"}})
        self.assertIn('node = "99.0.0"', (self.repo / "chezmoi/dot_config/mise/config.toml").read_text())
        self.assertIn('node = "99.0.0"', (self.home / ".config/mise/config.toml").read_text())
        self.assertIn("Pins changed in the repository", out)
        self.assertIn(["mise", "install"], calls)

    def run_interactive_without_mise(self, picked, answer, outdated=None):
        real_run = wb.subprocess.run
        calls = []

        def fake_run(command, *args, **kwargs):
            if command[:1] == ["mise"]:
                calls.append(command)
                return wb.subprocess.CompletedProcess(command, 0, "", "")
            return real_run(command, *args, **kwargs)

        output = io.StringIO()
        with patch.object(wb, "fetch_outdated", return_value=outdated or {}), \
                patch.object(wb, "missing_packages", return_value=[]), \
                patch.object(wb, "has_terminal", return_value=True), \
                patch.object(curses, "wrapper", return_value=picked), \
                patch("builtins.input", return_value=answer), \
                patch.object(wb.subprocess, "run", side_effect=fake_run), \
                contextlib.redirect_stdout(output):
            wb.interactive_apply(self.state, self.home, "never")
        return output.getvalue(), calls

    def test_interactive_requires_terminal_and_excludes_plan(self):
        with self.assertRaisesRegex(ValueError, "needs a terminal"):
            with patch.object(wb, "has_terminal", return_value=False):
                wb.interactive_apply(self.state, self.home, "never")
        result = wb.subprocess.run([str(CLI), "--destination", str(self.home), "--state-dir", str(self.state),
                                    "apply", "--interactive", "--plan", "x"], capture_output=True, text=True)
        self.assertIn("omit --plan and --components", result.stderr)
        result = wb.subprocess.run([str(CLI), "--destination", str(self.home), "--state-dir", str(self.state),
                                    "apply"], capture_output=True, text=True)
        self.assertIn("or --interactive", result.stderr)
