# Orchestration Mode

**One engineer, 5–10 self-checked streams, review final diffs — not keystrokes.**

Orchestration mode lets a single engineer dispatch many Claude streams in parallel — each
isolated in its own git worktree — where Claude runs the full self-check gate (tests,
build, lint, automated code review) on every stream *before* you look at it. You review
gate-green diffs, one stream at a time, instead of babysitting keystrokes. A backlog that
used to take the team weeks can become one engineer's afternoon of orchestration.

This is not a separate skill. It is a way of running the existing skills — `/implement`,
`/test`, `/review` — that this document sets up end to end. Everything here is
**project-agnostic**: the actual test/build/lint commands are read from your project's own
`CLAUDE.md`, exactly as the skills already do.

---

## The stream

A **stream** is one unit of parallel work — one worktree, one branch, one Claude session.

```
Orchestrator (you, auto mode)
   │  dispatch 5–10 streams, jump between them
   ▼
┌── stream: <slug> ─────────────────────────────────────────┐
│  worktree ../<repo>-worktrees/<slug>  ·  branch <type>/<slug> │
│  /implement → task loop → SELF-CHECK GATE → "ready for review" │
└────────────────────────────────────────────────────────────┘
   ▲
You review the FINAL DIFF per stream → /review opens the PR
```

Nothing new tracks your streams: `git worktree list` and the Claude session switcher —
both keyed by the slug — *are* the tracking surface.

## The slug is the single handle

Each stream gets **one kebab-case slug** (e.g. `add-docs-gate`), supplied by you or derived
from the ticket/task title. It is reused verbatim everywhere, so nothing is ambiguous when
you jump between streams:

| Surface | Form | Example |
|---|---|---|
| Branch | `<type>/<slug>` (per your git conventions) | `feature/add-docs-gate` |
| Worktree directory | `../<repo>-worktrees/<slug>` | `../tars-worktrees/add-docs-gate` |
| Claude session label | `<slug>` | `add-docs-gate` |

## The self-check gate (canonical definition)

`/implement` runs this gate once per stream, after all tasks complete, **before** the diff
is surfaced to you. This section is the source of truth; the skills reference it.

| Step | Source | Blocks? | If it can't run |
|---|---|---|---|
| Tests | your `CLAUDE.md` command (via `/test`) | Yes | Reported: `not run: no test command configured` |
| Build | your `CLAUDE.md` command | Yes | Reported: `not run: no build step` |
| Lint / type-check | your `CLAUDE.md` command (via `/test`) | Yes | Reported: `not run: no lint configured` |
| `code-reviewer` | bare-name agent (inline fallback if absent) | Critical only | Review performed inline |

Rules:

- **A check that cannot run is reported, never silently passed.** "Gate green" means every
  applicable check passed *and* any inapplicable one is named explicitly.
- **`code-reviewer` severity maps to the gate:** `Critical` blocks; `Important` and
  `Suggestions` are surfaced in the ready-for-review summary but do not block.
- **Bounded auto-fix:** on a blocking failure, the stream auto-fixes and re-runs the gate up
  to **2 attempts**, then escalates with full context. A diff that did not pass cleanly is
  never surfaced as ready.
- **`security-auditor` is opt-in.** It is not part of the default gate. Request it per stream
  when a change warrants a deep security/compliance pass.

## Prerequisites

- `git` ≥ 2.5 (git worktrees).
- Your project's `CLAUDE.md` defines the test / build / lint commands. The gate reads these;
  any that are missing are reported as "not run" rather than silently skipped.
- The `code-reviewer` agent available for automated review. The one bundled with TARS works
  out of the box; a project-local `.claude/agents/code-reviewer.md` transparently overrides
  it. If none is installed, `/implement` performs the review inline.

## One-time setup

### 1. Permissions & auto-accept — `.claude/settings.json`

Auto mode is what lets a stream run the implement→gate loop unattended. Configure it in the
project's `.claude/settings.json`: default to accepting edits, and **allow-list only the
specific commands the gate runs** — never a blanket bypass.

> This is a template. Replace the example `Bash(...)` rules with your project's real
> test / build / lint commands, and confirm the keys against the
> [Claude Code settings docs](https://docs.anthropic.com/en/docs/claude-code/settings) for
> your version.

```jsonc
{
  "permissions": {
    // Auto-accept file edits so streams don't pause on every write.
    "defaultMode": "acceptEdits",
    // Pre-approve ONLY the commands the gate and worktree flow need.
    // "<cmd>:*" is a trailing wildcard (valid only at the end of the rule):
    // "Bash(git worktree:*)" matches "git worktree add", "... remove", etc.
    "allow": [
      "Bash(git worktree:*)",
      "Bash(npm test:*)",       // ← replace with your project's test command
      "Bash(npm run build:*)",  // ← replace with your project's build command
      "Bash(npm run lint:*)"    // ← replace with your project's lint command
    ]
  }
}
```

Keep the allow-list tight: it is the safety boundary that makes unattended runs safe. Do not
add credential, network, or destructive commands. Secrets and credentials stay out of scope
— use your approved secrets manager, never plaintext in settings.

### 2. The `new-stream` helper

Each stream needs its own worktree. Paste this shell function into your shell profile
(`~/.zshrc` / `~/.bashrc`) — it needs nothing from TARS on your path:

```bash
# new-stream <slug> [<type>] — create an isolated worktree for one stream.
new-stream() {
  local slug="${1:?usage: new-stream <slug> [<type>]}" type="${2:-feature}"
  case "$slug" in *[!a-z0-9-]*|-*|*-) echo "slug must be kebab-case" >&2; return 1;; esac
  local root repo worktree branch base
  root="$(git rev-parse --show-toplevel)" || return 1
  repo="$(basename "$root")"
  worktree="$(dirname "$root")/${repo}-worktrees/${slug}"
  branch="${type}/${slug}"
  [ -e "$worktree" ] && { echo "worktree exists: $worktree" >&2; return 1; }
  git show-ref --quiet --verify "refs/heads/${branch}" && { echo "branch exists: $branch" >&2; return 1; }
  base="HEAD"; git symbolic-ref --quiet refs/remotes/origin/HEAD >/dev/null 2>&1 && \
    base="$(git symbolic-ref --short refs/remotes/origin/HEAD)"
  git worktree add -b "$branch" "$worktree" "$base"
}
```

> The TARS repo mirrors this as [`scripts/new-stream.sh`](../scripts/new-stream.sh) for
> reference and for dogfooding TARS itself. Adopting projects don't get TARS's `scripts/` on
> their path (plugins install skills, not scripts), so the copy-paste function above is the
> supported form.

## Per-stream loop

For each backlog item:

1. `new-stream <slug>` — creates `../<repo>-worktrees/<slug>` on `feature/<slug>`.
2. Open a Claude session **in that worktree directory** and label it `<slug>`.
3. Run `/implement` (with a plan from `/plan`, ideally). It runs the task loop, then the
   self-check gate, in auto mode.
4. When the gate is green, the stream surfaces one line: `✅ Stream <slug> — gate green`
   with the diff summary. That is your cue.
5. Review the final diff. Happy? Run `/review` to open the PR (`code-reviewer` already ran in
   the gate, so it isn't repeated).

Repeat across 5–10 streams, jumping between sessions. You are interrupted per stream only
when a diff is ready or the gate escalated something that needs your judgment.

## Enable checklist

You have orchestration mode working end to end when:

- [ ] `git --version` ≥ 2.5.
- [ ] `CLAUDE.md` defines test / build / lint commands (or you accept they'll show as "not run").
- [ ] `.claude/settings.json` sets `acceptEdits` and allow-lists your verification commands + `git worktree`.
- [ ] `new-stream` is on your path and creates a worktree + branch from a slug.
- [ ] `code-reviewer` resolves (bundled, project-local, or inline fallback confirmed).
- [ ] You dispatched ≥5 concurrent streams and reviewed at least one gate-green diff without watching keystrokes.

## Running without orchestration

Everything degrades gracefully. Skip the worktree and auto-mode setup and the skills behave
exactly as before — single stream, one branch, gate run inline. On a clean machine with no
`code-reviewer` agent, `/implement` performs the review inline. Orchestration mode is purely
additive; it takes nothing away from the linear `/refine → … → /retro` flow.
