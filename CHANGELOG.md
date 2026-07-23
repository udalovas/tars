# Changelog

All notable changes to TARS are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The plugin version lives in `.claude-plugin/plugin.json`; bump it on release so
installs pick up changes predictably.

## [Unreleased]

## [0.4.0] - 2026-07-23

### Added
- Orchestration mode — run the existing `/implement`, `/test`, and `/review`
  skills as parallel, self-checked worktree **streams**, so one engineer can
  dispatch 5–10 at once and review gate-green final diffs instead of keystrokes.
  - `/implement` gains an auto-mode posture and owns a **self-check gate**
    (tests + build + lint + automated `code-reviewer`) that must pass before a
    diff is surfaced; blocking failures auto-fix and re-run (max 2 attempts)
    then escalate. Checks the project doesn't define are reported as "not run",
    never silently passed. `security-auditor` stays opt-in.
  - `/test` documents its role as the tests+build+lint gate component and
    returns a structured per-check pass/fail.
  - `/review` notes that `code-reviewer` already ran in the gate, so PR
    creation doesn't re-invoke it.
  - New `docs/ORCHESTRATION.md` onboarding guide (stream/slug conventions,
    canonical gate definition, `.claude/settings.json` auto-mode snippet,
    copy-paste `new-stream` worktree helper, enable checklist) and a mirrored
    `scripts/new-stream.sh`.
  - `docs/EDD/001-fleet-orchestration.md` design doc (establishes `docs/EDD/`).

  Purely additive — the skills still work single-stream and degrade gracefully
  with no worktrees or bundled agents.

## [0.3.0] - 2026-07-17

### Added
- `retro` skill — end-of-session retrospective, the new final step of the
  workflow chain (`… → /resolve-pr-comments → /retro`). Mines the finished
  session for friction through three lenses (key decisions, rule/standard
  gaps that forced clarifications or corrections, context-gathering
  inefficiencies), curates at most 5 evidence-linked findings, and proposes
  diff-ready improvements to the consuming project's `CLAUDE.md`,
  `.claude/rules/`, and docs. Applies only engineer-approved edits, to
  project files only; the report itself stays chat-only.

## [0.2.1] - 2026-06-24

### Added
- `docs-consistency-reviewer` agent — a pre-PR docs gate that checks new
  functionality is documented to the project's standard (coverage) and that the
  change hasn't left existing docs stale or contradictory (consistency).
  Project-agnostic, diff-scoped, and report-only, with a built-in floor
  checklist when a project documents no conventions.
- The `review` skill now runs the docs-consistency gate in PR creation
  (Sub-flow A) before opening the PR — delegating to the agent when available
  and falling back to an inline check otherwise — and surfaces findings for the
  engineer to confirm rather than auto-blocking.

## [0.2.0] - 2026-06-23

### Added
- Bundled, project-agnostic review agents (`code-reviewer`, `design-reviewer`,
  `security-auditor`, `test-engineer`, and the optional self-gating
  `aws-reviewer`); wired into the `design-review`, `test`, and `review` skills
  with explicit sub-agent delegation and a documented local-override precedence.
- MIT `LICENSE` and a `license` field in the plugin manifest.
- CI workflow validating the manifests and every skill/agent frontmatter, plus a
  guard that fails a PR which changes `skills/` or `agents/` without bumping the
  plugin version (so a release never silently reaches no one).
- Release automation: on merge to `main`, tags `v<version>` and publishes a
  GitHub Release with notes drawn from this changelog, once per version.
- This changelog, `.editorconfig`, and plugin discoverability `keywords`.

## [0.1.0] - 2026-06-23

### Added
- Initial release: an opinionated Claude Code engineering workflow shipped as a
  plugin and marketplace.
- Skills: `refine`, `design`, `design-review`, `plan`, `implement`, `test`,
  `review`, `resolve-pr-comments`.
- Project-agnostic skill logic that reads stack and standards from each
  project's own `CLAUDE.md`.

[Unreleased]: https://github.com/udalovas/tars/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/udalovas/tars/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/udalovas/tars/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/udalovas/tars/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/udalovas/tars/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/udalovas/tars/releases/tag/v0.1.0
