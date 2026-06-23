# TARS

**Portable intelligence for AI agents.**

TARS is a repository of skills, tools, prompts, workflows, and agent behaviors that travel with you across projects and machines.

*Because every agent deserves a personality slider.*

Today TARS ships an opinionated set of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) **skills**. Install it once as a plugin and the workflow travels with you to every project — no per-project copying, and updates arrive through `/plugin marketplace update`.

## What's inside

The skills encode an opinionated path from idea to merged PR. Each is invoked with its slash command (e.g. `/refine`) or triggered by intent.

| Skill (folder) | Command | What it does |
|---|---|---|
| `refine` | `/refine` | Turns a raw idea or vague ticket into measurable, Jira-ready acceptance criteria via structured dialogue. |
| `design` | `/design` | Transforms a refined requirement into a validated Engineering Design Document (EDD). |
| `design-review` | `/design-review` | Runs `design-reviewer` + `security-auditor` (plus an optional `aws-reviewer` pass) over an EDD in parallel and appends a verdict. |
| `plan` | `/plan` | Decomposes an approved EDD into an ordered, verifiable task list. |
| `implement` | `/implement` | Builds the task list one vertical slice at a time: implement → test → commit. |
| `test` | `/test` | Runs the suite, auto-fixes mechanical failures, escalates the rest. |
| `review` | `/review` | Opens a PR with a clean description and responds to review comments. |
| `resolve-pr-comments` | `/resolve-pr-comments` | Classifies PR comments by impact, fixes major/critical, replies with the commit reference. |

Typical flow: `/refine` → `/design` → `/design-review` → `/plan` → `/implement` → `/test` → `/review` → `/resolve-pr-comments`.

The skills are **project-agnostic**: they carry generic workflow logic and read project-specific details (test/lint commands, design-doc location, coding standards) from each project's own `CLAUDE.md`. Example commands in the skills (npm, etc.) are clearly marked as examples, not assumptions.

## Agents

The review steps fan out to dedicated review agents, bundled at `agents/` and shipped with the plugin. Like the skills, they're **project-agnostic** — each carries a review *framework*, not a stack, and reads the language, conventions, and applicable compliance regimes from the project's `CLAUDE.md` / `.claude/rules/`.

| Agent | Used by | Role |
|---|---|---|
| `code-reviewer` | `/review` | Five-dimension review of a code diff or PR. |
| `design-reviewer` | `/design-review` | Architecture-altitude EDD review, incl. trade-off analysis on hard-to-reverse decisions. |
| `security-auditor` | `/design-review` | Generic application-security core **+** a self-gating commodities-trading compliance lens (data-protection / market-integrity / AI-regulation). No org specifics — escalation paths come from the project. |
| `test-engineer` | `/test` | Test strategy and coverage-gap analysis. |
| `aws-reviewer` | `/design-review`, `/review` | **Optional** AWS Well-Architected lens. Self-declines on non-AWS projects, so it's purely additive. |

These agents enrich the review passes; they are **not** a hard dependency. On a machine where they aren't installed (e.g. a partial manual install), the skills perform the review inline instead.

### Overriding a bundled agent

Bundled agents are **lowest-precedence defaults**. Claude Code resolves an agent by its bare name to the highest-precedence definition it can find:

```
project   .claude/agents/<name>.md      ← wins
user      ~/.claude/agents/<name>.md
plugin    agents/<name>.md  (TARS)       ← fallback default
```

So if your team already has its own `test-engineer` — or any same-named agent — **drop it in the project's `.claude/agents/` and it transparently takes over**. No configuration, and nothing in TARS is touched or overwritten; the bundled version simply stops being selected. The agents ship with bare (un-namespaced) names precisely so this override works, and the skills always invoke them by bare name rather than pinning the plugin-namespaced form. To extend rather than replace, copy the bundled agent into `.claude/agents/` and edit your copy.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- `git`; a GitHub repo + `gh` CLI for the PR-related skills (`review`, `resolve-pr-comments`)
- macOS, Linux, or Windows (the plugin install is OS-agnostic; the backup symlink/Stow steps assume a POSIX shell)

### Optional integrations

These skills use extra capabilities **if present**, and degrade gracefully if not:

- **Review agents** — `design-review`, `test`, and `review` use the bundled review agents (see [Agents](#agents)) when present; otherwise they perform the review inline. The agents ship project-agnostic, so a project's own `CLAUDE.md` supplies the stack and compliance specifics. You can still override or extend them under a project's `.claude/agents/`.
- **Issue tracker** — `refine` can read from / write to an issue tracker (e.g. a `jira` skill) when available; otherwise it hands the requirement block back to you to file.

## Install

### Recommended — Claude Code plugin

TARS is packaged as a Claude Code plugin distributed through its own marketplace. This is the primary, supported path: it's git-backed, version-aware, updates from inside Claude Code, and needs no manual file management. Skills install machine-wide and apply to every project.

Inside any Claude Code session, run:

```text
/plugin marketplace add udalovas/tars
/plugin install tars
```

That's it — the skills (`/refine`, `/design`, …) are available everywhere. Skills from a plugin are namespaced, so you may also see them as `/tars:refine`.

> **Just want one skill?** The plugin intentionally installs the full, curated workflow — Claude Code has no per-skill `/plugin install` (the plugin is the smallest installable unit). To cherry-pick a single skill, e.g. just `/refine`, use the [single-skill install](#install-a-single-skill) below.

**Update:** plugins track the marketplace repo. Pull the latest with `/plugin marketplace update tars`, then `/plugin install tars` again if needed. Because `plugin.json` declares a `version`, bump it on release so installs pick up changes predictably.

**Uninstall / disable:** `/plugin uninstall tars` (use the `/plugin` manager UI to disable without removing).

> No marketplace registration needed for a one-off install: `/plugin install github:udalovas/tars`.

---

### Backup — manual install (no plugin manager)

If you can't use the plugin manager (older Claude Code, restricted environment, or you simply prefer raw files), clone the repo and symlink what you want into your global `~/.claude/skills` — a single skill, or the whole suite.

#### Install a single skill

Want only one skill — say `refine` — and none of the rest? A skill is a self-contained folder, so link just that one:

```bash
git clone https://github.com/udalovas/tars.git ~/Projects/tars
mkdir -p ~/.claude/skills
ln -sfn ~/Projects/tars/skills/refine ~/.claude/skills/refine   # swap "refine" for any skill in skills/
```

`/refine` is now available everywhere and nothing else from TARS is installed. Repeat the `ln -sfn` line for each additional skill you want — that's the per-skill granularity the plugin path doesn't offer.

- **Cross-references are soft.** A skill may point you at the next step ("run `/design`"); if that skill isn't installed, the pointer just has nothing to resolve to — the skill itself still works standalone.
- **Review agents are separate.** This links only the skill, not `agents/`, so `design-review` / `test` / `review` fall back to inline review. Link the agents too (see [Agents](#agents)) if you want the multi-agent passes.
- **Update / uninstall:** the symlink tracks the repo, so `git pull` applies changes immediately; `rm ~/.claude/skills/refine` removes just that skill.

#### Option 1 — Per-skill symlinks (full suite)

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

## Repository layout

```
tars/
├── .claude-plugin/
│   ├── plugin.json            # plugin manifest (name, version, author)
│   └── marketplace.json       # marketplace listing → makes the repo /plugin-installable
├── agents/                    # bundled review agents (ship via the plugin)
│   ├── code-reviewer.md
│   ├── design-reviewer.md
│   ├── security-auditor.md
│   ├── test-engineer.md
│   └── aws-reviewer.md        # optional — self-gates to AWS-hosted projects
├── skills/
│   ├── refine/
│   ├── design/                # includes references/ with EDD patterns & dialogue examples
│   ├── design-review/
│   ├── plan/
│   ├── implement/
│   ├── test/
│   ├── review/
│   └── resolve-pr-comments/
└── README.md
```

The repo is **both** a marketplace and the plugin it serves: the `skills/` and `agents/` at the repo root ship together through the same plugin. Further Claude Code assets — `commands/`, `hooks/` — can be added the same way.

## License

Released under the [MIT License](LICENSE) — © 2026 Aleksei Udalov. Use, modify, and redistribute freely; keep the copyright notice.
