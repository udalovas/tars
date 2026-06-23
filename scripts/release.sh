#!/usr/bin/env bash
# Tag v<version> and publish a GitHub Release when plugin.json's version has no
# matching tag yet. Idempotent: runs on every push to main but only acts when
# the version is new, so unrelated commits are a no-op. Requires `gh` with a
# token that has contents:write.
#
# Usage: scripts/release.sh   (reads version from .claude-plugin/plugin.json)
set -euo pipefail

VERSION="$(python3 -c 'import json;print(json.load(open(".claude-plugin/plugin.json"))["version"])')"
TAG="v${VERSION}"

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "Release $TAG already exists — nothing to do."
  exit 0
fi

NOTES_FILE="$(mktemp)"
trap 'rm -f "$NOTES_FILE"' EXIT
if ! python3 scripts/extract-changelog.py "$VERSION" >"$NOTES_FILE" 2>/dev/null \
    || [ ! -s "$NOTES_FILE" ]; then
  echo "Release $TAG. See CHANGELOG.md." >"$NOTES_FILE"
fi

echo "Creating release $TAG…"
gh release create "$TAG" \
  --target "${GITHUB_SHA:-HEAD}" \
  --title "$TAG" \
  --notes-file "$NOTES_FILE"
echo "✓ released $TAG"
