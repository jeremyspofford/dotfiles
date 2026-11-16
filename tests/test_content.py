"""Check the plain content contract without applying to the real home."""
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest
ROOT = Path(__file__).resolve().parents[1]


class ContentTests(unittest.TestCase):
    def test_plain_layout(self):
        names = subprocess.check_output(['git', 'ls-files'], cwd=ROOT, text=True).splitlines()
        self.assertFalse(any(n.startswith(('dot_', 'private_dot_', '.chezmoi')) or n.endswith('.tmpl') for n in names))
        for name in ['install.sh', 'scripts/bootstrap.sh', 'release-please-config.json', 'agents/manifest.toml']:
            self.assertNotIn(name, names)
        manifest = tomllib.loads((ROOT / 'dotfleet.toml').read_text())
        self.assertEqual(manifest['format'], 'plain')
        self.assertEqual(set(manifest['groups']), {'docker', 'terraform', 'kubectl', 'python', 'npm'})

    def test_git_and_secret_rules(self):
        text = (ROOT / '.gitconfig').read_text()
        self.assertNotIn('[user]', text)
        self.assertNotIn('{{', text)
        self.assertIn('ff = only', text)
        aliases = subprocess.check_output(['git', 'config', '--file', str(ROOT / '.gitconfig'), '--get-regexp', '^alias[.]'], text=True)
        self.assertEqual({line.split()[0] for line in aliases.splitlines()}, {'alias.unstage', 'alias.last', 'alias.lg', 'alias.branches', 'alias.remotes', 'alias.stashes'})
        self.assertTrue(all(not line.strip() or line.lstrip().startswith('#') for line in (ROOT / '.secrets.example').read_text().splitlines()))
        self.assertNotIn('alias weather=', (ROOT / '.config/dotfiles/aliases/core.zsh').read_text())
        self.assertNotIn('alias myip=', (ROOT / '.config/dotfiles/aliases/core.zsh').read_text())

    def test_runtime_and_shell_syntax(self):
        for shell, files in [('bash', ['.bashrc', '.bash_profile', '.commonrc', '.aliases']), ('zsh', ['.zshrc', '.zprofile', '.zshenv'])]:
            for name in files:
                subprocess.run([shell, '-n', str(ROOT / name)], check=True)
        for name in (ROOT / '.config/dotfiles').rglob('*.zsh'):
            subprocess.run(['bash', '-n', str(name)], check=True)


if __name__ == '__main__':
    unittest.main()
