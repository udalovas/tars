# Changelog

All notable changes to TARS are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The plugin version lives in `.claude-plugin/plugin.json`; bump it on release so
installs pick up changes predictably.

## [Unreleased]

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

[Unreleased]: https://github.com/udalovas/tars/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/udalovas/tars/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/udalovas/tars/releases/tag/v0.1.0
