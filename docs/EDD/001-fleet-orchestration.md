# EDD-001: Fleet-Orchestration Mode for TARS Skills

| Field | Value |
|---|---|
| Status | Draft |
| Author | Aleksei Udalov |
| Created | 2026-07-23 |
| Supersedes | — |

## Overview

Enable **one engineer to orchestrate 5–10 Claude agents in parallel** — each isolated
in its own git worktree — where Claude **self-verifies** every stream (tests, build,
lint, automated code review) *before* the engineer sees anything. The engineer's role
shifts from keystroke author to **reviewer of final diffs**, so a backlog that used to
take the team weeks can become one engineer's afternoon of orchestration.

This is delivered by **modifying the existing `/implement`, `/test`, and `/review`
skills** plus a **new onboarding document** — no new skill, no new runtime. Orchestration
is a *documented pattern* that composes behavior the skills already have.

## Requirements

**Problem:** TARS's SDLC skills assume a single linear work-stream, so an engineer can't
safely run many Claude agents in parallel with each agent self-verifying its work before
the human reviews only the final diff.

**Success criteria:**
- A fresh consuming project, following the onboarding doc **only** (no edits to TARS),
  can enable end-to-end: git-worktree isolation + auto mode + the self-check gate.
- `/implement`, `/test`, `/review` each operate correctly inside a worktree-isolated
  stream and assume auto mode as the default posture.
- No diff is surfaced for human review until tests + build + lint + `code-reviewer` all
  pass — or the skill reports precisely why a gate check could not run. `security-auditor`
  remains **opt-in**.
- One engineer can sustain **≥5 concurrent worktree streams**, jump between them, and
  review only final diffs (demonstrated once on TARS's own backlog).
- Backward compatible: single-stream usage still works; skills degrade gracefully on a
  clean machine (no worktrees, no bundled agents → inline fallback).
- Each stream has **one human-readable slug** reused across its worktree directory,
  branch, and Claude session label, so `git worktree list` and the session list are
  trivially differentiable.
- `python3 scripts/validate.py` passes; `plugin.json` version bumped + `CHANGELOG.md`
  entry.

**Out of scope:**
- A dedicated `/orchestrate` skill or fleet-tracking UI/dashboard.
- Changing the Claude Code harness or auto-mode itself (assume it, don't build it).
- Enabling `security-auditor` by default.
- Worktree lifecycle management beyond the bootstrap helper (project owns cleanup/merge).
- Changes to `/refine`, `/design`, `/design-review`, `/plan`, `/resolve-pr-comments`,
  `/retro` beyond a trivial cross-reference.

## Design

### Approach

Chosen approach: **thin skill hooks + one canonical orchestration/onboarding doc.**
`docs/ORCHESTRATION.md` is the single source of truth (workflow, conventions, setup, gate
definition, onboarding checklist, copy-paste helper). Each skill gains a compact
"Orchestration mode" section that references it. The gate is *enforced* in `/implement`.

Rejected alternatives:
- **Fully inline per skill** — duplicates worktree/gate conventions across three skills
  (drift risk) and scatters onboarding.
- **Reference bundled under `/implement`, others link to it** — cross-skill file
  references are fragile once installed as a plugin; awkward ownership.

### Architecture

No new skill and no runtime. Everything composes around one concept — the **stream**: a
single unit of parallel work the orchestrator dispatches and later reviews.

```
Orchestrator (1 engineer, auto mode)
   │  dispatches 5–10 streams, jumps between them
   ▼
┌── stream: <slug> ──────────────────────────────────────────┐
│  worktree ../repo-worktrees/<slug>  ·  branch <type>/<slug>  │
│                                                              │
│  /implement  ── task loop (implement → /test → commit)       │
│        │                                                     │
│        ▼  all tasks done                                     │
│  ┌── SELF-CHECK GATE (owned by /implement) ───────────────┐  │
│  │  tests · build · lint  →  code-reviewer (bare name)     │  │
│  │  Critical? → auto-fix & re-gate (max 2) → else escalate │  │
│  └─────────────────────────────────────────────────────────┘  │
│        │  gate GREEN                                         │
│        ▼                                                     │
│  "Stream <slug> ready for review" → /review (PR)             │
└──────────────────────────────────────────────────────────────┘
   ▲
Engineer reviews the FINAL DIFF per stream, not keystrokes
```

The harness session list + `git worktree list` (both keyed by the slug) *are* the tracking
surface — no orchestrator daemon, registry, or state file (YAGNI).

### The self-check gate

Owned by `/implement`, run once per stream after all tasks complete, before the stream is
surfaced.

| Step | Source | Blocks? | If it can't run |
|---|---|---|---|
| Tests | project `CLAUDE.md` command, via `/test` | Yes | Report `not run: no test command configured` |
| Build | project `CLAUDE.md` command, via `/test` | Yes | Report `not run: no build step` |
| Lint / type-check | project `CLAUDE.md` command, via `/test` | Yes | Report `not run: no lint configured` |
| `code-reviewer` | bare-name agent; **inline fallback** if absent | Critical only | Perform review inline |

Rules:
- **A check that can't run is reported, never silently passed.** "Green" = every applicable
  check passed *and* any inapplicable one is explicitly named.
- **`code-reviewer` severity → gate:** `Critical` blocks; `Important` / `Suggestions` are
  surfaced in the ready-for-review summary but don't block.
- **Bounded auto-fix loop (auto mode):** on a blocking failure, auto-fix and re-run the
  gate, **max 2 attempts** (mirrors `/implement` Rule 3 / `/test` loop). Still failing →
  escalate that stream with full context; the diff is **not** surfaced.
- **`security-auditor` is opt-in**, invoked by bare name only when the orchestrator requests
  it per stream; never in the default gate.

Ready-for-review handoff (the only routine interruption):

```
✅ Stream <slug> — gate green
   tests ✓  build ✓  lint ✓  code-reviewer ✓ (2 suggestions)
   Diff: 6 files, +180 −40  ·  branch feature/<slug>
   Review the diff, or run /review to open the PR.
   (security-auditor not run — request it per stream if needed)
```

Graceful degradation: on a clean machine with no `code-reviewer` agent and no worktrees,
`/implement` runs the gate inline and single-stream — identical behavior, just not parallel.

### Stream conventions — the slug is the single handle

One kebab-case name per stream, engineer-supplied; if omitted, auto-derived from the
ticket/task title (kebab-cased). Reused verbatim:

| Surface | Form | Example |
|---|---|---|
| Branch | `<type>/<slug>` (per `.claude/rules/git.md`) | `feature/add-docs-gate` |
| Worktree dir | `../<repo>-worktrees/<slug>` (sibling dir) | `../tars-worktrees/add-docs-gate` |
| Session label | `<slug>` | `add-docs-gate` |

Sibling worktree dir keeps the main checkout clean and needs no `.gitignore` entry.

### Per-skill changes (all additive — existing single-stream behavior untouched)

- **`/implement`** (main change) — new "Orchestration mode" section: (a) stream/worktree
  awareness (verify you're in the stream's worktree, use its slug); (b) auto-mode posture
  (proceed through the task loop without per-step confirmation); (c) **owns the self-check
  gate** as a new step after "all tasks complete," replacing "Next: run `/review`" with
  "gate → surface." Cross-references `docs/ORCHESTRATION.md`.
- **`/test`** (small) — documents that it is the tests+build+lint component of the gate and
  returns a **structured pass/fail** (which checks ran, which couldn't) so `/implement` can
  compose it. No change when run standalone.
- **`/review`** (small) — note that in orchestration mode `code-reviewer` has **already run
  in the gate**, so PR creation doesn't re-invoke it; the docs-consistency gate and PR flow
  are unchanged. Clarifies the "conducting a review" boundary rather than contradicting it.

Invariants honored: bare-name agent invocation (never `tars:code-reviewer`); inline fallback
everywhere; no stack assumptions (commands read from consuming project's `CLAUDE.md`);
version bump + CHANGELOG required.

### `docs/ORCHESTRATION.md` (onboarding + helper)

Single source of truth an adopting project reads to enable the workflow e2e:

1. **What this unlocks** — one engineer orchestrating 5–10 self-checked streams; review
   final diffs, not keystrokes.
2. **Prerequisites** — `git` ≥ 2.5 (worktrees); project `CLAUDE.md` defines test/build/lint
   commands (missing → gate reports "not run"); `code-reviewer` available (bundled default
   works; project override optional).
3. **One-time setup (copy-paste)**:
   - **Auto-mode + permissions `settings.json` snippet** for the project's
     `.claude/settings.json` — auto-accept edits, allow the project's test/build/lint
     commands, allow `git worktree`. Project-agnostic, with a "fill in your project's
     commands" marker. Never a blanket allow.
   - **Worktree bootstrap** — a short copy-paste shell function `new-stream <slug> [<type>]`
     that creates `../<repo>-worktrees/<slug>` on branch `<type>/<slug>`. Provided **inline
     as copy-paste** (plugin installs don't expose TARS's `scripts/`), and mirrored as
     `scripts/new-stream.sh` in the TARS repo for reference/dogfooding.
4. **Per-stream loop** — `new-stream` → open a Claude session labelled `<slug>` in that
   worktree → `/implement` → gate → surface → `/review`.
5. **Enable checklist** — tickable list proving the success criterion (git version, commands
   defined, permissions set, one stream dispatched, one gated diff reviewed).
6. **Degradation note** — skip worktrees/auto-mode and every skill still works single-stream.

`README` gets a short "Orchestration mode" subsection linking to this doc.

**Auto-mode posture** is expressed as *documentation + a settings snippet the adopter
applies* — TARS never changes the harness itself (out of scope); it tells you how to
configure it and the skills assume it's on.

## Testing Strategy

- **Structural:** `python3 scripts/validate.py` passes (frontmatter/name rules intact for
  the three edited skills); `bash scripts/check-version-bump.sh origin/main` passes (version
  bumped + CHANGELOG entry — this change touches `skills/`).
- **New helper:** `scripts/new-stream.sh` shellcheck-clean; a manual run creates the worktree
  + branch with the slug and fails clearly if the slug already exists.
- **Dogfood (success-criterion proof):** on TARS's own backlog, dispatch ≥5 streams via the
  documented loop; confirm each surfaces only a gate-green diff and the engineer reviews
  final diffs only. Record in `/retro`.
- **Degradation:** run `/implement` on a clean checkout with no worktree and no bundled
  `code-reviewer` → confirm single-stream inline behavior is unchanged.

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Gate logic drifts between `docs/ORCHESTRATION.md` and `/implement` | Doc is the definition; `/implement` links to it and keeps only enforcement steps — one canonical source |
| Auto mode + broad permissions runs an unsafe command unattended | Settings snippet allow-lists only the project's test/build/lint + `git worktree`; never a blanket allow. Credentials/secrets stay out of scope per org policy |
| `security-auditor` silently skipped → false sense of safety | Ready-for-review summary states security review was **not** run and how to request it per stream |
| Parallel streams touch the same files → merge conflicts | Worktrees isolate working trees; conflicts surface at PR/merge (project owns merge — out of scope), documented in the doc |
| Adopters can't run TARS's `scripts/` (plugin install) | Helper provided inline as copy-paste in the doc; repo file is reference only |
| Bounded auto-fix loop masks a real problem by retrying | Max 2 attempts, then escalate with full context — never surface a diff that didn't pass cleanly |

## Implementation Notes

- **Version:** bump `.claude-plugin/plugin.json` `0.3.0 → 0.4.0` (new feature) and add a
  matching `CHANGELOG.md` entry in the same PR (release-correctness contract).
- **Files touched:** `skills/implement/SKILL.md`, `skills/test/SKILL.md`,
  `skills/review/SKILL.md`, new `docs/ORCHESTRATION.md`, new `scripts/new-stream.sh`,
  `README.md` (link), `.claude-plugin/plugin.json`, `CHANGELOG.md`.
- **Mirror existing wording** for the bare-name / inline-fallback / override note (see
  `skills/design-review/SKILL.md`) so the three edited skills stay consistent with the rest.
- **Keep each skill self-contained enough to work on a clean machine** — the doc reference
  is convenience, not a hard dependency; the gate steps live in `/implement` itself.
```
