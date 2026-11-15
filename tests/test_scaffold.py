"""Portable integration tests; never apply configuration to the invoking user's home."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("agent_configs", ROOT / "scripts/agent_configs.py")
agents = importlib.util.module_from_spec(spec)
spec.loader.exec_module(agents)


class ScaffoldTests(unittest.TestCase):
    def test_script_help_and_unknown_flags(self):
        for script in sorted((ROOT / "scripts").glob("*.sh")):
            for flag in ("--help", "-h"):
                result = subprocess.run(["bash", str(script), flag], capture_output=True, text=True, cwd=ROOT)
                self.assertEqual(result.returncode, 0, result.stderr)
                for word in ("Usage:", "Parameters:" if script.name == "logger.sh" else "Options:" if script.name in ("bootstrap.sh", "generate-agent-configs.sh") else "Parameters:", "Example", "Exit codes:", "Version:"):
                    self.assertIn(word, result.stdout)
            result = subprocess.run(["bash", str(script), "--unknown"], capture_output=True, text=True, cwd=ROOT)
            self.assertEqual(result.returncode, 2)
            self.assertIn("Usage:", result.stderr)

    @unittest.skipUnless(shutil.which("chezmoi") and shutil.which("zsh"), "chezmoi/zsh required")
    def test_domains_secrets_shell_and_idempotence(self):
        for domain in ("core", "personal", "work", "client"):
            with tempfile.TemporaryDirectory() as directory:
                temporary = Path(directory)
                home = temporary / "home"
                home.mkdir()
                config = temporary / "chezmoi.toml"
                config.write_text(f'[data]\ndomain = "{domain}"\n')
                command = ["chezmoi", "--source", str(ROOT), "--destination", str(home),
                           "--config", str(config), "--persistent-state", str(temporary / "state.boltdb")]
                subprocess.run(command + ["apply", "--dry-run"], check=True, capture_output=True)
                subprocess.run(command + ["apply"], check=True, capture_output=True)
                secret = home / ".secrets"
                self.assertTrue(secret.exists())
                self.assertEqual(secret.stat().st_mode & 0o777, 0o600)
                self.assertNotIn("op://", secret.read_text())
                self.assertTrue((home / ".aliases").exists())
                self.assertFalse((home / "scripts").exists())
                self.assertFalse((home / "agents").exists())
                # ZDOTDIR points to an isolated startup directory without changing HOME.
                # Syntax checks plus explicit fragment sourcing exercise this test destination.
                subprocess.run(["zsh", "-n", str(home / ".zshrc")], check=True)
                command_text = 'source "$1/.aliases"; source "$1/.config/dotfiles/domain.zsh"; print -r -- "$DOTFILES_DOMAIN"'
                shell = subprocess.run(["zsh", "-f", "-c", command_text, "test", str(home)],
                                       capture_output=True, text=True, check=True)
                self.assertEqual(shell.stdout.strip(), domain)
                subprocess.run(command + ["verify"], check=True, capture_output=True)
                self.assertEqual(subprocess.check_output(command + ["diff"]), b"")

    def test_git_ignores_secrets_at_any_depth(self):
        for path in (".secrets", "nested/.secrets", ".secrets.backup"):
            result = subprocess.run(["git", "check-ignore", "--no-index", path], cwd=ROOT, capture_output=True)
            self.assertEqual(result.returncode, 0, path)
        tracked = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True).splitlines()
        self.assertFalse(any(Path(path).name == ".secrets" for path in tracked))

    def test_agent_generation_conflicts_and_inventory(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            with patch.object(shutil, "which", side_effect=lambda name: "/bin/fake" if name == "claude" else None):
                agents.generate(home, "linux", True)
                self.assertEqual(list(home.iterdir()), [])
                agents.generate(home, "linux", False)
                self.assertEqual(json.loads((home / ".claude/settings.json").read_text()), {})
                link = home / ".claude/skills/review-change"
                self.assertTrue(link.is_symlink())
                self.assertEqual(link.resolve(), ROOT / "agents/skills/review-change")
                agents.generate(home, "linux", False)
                config = home / ".claude/settings.json"
                config.write_text('{"local": true}\n')
                with self.assertRaisesRegex(ValueError, "modified config"):
                    agents.generate(home, "linux", False)
                self.assertEqual(json.loads(config.read_text()), {"local": True})

    def test_native_manifest_all_platforms(self):
        import tomllib
        manifest = tomllib.loads((ROOT / "agents/manifest.toml").read_text())
        self.assertEqual(set(manifest["agents"]), {"claude", "codex", "gemini", "grok", "pi", "opencode", "ollama"})
        for agent in manifest["agents"].values():
            self.assertEqual(set(agent["config_paths"]), {"darwin", "linux", "windows", "wsl"})
            self.assertEqual(set(agent["skills_paths"]), {"darwin", "linux", "windows", "wsl"})


if __name__ == "__main__":
    unittest.main()
