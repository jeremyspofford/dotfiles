"""Check the single optional fleet alias in both supported shells."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]


class HelpersTests(unittest.TestCase):
    def test_one_default_on_guarded_alias(self):
        manifest = tomllib.loads((ROOT / 'dotfleet.toml').read_text())
        self.assertTrue(manifest['groups']['helpers']['default'])
        text = (ROOT / '.config/dotfiles/aliases/core.zsh').read_text()
        block = text.split('# dotfleet:group helpers begin\n', 1)[1].split('# dotfleet:group helpers end', 1)[0]
        self.assertEqual(re.findall(r'^\s*alias\s+(\w+)=', block, re.M), ['fleet'])
        self.assertIn('command -v dotfleet', block)

    def test_fleet_status_requires_manager_and_keeps_df(self):
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as folder:
                bin_dir = Path(folder)
                options = ['/bin/bash', '-O', 'expand_aliases'] if shell == 'bash' else ['/bin/zsh']
                script = 'source "$1"; alias fleet 2>/dev/null || true; alias df dtf dtfu dtfs dtfd fleetu 2>/dev/null || true'
                env = dict(os.environ, PATH=folder, HOME=folder, ZDOTDIR=folder, XDG_CONFIG_HOME=folder)
                result = subprocess.run([*options, '-c', script, 'helpers', str(ROOT / '.config/dotfiles/aliases/core.zsh')],
                                        env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout, '')
                self.assertEqual(result.stderr, '')
                exe = bin_dir / 'dotfleet'
                exe.write_text('#!/bin/sh\nprintf "command:%s\\n" "$1"\n')
                exe.chmod(0o700)
                result = subprocess.run([*options, '-c', script + '; eval "fleet status"', 'helpers',
                                         str(ROOT / '.config/dotfiles/aliases/core.zsh')], env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stderr, '')
                self.assertIn('command:status', result.stdout)
                self.assertIn('fleet=', result.stdout)
                for forbidden in ['df', 'dtf', 'dtfu', 'dtfs', 'dtfd', 'fleetu']:
                    self.assertNotRegex(result.stdout, rf'(?m)^(?:alias )?{forbidden}=')
