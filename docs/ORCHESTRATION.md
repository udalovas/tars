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
│  worktree .claude/worktrees/<slug>  ·  branch worktree-<slug> │
│  /implement → task loop → SELF-CHECK GATE → "ready for review" │
└────────────────────────────────────────────────────────────┘
   ▲
You review the FINAL DIFF per stream → /review opens the PR
```

Nothing new tracks your streams: `git worktree list` and the session picker (`/resume`,
`Ctrl+W` to see all worktrees) — both keyed by the slug — *are* the tracking surface.

## The slug is the single handle

Each stream gets **one kebab-case slug** (e.g. `add-docs-gate`), supplied by you or derived
from the ticket/task title. It is reused verbatim everywhere, so nothing is ambiguous when
you jump between streams:

| Surface | Form | Example |
|---|---|---|
| Claude session name | `<slug>` (via `--name`) | `add-docs-gate` |
| Worktree directory | `.claude/worktrees/<slug>` (via `--worktree`) | `.claude/worktrees/add-docs-gate` |
| Branch | `worktree-<slug>` (created by `--worktree`) | `worktree-add-docs-gate` |

You type the slug once, on the launch command; Claude Code derives the worktree and branch
from it.

## The self-check gate (canonical definition)

`/implement` runs this gate once per stream, after all tasks complete, **before** the diff
is surfaced to you. This section is the source of truth; the skills reference it.

| Step | Source | Blocks? | If it can't run |
|---|---|---|---|
| Tests | your `CLAUDE.md` command (via `/test`) | Yes | Reported: `not run: no test command configured` |
| Build | your `CLAUDE.md` command (via `/test`) | Yes | Reported: `not run: no build step` |
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
  when a change warrants a deep security/compliance pass. On regulated codebases — or any
  project where every change needs a compliance lens — make it non-optional instead: add a
  `.claude/rules/` entry (or a `CLAUDE.md` instruction) telling the gate to also run
  `security-auditor`. The default here keeps it opt-in for speed.

## Prerequisites

- `git` ≥ 2.5 (git worktrees). Add `.claude/worktrees/` to `.gitignore` so worktree checkouts
  don't show up as untracked files in your main checkout.
- Your project's `CLAUDE.md` defines the test / build / lint commands. The gate reads these;
  any that are missing are reported as "not run" rather than silently skipped.
- The `code-reviewer` agent available for automated review. The one bundled with TARS works
  out of the box; a project-local `.claude/agents/code-reviewer.md` transparently overrides
  it. If none is installed, `/implement` performs the review inline.

## One-time setup

### 1. Permissions posture for unattended streams

A stream runs the implement→gate loop unattended, so it needs a permission posture that doesn't
stop on every action. Anthropic recommends **auto mode** for exactly this: a classifier reviews
each command and blocks the risky ones — scope escalation, unknown infrastructure,
hostile-content-driven actions — while routine work proceeds. It's the best fit here and is
**more portable** than a hand-maintained allow-list, because you don't have to enumerate your
project's commands.

Launch each stream's session in auto mode:

```bash
claude --permission-mode auto      # run inside the stream's worktree
```

Add guardrails for anything the classifier shouldn't wave through (confirm keys against the
[Claude Code settings docs](https://code.claude.com/docs/en/settings) for your version):

```jsonc
// .claude/settings.json  (shared, committed)
{
  "autoMode": {
    // Plain-prose deny-list of things auto mode must never do on its own.
    "soft_deny": ["$defaults", "Never run a deploy or destructive command"]
  }
}
```

**Alternative — explicit allow-list (`acceptEdits` + rules).** If your team prefers a static,
auditable boundary over the classifier, use accept-edits plus an allow-list — but split the two
across files so you don't change the whole team's default:

- **Auto-accept edits — per user, not committed.** `defaultMode: acceptEdits` in your personal
  `.claude/settings.local.json` (git-ignored). Committing it to the shared `settings.json`
  silently flips every teammate to auto-accept, including those who never run streams.
- **Command allow-list — safe to share.** The `allow` rules can live in the committed
  `.claude/settings.json`. Allow only what the gate and worktree flow need — never a blanket
  bypass, never `bypassPermissions`.

```jsonc
// .claude/settings.local.json  (per user, git-ignored)
{ "permissions": { "defaultMode": "acceptEdits" } }
```

```jsonc
// .claude/settings.json  (shared, committed) — the command boundary
{
  "permissions": {
    // "<cmd>:*" is a trailing wildcard (valid only at the end of the rule).
    "allow": [
      "Bash(npm test:*)",       // ← replace with your project's test command
      "Bash(npm run build:*)",  // ← replace with your project's build command
      "Bash(npm run lint:*)"    // ← replace with your project's lint command
    ]
  }
}
```

Either posture: keep the boundary tight, never add credential / network / destructive commands,
and keep secrets out of settings — use your approved secrets manager, never plaintext.

### 2. (Optional) Enforce the gate deterministically with a Stop hook

The self-check gate is defined in the skills, so it is **advisory** — a stream follows it
because it is instructed to. To make it a gate a run *cannot* skip, add a
[Stop hook](https://code.claude.com/docs/en/hooks): the script runs when a turn tries to end,
and a non-zero exit keeps the turn open until the checks pass. That is the difference between a
gate you trust and one the harness enforces.

```jsonc
// .claude/settings.json
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "bash .claude/hooks/gate.sh", "timeout": 600 } ] }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# .claude/hooks/gate.sh — exit 2 (reason on stderr) to keep the turn open until the
# mechanical checks pass; exit 0 lets it end. Fill in your commands from CLAUDE.md.
set -uo pipefail
if <your test command> && <your build command> && <your lint command>; then
  exit 0
fi
echo "Self-check gate failed — fix tests/build/lint before finishing." >&2
exit 2
```

- **Exit 2 blocks and feeds stderr back to Claude** as the reason to keep working; exit 0 lets
  the turn end. Claude Code caps consecutive blocks, so keep the script fast and deterministic.
- A hook runs **scripts, not agents**, so it hardens the *mechanical* half of the gate
  (tests + build + lint). The `code-reviewer` half stays a subagent step inside `/implement`.
- This is also the natural home for a project's other must-run checks (e.g. `shellcheck`, a
  schema/manifest validator).

## Per-stream loop

For each backlog item:

1. Start a named stream — one native command creates the worktree and opens a session in it:
   ```bash
   claude --worktree <slug> --name <slug> --permission-mode auto
   ```
   Claude Code makes the worktree (`.claude/worktrees/<slug>`, branch `worktree-<slug>`) and
   labels the session `<slug>`. No custom tooling.
2. Run `/implement` (ideally with a plan from `/plan`). It runs the task loop, then the
   self-check gate, in auto mode.
3. When the gate is green, the stream surfaces one line: `✅ Stream <slug> — gate green` with
   the diff summary. That is your cue.
4. Review the final diff. Happy? Run `/review` to open the PR (`code-reviewer` already ran in
   the gate, so it isn't repeated).

Jump between streams with `/resume` (press `Ctrl+W` to widen to all worktrees) or
`claude --resume <slug>`. You are interrupted per stream only when a diff is ready or the gate
escalated something that needs your judgment.

## Enable checklist

You have orchestration mode working end to end when:

- [ ] `git --version` ≥ 2.5, and `.claude/worktrees/` is git-ignored.
- [ ] `CLAUDE.md` defines test / build / lint commands (or you accept they'll show as "not run").
- [ ] Streams launch with `claude --worktree <slug> --name <slug> --permission-mode auto` (or the `acceptEdits` + allow-list fallback in `settings.local.json` / `settings.json`).
- [ ] (Optional) A Stop hook enforces the mechanical gate so an unattended run can't skip it.
- [ ] `code-reviewer` resolves (bundled, project-local, or inline fallback confirmed).
- [ ] You dispatched ≥5 concurrent streams and reviewed at least one gate-green diff without watching keystrokes.

## Running without orchestration

Everything degrades gracefully. Skip the worktree and auto-mode setup and the skills behave
exactly as before — single stream, one branch, gate run inline. On a clean machine with no
`code-reviewer` agent, `/implement` performs the review inline. Orchestration mode is purely
additive; it takes nothing away from the linear `/refine → … → /retro` flow.

## Cost, and Anthropic's built-in alternatives

- **Mind the token cost.** Fanning out multiplies spend — each stream runs a full
  implement→gate loop, and the gate adds a `code-reviewer` pass (plus `security-auditor` when
  you request it). Anthropic measures multi-agent runs at roughly an order of magnitude more
  tokens than a single session, so point the fleet at a **high-value backlog**, not one-line
  changes.
- **This is the manual orchestration model** — you dispatch streams and review each final diff.
  It rides on Claude Code's native
  [git worktrees](https://code.claude.com/docs/en/worktrees) (`--worktree`). If you want more
  automation, Anthropic also ships
  [Agent Teams](https://code.claude.com/docs/en/agent-teams) for coordinated multi-session runs
  with a team lead, and
  [Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web) for isolated
  cloud VMs. Keeping a human on each final diff is a deliberate choice here, not a limitation —
  pick the automation level that matches how much you need to review.
