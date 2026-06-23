#!/usr/bin/env bash
# Fail if skills/ or agents/ changed relative to the base ref without a
# plugin.json version bump. TARS pins an explicit version, which Claude Code
# uses as the update cache key — shipping skill/agent changes under an
# unchanged version means `/plugin update` reports "already latest" and users
# never receive them. This guard makes that mistake a red CI check.
#
# Usage: scripts/check-version-bump.sh <base-ref>   (e.g. origin/main)
set -euo pipefail

BASE="${1:?usage: check-version-bump.sh <base-ref>}"
MANIFEST=".claude-plugin/plugin.json"

read_version() { # <git-ref>
  git show "$1:$MANIFEST" 2>/dev/null \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])'
}

changed="$(git diff --name-only "$BASE"...HEAD -- skills agents || true)"
if [ -z "$changed" ]; then
  echo "✓ no changes under skills/ or agents/ — version bump not required."
  exit 0
fi

head_ver="$(read_version HEAD)"
base_ver="$(read_version "$BASE" || echo "")"

if [ "$head_ver" = "$base_ver" ]; then
  echo "✗ skills/ or agents/ changed but plugin.json version is still ${head_ver}."
  echo "  Bump the version (semver) so users actually receive the update, and roll CHANGELOG.md."
  echo "  Changed files:"
  echo "$changed" | sed 's/^/    - /'
  exit 1
fi

echo "✓ version bumped ${base_ver:-<none>} → ${head_ver} for skills/agents changes."
