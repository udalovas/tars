#!/usr/bin/env python3
"""Print the CHANGELOG.md section body (no header) for a given version.

Usage: scripts/extract-changelog.py 0.2.0
Used by the release workflow to populate GitHub Release notes. Exits non-zero
if the version has no section.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: extract-changelog.py <version>", file=sys.stderr)
        return 2
    version = sys.argv[1]
    text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    # "## [<version>]" + optional " - date", body up to the next "## [", the
    # link-reference block ("[x]: url"), or EOF — whichever comes first.
    pattern = rf"^## \[{re.escape(version)}\][^\n]*\n(.*?)(?=^## \[|^\[[^\]]+\]:|\Z)"
    m = re.search(pattern, text, re.DOTALL | re.MULTILINE)
    if not m:
        print(f"no CHANGELOG section for version {version}", file=sys.stderr)
        return 1
    print(m.group(1).strip())
    return 0


if __name__ == "__main__":
    sys.exit(main())
