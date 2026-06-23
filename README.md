# TARS

**Portable intelligence for AI agents.**

TARS is a repository of skills, tools, prompts, workflows, and agent behaviors that travel with you across projects and machines.

*Because every agent deserves a personality slider.*

Today TARS ships an opinionated set of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) **skills**. Install it once as a plugin and the workflow travels with you to every project — no per-project copying, and updates arrive through `git pull`.

## What's inside

The skills encode an opinionated path from idea to merged PR. Each is invoked with its slash command (e.g. `/refine`) or triggered by intent.

| Skill (folder) | Command | What it does |
|---|---|---|
| `refine` | `/refine` | Turns a raw idea or vague ticket into measurable, Jira-ready acceptance criteria via structured dialogue. |
| `design` | `/design` | Transforms a refined requirement into a validated Engineering Design Document (EDD). |
| `design-review` | `/design-review` | Runs `code-reviewer` + `security-auditor` over an EDD in parallel and appends a verdict. |
| `plan` | `/plan` | Decomposes an approved EDD into an ordered, verifiable task list. |
| `implement` | `/implement` | Builds the task list one vertical slice at a time: implement → test → commit. |
| `test` | `/test` | Runs the suite, auto-fixes mechanical failures, escalates the rest. |
| `review` | `/review` | Opens a PR with a clean description and responds to review comments. |
| `review-resolve-comments` | `/resolve-pr-comments` | Classifies PR comments by impact, fixes major/critical, replies with the commit reference. |

Typical flow: `/refine` → `/design` → `/design-review` → `/plan` → `/implement` → `/test` → `/review` → `/resolve-pr-comments`.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- `git`
- macOS, Linux, or Windows (the plugin install is OS-agnostic; the backup symlink/Stow steps assume a POSIX shell)

## Install

### Recommended — Claude Code plugin

TARS is packaged as a Claude Code plugin distributed through its own marketplace. This is the primary, supported path: it's git-backed, version-aware, updates from inside Claude Code, and needs no manual file management. Skills install machine-wide and apply to every project.

Inside any Claude Code session, run:

```text
/plugin marketplace add udalovas/tars
/plugin install tars
```

That's it — the skills (`/refine`, `/design`, …) are available everywhere. Skills from a plugin are namespaced, so you may also see them as `/tars:refine`.

**Update:** plugins track the marketplace repo. Pull the latest with `/plugin marketplace update tars`, then `/plugin install tars` again if needed. Because `plugin.json` declares a `version`, bump it on release so installs pick up changes predictably.

**Uninstall / disable:** `/plugin uninstall tars` (use the `/plugin` manager UI to disable without removing).

> No marketplace registration needed for a one-off install: `/plugin install github:udalovas/tars`.

---

### Backup — manual install (no plugin manager)

If you can't use the plugin manager (older Claude Code, restricted environment, or you simply prefer raw files), clone the repo and link `skills/` into your global `~/.claude/skills`. Pick one.

#### Option 1 — Per-skill symlinks

Safe to re-run, and coexists with any other skills already in `~/.claude/skills`.

```bash
# 1. Clone (any location; ~/Projects/tars used here)
git clone https://github.com/udalovas/tars.git ~/Projects/tars
cd ~/Projects/tars

# 2. Link each skill into the global skills dir
mkdir -p ~/.claude/skills
for dir in "$PWD"/skills/*/; do
  name="$(basename "$dir")"
  ln -sfn "${dir%/}" "$HOME/.claude/skills/$name"
done

# 3. Verify
ls -la ~/.claude/skills
```

`ln -sfn` makes this idempotent — re-running after `git pull` is a no-op, and new skills get linked on the next run.

> Linking the whole directory (`ln -sfn "$PWD/skills" ~/.claude/skills`) is simpler but **clobbers** any other global skills you have. Use it only if `~/.claude/skills` is empty.

**Update:** `cd ~/Projects/tars && git pull` — symlinks point at the repo, so changes apply immediately.

**Uninstall:** remove only the links that point back into this repo.

```bash
for link in "$HOME"/.claude/skills/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    "$HOME"/Projects/tars/*) rm "$link" ;;
  esac
done
```

#### Option 2 — GNU Stow

[GNU Stow](https://www.gnu.org/software/stow/) is the dotfiles-standard symlink-farm manager — fully reversible, worth it if you already manage dotfiles this way.

```bash
brew install stow            # macOS  (Linux: apt/dnf install stow)
cd ~/Projects/tars
stow --target="$HOME/.claude/skills" --dir="$PWD" skills
```

**Uninstall:** `stow --target="$HOME/.claude/skills" --dir="$PWD" --delete skills`

## Repository layout

```
tars/
├── .claude-plugin/
│   ├── plugin.json            # plugin manifest (name, version, author)
│   └── marketplace.json       # marketplace listing → makes the repo /plugin-installable
├── skills/
│   ├── refine/
│   ├── design/                # includes references/ with EDD patterns & dialogue examples
│   ├── design-review/
│   ├── plan/
│   ├── implement/
│   ├── test/
│   ├── review/
│   └── review-resolve-comments/
└── README.md
```

The repo is **both** a marketplace and the plugin it serves. Other Claude Code assets — `agents/`, `commands/`, `hooks/` — can be added at the repo root and ship through the same plugin.
