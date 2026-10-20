#!/usr/bin/env python3
"""Validate the rendered baseline in isolation, or the activated VC Mac (--live)."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[1]
CLI = REPO / "bin/workbench"


def run(command, **kwargs):
    result = subprocess.run([str(x) for x in command], capture_output=True, text=True,
                            timeout=45, **kwargs)
    if result.returncode:
        raise RuntimeError(f"{command}:\n{result.stdout}\n{result.stderr}")
    return result.stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--live", action="store_true")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    actual_home = Path.home()
    with tempfile.TemporaryDirectory(prefix="wb-baseline-") as tmp:
        root = Path(tmp).resolve()
        home = actual_home if args.live else root / "home"
        home.mkdir(exist_ok=True)
        cli = [CLI, "--destination", home, "--state-dir", root / "transactions"]
        if not args.live:
            # Exercise replacement of real Stow-like symlinks, not just empty paths.
            legacy = root / "legacy"
            legacy.mkdir()
            (legacy / "zshrc").write_text("# legacy fixture\nexport WB_LEGACY=loaded\n")
            (home / ".zshrc").symlink_to(legacy / "zshrc")
            for name in (".aliases", ".commonrc", ".secrets", ".zshrc.local", ".bashrc.local"):
                (home / name).write_text("export WB_LEGACY=loaded\n")
            plan = run([*cli, "plan", "--existing", "replace"])
            token = re.search(r"Plan: ([a-f0-9]{64})", plan)[1]
            applied = run([*cli, "apply", "--existing", "replace", "--plan", token])
            checkpoint = re.search(r"Rollback id: (\S+)", applied)[1]
            assert not (home / ".zshrc").is_symlink()
            assert (legacy / "zshrc").read_text().startswith("# legacy fixture")
            # Reuse installed binaries while keeping test shell/config/state isolated.
            shims = home / ".local/share/mise/shims"
            shims.mkdir(parents=True)
            for name in ("node", "python3", "gh", "glab", "uv", "rg", "fd", "bat", "fzf", "jq", "eza", "codex"):
                (shims / name).symlink_to("/opt/homebrew/bin/mise")
            # The stale Codex shim must not shadow the app-bundled CLI.
        env = {
            "HOME": str(home), "USER": os.environ.get("USER", "workbench"),
            "LOGNAME": os.environ.get("LOGNAME", "workbench"), "SHELL": "/bin/zsh",
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "TERM": "xterm-256color", "LANG": "en_US.UTF-8",
            "XDG_CONFIG_HOME": str(home / ".config"), "XDG_CACHE_HOME": str(root / "cache"),
            "XDG_STATE_HOME": str(root / "state"), "XDG_DATA_HOME": str(root / "data"),
            "MISE_DATA_DIR": str(actual_home / ".local/share/mise"),
            "MISE_CACHE_DIR": str(root / "mise-cache"), "MISE_STATE_DIR": str(root / "mise-state"),
            "MISE_CONFIG_DIR": str(home / ".config/mise"),
            "MISE_GLOBAL_CONFIG_FILE": str(home / ".config/mise/config.toml"),
            "MISE_TRUSTED_CONFIG_PATHS": str(home / ".config/mise"),
        }
        check = '''set -e
test -z "${WB_LEGACY-}${OLLAMA_HOST-}${WIKI_VAULT-}"
test "$EDITOR" = nvim
command -v workbench
workbench doctor >/dev/null
node --version
python3 --version
gh --version | head -1
glab --version
rg --version | head -1
codex --version
test "$(command -v codex)" = /Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex
git --version
command -v herdr tmux nvim chezmoi mise
printf 'WORKBENCH_SHELL_OK\\n'
'''
        report = {"mode": "live" if args.live else "isolated"}
        for shell in ("/bin/zsh", "/bin/bash"):
            output = run([shell, "-lic", check], env=dict(env, SHELL=shell), cwd=home)
            assert "v24.14.1" in output and "Python 3.14.5" in output, output
            assert "WORKBENCH_SHELL_OK" in output, output
            report[Path(shell).name] = output
        report["noninteractive_zsh"] = run(["/bin/zsh", "-ec", "node --version; python3 --version; codex --version"], env=env, cwd=home)
        assert "v24.14.1" in report["noninteractive_zsh"] and "3.14.5" in report["noninteractive_zsh"]
        # Re-sourcing the environment must not duplicate paths.
        run(["/bin/zsh", "-c", '. "$HOME/.config/workbench/shell/env.sh"; before=$PATH; '
             '. "$HOME/.config/workbench/shell/env.sh"; test "$before" = "$PATH"'], env=env, cwd=home)
        git = "/opt/homebrew/bin/git"
        fixture_home = root / "git-home"
        fixture_home.mkdir()
        # Evaluate actual includeIf patterns against disposable client repos.
        git_env = dict(env, HOME=str(fixture_home), GIT_CONFIG_GLOBAL=str(home / ".gitconfig"))
        (fixture_home / ".config").symlink_to(home / ".config")
        identities = {}
        for client, expected in (("alertventure", "23528024+jeremyspofford@users.noreply.github.com"),
                                 ("vividcloud", "jspofford@vividcloud.com"),
                                 ("teradyne", "jspofford@vividcloud.com"),
                                 ("arialabs", "nova@arialabs.ai")):
            directory = fixture_home / "workspace" / client / "fixture"
            directory.mkdir(parents=True)
            run([git, "init", "-q", directory], env=git_env)
            email = run([git, "-C", directory, "config", "user.email"], env=git_env)
            assert email == expected, (client, email)
            identities[client] = email
        report["git_identities"] = identities
        # Integrations must coexist in a real interactive shell, including the
        # prompt inside a repository and safe handling of prompt metacharacters.
        run([git, "-C", directory, "symbolic-ref", "HEAD", "refs/heads/qol-%F{red}"], env=git_env)
        report["zsh_qol"] = run(["/bin/zsh", "-lic", '''
set -e
(( $+functions[compdef] && $+functions[_zsh_highlight] && $+functions[_zsh_autosuggest_start] ))
[[ ${widgets[fzf-history-widget]} == user:* ]]
[[ $(bindkey '^R') == *fzf-history-widget* ]]
[[ $(bindkey '^[[A') == *up-line-or-beginning-search* ]]
_workbench_prompt
[[ $PROMPT == *'qol-%%F{red}'* ]]
ll >/dev/null
lt >/dev/null
printf 'completion, highlighting, suggestions, fzf, listings, escaped Git branch: passed\\n'
'''], env=env, cwd=directory)
        editor_check = ('assert(vim.o.number and vim.o.expandtab and vim.o.shiftwidth == 2); '
                        'assert(vim.g.colors_name == "habamax"); '
                        'assert(package.loaded["lazy"] == nil and package.loaded["avante"] == nil)')
        editor_check = ('local ok, err = pcall(function() ' + editor_check +
                        ' end); if not ok then io.stderr:write(tostring(err)); vim.cmd("cquit 1") end')
        run(["/opt/homebrew/bin/nvim", "--headless", "-i", "NONE", "-n", "-u", home / ".config/nvim/init.lua",
             "+lua " + editor_check, "+qa!"], env=env, cwd=home)
        report["nvim"] = "baseline loads; no legacy plugin manager or AI plugin loaded"
        socket = root / "tmux.sock"
        tmux = ["/opt/homebrew/bin/tmux", "-S", socket]
        try:
            run([*tmux, "-f", home / ".tmux.conf", "new-session", "-d", "-s", "baseline", "/bin/sleep 30"], env=env, cwd=home)
            assert run([*tmux, "show-options", "-gv", "prefix"], env=env) == "C-a"
            assert run([*tmux, "show-options", "-gv", "mouse"], env=env) == "on"
            # Invoke the configured split binding and verify it inherits cwd.
            binding = run([*tmux, "list-keys", "-T", "prefix", "|"], env=env)
            assert "pane_current_path" in binding, binding
            run([*tmux, "split-window", "-h", "-c", "#{pane_current_path}", "/bin/sleep 30"], env=env)
            panes = run([*tmux, "list-panes", "-F", "#{pane_current_path}"], env=env).splitlines()
            assert panes == [str(home), str(home)], panes
            report["tmux"] = "isolated server loads config; prefix C-a, mouse, split cwd verified"
        finally:
            subprocess.run([str(x) for x in [*tmux, "kill-server"]], env=env, capture_output=True)
        if not args.live:
            # Prove rollback after all tools used the installed configuration.
            plan = run([*cli, "rollback", checkpoint])
            token = re.search(r"Plan: ([a-f0-9]{64})", plan)[1]
            run([*cli, "rollback", checkpoint, "--plan", token])
            assert (home / ".zshrc").is_symlink()
            assert (home / ".zshrc").read_text() == (legacy / "zshrc").read_text()
            assert not (home / ".gitconfig").exists()
            report["rollback"] = "restored legacy symlink; removed newly installed config"
        report["result"] = "passed"
        if args.report:
            args.report.write_text(json.dumps(report, indent=2) + "\n")
            args.report.chmod(0o600)
        print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
