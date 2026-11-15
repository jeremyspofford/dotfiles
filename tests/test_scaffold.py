"""Portable integration tests; never apply configuration to the invoking user's home."""
import importlib.util
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
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
                self.assertIn(".gitconfig", subprocess.check_output(command + ["managed"], text=True).splitlines())
                self.assertTrue((home / ".gitconfig").is_file())
                self.assertEqual(subprocess.check_output(
                    ["git", "config", "--file", str(home / ".gitconfig"), "--get", "init.defaultBranch"],
                    text=True).strip(), "main")
                for metadata in (".git", ".gitignore", ".github"):
                    self.assertFalse((home / metadata).exists())
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

    @unittest.skipUnless(shutil.which("chezmoi") and shutil.which("mise"), "chezmoi/mise required")
    def test_bootstrap_modes_and_managed_idempotence_across_umasks(self):
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            seed = temporary / "repo"
            seed.mkdir()
            # Commit a snapshot of the working sources, so local edits and CI use
            # the same fixture without fetching GitHub or installing tools.
            tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
            for relative in filter(None, tracked):
                target = seed / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / relative, target)
            git_env = {"PATH": os.environ["PATH"], "HOME": str(temporary),
                       "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull}
            for arguments in (["init", "--quiet"], ["add", "."],
                              ["-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                               "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "test: seed bootstrap fixture"]):
                subprocess.run(["git", "-C", str(seed)] + arguments, env=git_env, check=True, capture_output=True)

            snapshots = []
            for mask in (0o077, 0o022):
                with self.subTest(umask=oct(mask)):
                    home = temporary / ("home-" + str(mask))
                    home.mkdir()
                    env = {**git_env, "HOME": str(home), "TMPDIR": str(temporary),
                           "XDG_CONFIG_HOME": str(home / ".config"),
                           "XDG_DATA_HOME": str(home / ".local/share"),
                           "XDG_STATE_HOME": str(home / ".local/state"),
                           "XDG_CACHE_HOME": str(home / ".cache")}
                    source = home / ".local/share/chezmoi"
                    bootstrap = ["bash", str(seed / "scripts/bootstrap.sh"), "--repo", str(seed), "--source", str(source)]
                    chezmoi = ["chezmoi", "--source", str(source)]

                    def run(command, umask):
                        result = subprocess.run(command, env=env, cwd=temporary, umask=umask, capture_output=True, text=True)
                        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                        return result.stdout

                    def managed_snapshot():
                        # Tool-owned state/mtime is deliberately outside the
                        # idempotence contract: compare managed bytes and modes.
                        snapshot = {}
                        for relative in run(chezmoi + ["managed"], 0o022).splitlines():
                            target = home / relative
                            mode = stat.S_IMODE(target.lstat().st_mode)
                            if target.is_symlink():
                                content = os.readlink(target)
                            elif target.is_file():
                                content = hashlib.sha256(target.read_bytes()).hexdigest()
                            else:
                                content = None
                            snapshot[relative] = (mode, content)
                        return snapshot

                    run(bootstrap + ["--dry-run"], mask)
                    self.assertFalse((home / ".zshrc").exists())
                    run(bootstrap, mask)
                    self.assertEqual(run(chezmoi + ["status"], 0o022), "")
                    self.assertEqual(run(chezmoi + ["diff"], 0o022), "")
                    before = managed_snapshot()
                    self.assertEqual(before[".secrets"][0], 0o600)
                    for relative, (mode, _) in before.items():
                        if relative != ".secrets":
                            self.assertEqual(mode, 0o700 if (home / relative).is_dir() else 0o600, relative)
                    # Changing ambient umask must not change the managed state.
                    run(bootstrap, 0o022 if mask == 0o077 else 0o077)
                    self.assertEqual(managed_snapshot(), before)
                    self.assertEqual(run(chezmoi + ["status"], 0o077), "")
                    self.assertEqual(run(chezmoi + ["status"], 0o022), "")
                    snapshots.append(before)
            self.assertEqual(len(snapshots), 2)
            self.assertEqual(snapshots[0], snapshots[1])

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

    def test_restored_gitignore_protections(self):
        paths = [
            "token.secret", "shell.local", "cert.pem", "private.key",
            "id_rsa", "id_rsa.pub", "id_ed25519", "id_ed25519.pub",
            ".vscode/settings.json", ".claude/settings.json", "draft~",
            "edit.swp", "edit.swo", "__pycache__/module.pyc",
            "module.pyc", "module.pyo", "module.pyd", ".venv/bin/python",
            "venv/bin/python", ".worktrees/topic/file", ".herdr-web-ui/paste",
            ".secrets", "nested/.secrets", ".env", ".env.production",
        ]
        for path in paths:
            with self.subTest(path=path):
                result = subprocess.run(["git", "check-ignore", "--no-index", path], cwd=ROOT, capture_output=True)
                self.assertEqual(result.returncode, 0, path)
        for path in (".env.example", "nested/.env.example", ".chezmoitemplates/dot_secrets.tmpl"):
            result = subprocess.run(["git", "check-ignore", "--no-index", path], cwd=ROOT, capture_output=True)
            self.assertEqual(result.returncode, 1, path)

    def test_salvaged_shell_syntax(self):
        for path in ("dot_bashrc", "dot_bash_profile", "dot_commonrc", "core/aliases.zsh"):
            subprocess.run(["bash", "-n", path], cwd=ROOT, check=True)
        if shutil.which("zsh"):
            for path in ("dot_commonrc", "dot_zshrc", "core/aliases.zsh"):
                subprocess.run(["zsh", "-n", path], cwd=ROOT, check=True)

    def test_salvaged_aliases_and_sso_in_both_shells(self):
        env = {key: value for key, value in os.environ.items() if not key.startswith("AWS_")}
        script = r'''
command() {
    if [[ $1 == -v && $2 == eza ]]; then return 1; fi
    builtin command "$@"
}
aws() {
    case "$1 $2" in
    "sso login") return 0 ;;
    "configure export-credentials") printf 'export AWS_ACCESS_KEY_ID=fixture_key\nexport AWS_SESSION_TOKEN=fixture_session\n' ;;
    "sts get-caller-identity") printf 'fixture-identity\n' ;;
    *) return 99 ;;
    esac
}
export DOTFILES_PLATFORM=linux
source "$1/core/aliases.zsh"
[[ $(alias ll) == *"ls -alF"* ]] || exit 10
[[ $(alias gs) == *"git status"* ]] || exit 11
alias ls >/dev/null 2>&1 && exit 12
alias cat >/dev/null 2>&1 && exit 13
sso chosen || exit 14
[[ $AWS_PROFILE == chosen && $AWS_ACCESS_KEY_ID == fixture_key && $AWS_SESSION_TOKEN == fixture_session ]] || exit 15
unset AWS_PROFILE
sso 2>/dev/null
[[ $? == 2 ]] || exit 16
export AWS_PROFILE=previous
aws() {
    case "$1 $2" in
    "sso login") return 0 ;;
    "configure export-credentials") return 42 ;;
    *) printf 'unexpected-call\n'; return 99 ;;
    esac
}
sso chosen
[[ $? == 42 && $AWS_PROFILE == previous ]] || exit 17
'''
        for shell in ("bash", "zsh"):
            if not shutil.which(shell):
                continue
            with self.subTest(shell=shell):
                result = subprocess.run([shell, "-f", "-c", script, "test", str(ROOT)], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "fixture-identity\n")


if __name__ == "__main__":
    unittest.main()
