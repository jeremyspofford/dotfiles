"""Check optional Dotfleet shortcuts in both supported shells."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class HelpersTests(unittest.TestCase):
    def test_helpers_require_manager_and_keep_df(self):
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as folder:
                bin_dir = Path(folder)
                script = 'source "$1"; alias dtf dtfu dtfs dtfd; eval dtfs; alias df 2>/dev/null || true'
                env = dict(os.environ, PATH=folder)
                clean = subprocess.run(['/bin/' + shell, '-c', 'source "$1"', 'helpers', str(ROOT / '.config/dotfiles/aliases/core.zsh')], env=env, text=True, capture_output=True)
                self.assertEqual(clean.stderr, '')
                result = subprocess.run(['/bin/' + shell, '-c', script, 'helpers', str(ROOT / '.config/dotfiles/aliases/core.zsh')], env=env, text=True, capture_output=True)
                self.assertNotIn('dtfs=', result.stdout)
                self.assertNotIn('df=', result.stdout)
                exe = bin_dir / 'dotfleet'
                exe.write_text('#!/bin/sh\nprintf "command:%s\\n" "$1"\n')
                exe.chmod(0o700)
                result = subprocess.run(['/bin/' + shell, '-c', script, 'helpers', str(ROOT / '.config/dotfiles/aliases/core.zsh')], env=env, text=True, capture_output=True)
                if shell == 'bash':
                    # Bash expands aliases only when enabled outside interactive shells.
                    result = subprocess.run(['/bin/bash', '-O', 'expand_aliases', '-c', script, 'helpers', str(ROOT / '.config/dotfiles/aliases/core.zsh')], env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('command:status', result.stdout)
                self.assertNotIn('df=', result.stdout)
