#!/usr/bin/env python3
"""Export public toolkit entries to the portfolio site.

Usage: python3 export_toolkit.py <path-to-portfolio-repo>
Writes <portfolio>/src/data/toolkit/<id>.yml for every `public: true` entry in
toolkit.yml (using public_source when present) and removes files for entries
that are no longer public. Refuses to export text that looks client-specific.
"""
import pathlib, re, sys, yaml

HERE = pathlib.Path(__file__).resolve().parent
BLOCK = re.compile(r"vividcloud|alertventure|teradyne|atlassian\.net|@[\w-]+\.(com|ai|net)|jeremys-macbook", re.I)

def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    out = pathlib.Path(sys.argv[1]).expanduser() / "src" / "data" / "toolkit"
    out.mkdir(parents=True, exist_ok=True)
    manifest = yaml.safe_load((HERE / "toolkit.yml").read_text())
    keep = set()
    for e in manifest["entries"]:
        if not e.get("public"):
            continue
        src = HERE / (e.get("public_source") or e["source"])
        body = src.read_text().strip()
        body = re.sub(r"<!--.*?-->\s*", "", body, flags=re.S)
        if BLOCK.search(body) or BLOCK.search(e.get("description", "")):
            sys.exit(f"REFUSED: {e['id']} looks client-specific ({BLOCK.search(body) or BLOCK.search(e['description'])}). Add a sanitized public_source.")
        doc = {"PK": "TOOLKIT", "SK": e["id"], "content": {
            "title": e["title"], "type": e["type"], "description": e["description"],
            "tags": e.get("tags", []), "schedule": e.get("schedule"), "body": body}}
        (out / f"{e['id']}.yml").write_text(yaml.safe_dump(doc, sort_keys=False, allow_unicode=True, width=1000))
        keep.add(f"{e['id']}.yml")
    for f in out.glob("*.yml"):
        if f.name not in keep:
            f.unlink()
    print(f"Exported {len(keep)} public entries to {out}")

if __name__ == "__main__":
    main()
