#!/usr/bin/env bash
# new-stream — create an isolated git worktree for one orchestration stream.
#
# One engineer can run several of these side by side, each in its own worktree
# on its own branch, and review the final diff per stream. The <slug> is the
# single readable handle reused everywhere: the worktree directory, the branch,
# and the label you give the Claude session you open inside it — so both
# `git worktree list` and the session switcher show the same name.
#
# Usage: scripts/new-stream.sh <slug> [<type>]
#   <slug>   kebab-case stream name (e.g. add-docs-gate)
#   <type>   branch type: feature|bugfix|hotfix|chore|docs  (default: feature)
#
# Creates ../<repo>-worktrees/<slug> on branch <type>/<slug>, based on the
# repository's default branch. Fails if the worktree or the branch already
# exists, so re-running with a taken slug is a clear error, not a surprise.
set -euo pipefail

slug="${1:?usage: new-stream.sh <slug> [<type>]}"
type="${2:-feature}"

# The slug must be safe as a directory name, a branch segment, and a label.
if ! printf '%s' "$slug" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  echo "✗ slug must be kebab-case (lowercase letters, digits, single hyphens): got '$slug'" >&2
  exit 1
fi

# The type must be one of the documented branch prefixes (see .claude/rules/git.md).
case "$type" in
  feature|bugfix|hotfix|chore|docs) ;;
  *) echo "✗ type must be one of feature|bugfix|hotfix|chore|docs: got '$type'" >&2; exit 1 ;;
esac

# Resolve the MAIN worktree (first `git worktree list` entry) so the sibling worktrees
# dir is correct even when run from inside another stream's worktree.
root="$(git worktree list --porcelain | sed -n '1s/^worktree //p')"
if [ -z "$root" ]; then
  echo "✗ not inside a git repository" >&2
  exit 1
fi
repo="$(basename "$root")"
worktree="$(dirname "$root")/${repo}-worktrees/${slug}"
branch="${type}/${slug}"

if [ -e "$worktree" ]; then
  echo "✗ worktree already exists: $worktree" >&2
  exit 1
fi
if git show-ref --quiet --verify "refs/heads/${branch}"; then
  echo "✗ branch already exists: $branch" >&2
  exit 1
fi
if git show-ref --quiet --verify "refs/remotes/origin/${branch}"; then
  echo "✗ branch already exists on origin: origin/${branch}" >&2
  exit 1
fi

# Base new streams on the default branch when it is known, else current HEAD.
base="HEAD"
if git symbolic-ref --quiet refs/remotes/origin/HEAD >/dev/null 2>&1; then
  base="$(git symbolic-ref --short refs/remotes/origin/HEAD)"
fi

# Ensure the worktrees parent dir exists — older git won't create leading dirs.
mkdir -p "$(dirname "$worktree")"
git worktree add -b "$branch" "$worktree" "$base"

echo "✓ stream '${slug}' ready"
echo "    worktree : ${worktree}"
echo "    branch   : ${branch}  (based on ${base})"
echo "    session  : label your Claude session '${slug}' and run /implement there"
