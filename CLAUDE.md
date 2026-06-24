# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

TARS is a **Claude Code plugin that is also its own marketplace**. There is no application to build or run — the deliverables are Markdown assets (skills and agents) that install into other people's Claude Code environments and travel across their projects. The repo dogfoods its own workflow: changes here are meant to flow through `/refine → /design → /design-review → /plan → /implement → /test → /review → /resolve-pr-comments`.

The product is an opinionated SDLC workflow encoded as skills, plus bundled review agents the review-related skills fan out to.

## Commands

There is no compiler, package manager, or test framework — validation is a single stdlib-only Python script.

```bash
python3 scripts/validate.py                        # validate manifests + every skill/agent frontmatter
bash scripts/check-version-bump.sh origin/main     # enforce version bump when skills/ or agents/ changed
```

`scripts/validate.py` is the closest thing to a test suite and the verify command for most changes. CI (`.github/workflows/validate.yml`) runs both on every PR.

## The two asset types (and their hard rules)

Everything ships from the repo root through one plugin:

- **Skills** — `skills/<name>/SKILL.md`. Frontmatter `name:` **must equal the folder name**.
- **Agents** — `agents/<name>.md`. Frontmatter `name:` **must equal the file stem**.

Both require `name` and `description` frontmatter. `validate.py` enforces all of the above — a name mismatch fails CI.

## Core design invariants

These are the non-obvious rules that make the plugin portable. Violating them breaks installs silently or regresses the product contract.

1. **Project-agnostic by construction.** Skills and agents carry a *framework*, never a stack. They must not assume a language, build tool, cloud, or company. Anything project-specific (test/lint commands, doc locations, coding standards, compliance regimes, escalation contacts) is read at runtime from the *consuming* project's `CLAUDE.md` / `.claude/rules/`. Example commands inside skills (npm, etc.) are explicitly marked as examples, not assumptions.

2. **Agents are invoked by bare name; never pin the plugin-namespaced form.** Bare-name invocation lets a consuming project override a bundled agent by dropping `.claude/agents/<name>.md` into their repo. Precedence: project `.claude/agents/` > user `~/.claude/agents/` > bundled `agents/` (lowest). Bundled agents must describe themselves as the "lowest-precedence default." Never write a skill that pins `tars:<agent>`, and never overwrite a project-local agent file.

3. **Skills must degrade gracefully.** A skill must work on a clean machine with no bundled agents installed. Review skills (`design-review`, `test`, `review`) delegate to agents *when available* and otherwise **perform the review inline**. When adding agent delegation, always include the inline fallback and the bare-name/override note — mirror the existing wording in `skills/design-review/SKILL.md`.

4. **The version bump is a release-correctness contract, not hygiene.** `plugin.json`'s `version` is Claude Code's update cache key. Shipping a change under `skills/` or `agents/` **without** bumping the version means `/plugin update` reports "already latest" and users never receive it. So: any change touching `skills/` or `agents/` requires a semver bump in `.claude-plugin/plugin.json` **and** a `CHANGELOG.md` entry. `check-version-bump.sh` fails the PR otherwise.

## Skill / agent authoring conventions

Follow the prevailing structure of existing files rather than inventing a new shape:

- Skills follow a consistent rhythm: `When to Use` / `When NOT to use`, a numbered process, a `Common Rationalizations` table, `Red Flags`, and a `Verification` checklist.
- Review agents follow: a "Project Context — Read First" section (read the consuming project's standards before judging), explicit review dimensions, an issue/severity classification using shared vocabulary (Blocking / Non-blocking / Suggestion, or Critical…Info) so the owning skill can merge findings, an output-format block, `Rules`, and a `Composition` section ending with the lowest-precedence-default note.
- Keep agents at their own altitude and hand off across boundaries (`code-reviewer` = code, `design-reviewer` = architecture, `security-auditor` = security/compliance, `docs-consistency-reviewer` = docs, `aws-reviewer` = optional AWS lens that self-declines off-AWS).

## Release flow

Automated. On push to `main`, `.github/workflows/release.yml` runs `scripts/release.sh`, which tags `v<version>` and publishes a GitHub Release **only when `plugin.json`'s version has no matching tag** (idempotent — unrelated commits are a no-op). Release notes are extracted from the matching `CHANGELOG.md` section via `scripts/extract-changelog.py`. Practical consequence: land the version bump and CHANGELOG entry in the same PR as the change.

## Repository map

- `.claude-plugin/plugin.json` — manifest; `version` is the update/release key.
- `.claude-plugin/marketplace.json` — makes the repo `/plugin`-installable.
- `skills/<name>/SKILL.md` — one folder per skill; `design/` also carries `references/`.
- `agents/<name>.md` — bundled review agents.
- `scripts/` — `validate.py`, `check-version-bump.sh`, `release.sh`, `extract-changelog.py`.
