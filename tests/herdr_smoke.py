#!/usr/bin/env python3
"""Exercise an isolated Herdr server in an existing repo without changing it."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path)
    args = parser.parse_args()
    repo = args.repo.resolve(strict=True)
    def git(*args):
        return subprocess.check_output(["git", "--no-optional-locks", "-C", str(repo), *args])
    def fingerprint():
        return {"head": git("rev-parse", "HEAD").decode().strip(),
                "status": git("status", "--porcelain=v1", "--branch").decode(),
                "diff": hashlib.sha256(git("diff", "--binary", "HEAD")).hexdigest()}
    before = fingerprint()
    root = Path(tempfile.mkdtemp(prefix="wb-herdr-", dir="/tmp"))
    config = root / "config.toml"
    config.write_text('[terminal]\ndefault_shell = "/bin/sh"\nshell_mode = "non_login"\n'
                      '[update]\nversion_check = false\nmanifest_check = false\n')
    env = dict(os.environ, HERDR_CONFIG_PATH=str(config),
               HERDR_SOCKET_PATH=str(root / "herdr.sock"),
               XDG_CONFIG_HOME=str(root / "config"), XDG_STATE_HOME=str(root / "state"))
    def call(*args):
        result = subprocess.run(["herdr", *args], env=env, capture_output=True, text=True, timeout=20)
        if result.returncode:
            raise RuntimeError(result.stderr)
        return result.stdout
    def api(*args):
        return json.loads(call(*args))["result"]
    evidence = {"repo": str(repo), "before": before, "version": call("--version").strip()}
    with (root / "server.log").open("w") as log:
        server = subprocess.Popen(["herdr", "server"], cwd=repo, env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            for _ in range(50):
                if server.poll() is not None:
                    raise RuntimeError((root / "server.log").read_text())
                if "status: running" in call("status", "server"):
                    break
                time.sleep(.1)
            else:
                raise RuntimeError("Herdr server did not become ready")
            created = api("workspace", "create", "--cwd", str(repo), "--label", "workbench-smoke", "--no-focus")
            pane = created["root_pane"]["pane_id"]
            assert created["root_pane"]["cwd"] == str(repo), created
            evidence["workspace"] = created
            call("pane", "wait-output", pane, "--match", "$", "--timeout", "10000")
            # Split marker strings prevent matching the echoed command itself.
            command = "pwd; git --no-optional-locks status --short --branch; printf '\\n%s%s\\n' WORKBENCH_ SMOKE_OK"
            call("pane", "run", pane, command)
            call("pane", "wait-output", pane, "--match", "WORKBENCH_SMOKE_OK", "--timeout", "10000")
            evidence["pane_output"] = call("pane", "read", pane, "--source", "recent-unwrapped", "--lines", "40")
            # Create a second pane, keeping focus and repo cwd explicit.
            evidence["split"] = api("pane", "split", pane, "--direction", "right", "--cwd", str(repo), "--no-focus")
            assert evidence["split"]["pane"]["cwd"] == str(repo)
            evidence["after"] = fingerprint()
            assert evidence["before"] == evidence["after"], "Repository state changed"
            evidence["result"] = "passed"
        finally:
            if server.poll() is None:
                try:
                    call("server", "stop")  # Socket is unique to this process.
                    server.wait(timeout=10)
                finally:
                    if server.poll() is None:
                        server.terminate()
                        server.wait(timeout=10)
            evidence["stopped"] = server.poll() is not None
            (root / "evidence.json").write_text(json.dumps(evidence, indent=2) + "\n")
            print("Evidence:", root / "evidence.json")
    print(json.dumps(evidence, indent=2))


if __name__ == "__main__":
    main()
