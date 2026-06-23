#!/usr/bin/env python3
"""Validate the TARS plugin: manifests and skill/agent frontmatter.

Runnable locally (`python3 scripts/validate.py`) and in CI. Stdlib only —
no third-party YAML dependency. Exits non-zero on any error, listing every
problem found rather than stopping at the first.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def load_json(path: Path) -> dict | None:
    if not path.exists():
        err(f"{path.relative_to(ROOT)}: missing")
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        err(f"{path.relative_to(ROOT)}: invalid JSON — {e}")
        return None


def require(obj: dict, key: str, where: str) -> None:
    if not obj.get(key):
        err(f"{where}: missing required field '{key}'")


def parse_frontmatter(path: Path) -> dict[str, str] | None:
    """Minimal YAML-frontmatter reader: a leading '---' block of key: value
    pairs. Sufficient for skill/agent frontmatter; avoids a PyYAML dep."""
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        err(f"{path.relative_to(ROOT)}: no '---' frontmatter block at top")
        return None
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
    if not m:
        err(f"{path.relative_to(ROOT)}: frontmatter block is not closed with '---'")
        return None
    fields: dict[str, str] = {}
    for line in m.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        fields[key.strip()] = value.strip()
    return fields


def validate_manifests() -> None:
    plugin = load_json(ROOT / ".claude-plugin" / "plugin.json")
    if plugin is not None:
        for key in ("name", "version", "description", "license"):
            require(plugin, key, "plugin.json")

    market = load_json(ROOT / ".claude-plugin" / "marketplace.json")
    if market is not None:
        for key in ("name", "plugins"):
            require(market, key, "marketplace.json")
        for i, p in enumerate(market.get("plugins", []) or []):
            for key in ("name", "source", "description"):
                if not p.get(key):
                    err(f"marketplace.json: plugins[{i}] missing '{key}'")


def validate_dir(kind: str, base: Path, get_file) -> None:
    if not base.exists():
        err(f"{kind}: directory '{base.relative_to(ROOT)}' is missing")
        return
    for entry in sorted(base.iterdir()):
        file, expected_name = get_file(entry)
        if file is None:
            continue
        if not file.exists():
            err(f"{kind} '{entry.name}': expected {file.relative_to(ROOT)}")
            continue
        fields = parse_frontmatter(file)
        if fields is None:
            continue
        for key in ("name", "description"):
            if not fields.get(key):
                err(f"{file.relative_to(ROOT)}: frontmatter missing '{key}'")
        actual = fields.get("name")
        if actual and actual != expected_name:
            err(
                f"{file.relative_to(ROOT)}: frontmatter name '{actual}' "
                f"!= expected '{expected_name}'"
            )


def validate_skills() -> None:
    validate_dir(
        "skill",
        ROOT / "skills",
        lambda e: (e / "SKILL.md", e.name) if e.is_dir() else (None, None),
    )


def validate_agents() -> None:
    validate_dir(
        "agent",
        ROOT / "agents",
        lambda e: (e, e.stem) if e.suffix == ".md" else (None, None),
    )


def main() -> int:
    validate_manifests()
    validate_skills()
    validate_agents()

    if errors:
        print(f"✗ validation failed — {len(errors)} problem(s):\n")
        for e in errors:
            print(f"  - {e}")
        return 1
    print("✓ plugin valid: manifests, skills, and agents all pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
