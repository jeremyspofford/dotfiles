"""Write settings for installed coding agents; requires Python 3.11+.

An agent is a coding assistant. The manifest lists its settings and paths.
Usage: python3 scripts/agent_configs.py [--home PATH] [--os OS] [--dry-run]
Parameters: --home selects a full target home path; --dry-run lists changes only.
--os selects linux (Linux), darwin (macOS), windows (Windows), or wsl (Windows Subsystem for Linux).
-h and --help print full help. See argparse, Python's argument parser, for details.
Example: bash scripts/generate-agent-configs.sh --dry-run
Exit codes: 0 success/help; 1 conflict or runtime failure; 2 invalid arguments.
Author: Jeremy Spofford / Aria Labs; Version: read from ../VERSION.
The calling Bash wrapper sends messages through logger.sh.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import sys
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def native_os():
    if os.environ.get("WSL_DISTRO_NAME") or os.environ.get("WSL_INTEROP"):
        return "wsl"
    return {"Linux": "linux", "Darwin": "darwin", "Windows": "windows"}[platform.system()]


def target(home, relative):
    path = home / relative
    if Path(relative).is_absolute() or ".." in Path(relative).parts:
        raise ValueError(f"Unsafe manifest path: {relative}")
    # Do not follow a config-directory link into an unrelated checkout.
    if not path.parent.resolve().is_relative_to(home.resolve()):
        raise ValueError(f"Target parent escapes selected home: {relative}")
    return path


def write_atomic(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".dotfiles-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def generate(home, os_name, dry_run):
    manifest = tomllib.loads((ROOT / "agents/manifest.toml").read_text())
    if manifest["schema_version"] != 1:
        raise ValueError("Unsupported manifest schema")
    source = (ROOT / manifest["skills_source"]).resolve()
    if not source.is_relative_to(ROOT):
        raise ValueError("Skills source must be inside the repository")
    skills = sorted(path.parent for path in source.glob("*/SKILL.md"))
    state_path = target(home, ".local/state/dotfiles/agents.json")
    if state_path.is_symlink():
        raise ValueError("Refusing a symlinked output inventory")
    previous = json.loads(state_path.read_text()) if state_path.exists() else {}
    planned = {}
    payloads = {}
    for name, agent in manifest["agents"].items():
        if not shutil.which(agent["command"]):
            print(f"Absent: {name}")
            continue
        if not agent["supported"]:
            print(f"Unsupported native contract: {name}: {agent['reason']}")
            continue
        content = agent["content"]
        if agent["format"] == "json":
            json.loads(content)
        elif agent["format"] == "toml":
            tomllib.loads(content)
        else:
            raise ValueError(f"Unknown format: {name}")
        relative = agent["config_paths"][os_name]
        planned[relative] = {"sha256": digest(content.encode()), "agent": name}
        payloads[relative] = content.encode()
        for skill in skills:
            relative = str(Path(agent["skills_paths"][os_name]) / skill.name)
            if relative in planned:
                raise ValueError(f"Two sources own one output: {relative}")
            planned[relative] = {"link": str(skill), "agent": name}
    # Preflight every target before changing any file.
    for relative, item in planned.items():
        path = target(home, relative)
        old = previous.get(relative)
        if path.is_symlink():
            if not old or old.get("link") != os.readlink(path):
                raise ValueError(f"Unmanaged/modified link: {relative}")
        elif path.exists():
            if not path.is_file() or not old or old.get("sha256") != digest(path.read_bytes()):
                raise ValueError(f"Unmanaged/modified config: {relative}; move it aside after review")
        print(f"{'Would generate' if dry_run else 'Generate'}: {relative}")
    for relative in previous.keys() - planned.keys():
        print(f"Retained output (agent absent or manifest changed): {relative}")
    if dry_run:
        return
    # Record intent before writes so partial failures are still inventoried.
    updated = {**previous, **planned}
    write_atomic(state_path, (json.dumps(updated, indent=2, sort_keys=True) + "\n").encode())
    for relative, item in planned.items():
        path = target(home, relative)
        if "link" in item:
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.is_symlink() and os.readlink(path) == item["link"]:
                continue
            if path.is_symlink():
                path.unlink()
            path.symlink_to(item["link"], target_is_directory=True)
        else:
            write_atomic(path, payloads[relative])


def main():
    parser = argparse.ArgumentParser(
        description="Write settings for installed coding agents from agents/manifest.toml.\n"
        "An agent is a coding assistant. The manifest lists settings and paths.\n"
        "The Bash wrapper logs messages through logger.sh. Requires Python 3.11+.",
        epilog="Example: bash scripts/generate-agent-configs.sh --dry-run\n"
        "Exit codes: 0 success/help; 1 conflict or runtime failure; 2 invalid arguments.\n"
        "Author: Jeremy Spofford / Aria Labs; Version: " + (ROOT / "VERSION").read_text().strip(),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--home", type=Path, default=Path.home(), help="full target home path; default: current user home")
    parser.add_argument("--os", choices=["linux", "darwin", "windows", "wsl"], help="linux=Linux, darwin=macOS, windows=Windows, wsl=Windows Subsystem for Linux; default: detected system")
    parser.add_argument("--dry-run", action="store_true", help="validate and report proposed paths without writing")
    args = parser.parse_args()
    if not args.home.is_absolute():
        parser.error("--home must be absolute")
    try:
        generate(args.home, args.os or native_os(), args.dry_run)
    except (OSError, ValueError, KeyError) as error:
        print(f"ERROR: {error}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
