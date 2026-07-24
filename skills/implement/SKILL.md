---
name: implement
description: Implements features incrementally from a task list, one vertical slice at a time. Each slice is: implement → test → commit. Use when executing a planned task list from /plan, or when implementing any multi-file change. Trigger phrases: "start building", "implement this", "build the feature", "/implement".
---

# Incremental Implementation

Implement one task at a time. Each task ends with passing tests and a commit. Never accumulate more than one task's worth of uncommitted changes.

## When to Use

- Executing a task list produced by `/plan`
- Implementing any change that touches more than one file
- Any time you're about to write more than ~100 lines before testing

**When NOT to use:** Single-file, single-function changes where the full scope is obvious and fits in one edit.

## Pre-flight

If invoked without a task list from `/plan`:

```
⚠️ No implementation plan found — consider running `/plan docs/EDD/XXX.md`
   first for better results. Continuing without a plan.
```

Then ask: "What are we building?" Establish a minimal task list before proceeding.

## The Increment Cycle

```
Pick next task (TodoWrite)
        │
  Load context:
  - Task's file list
  - Relevant EDD section
  - Existing patterns in similar files
        │
  Implement the slice
  (smallest complete piece of functionality)
        │
  Run verification command from task
        │
  ┌─────┴──────────────┐
PASS                 FAIL
  │                    │
Mark complete        Invoke `test` skill auto-fix loop
Commit               (max 2 attempts, then escalate)
  │
Next task
```

## Implementation Rules

### Rule 0: Read Before Writing

Before touching any file, read:
1. The existing file (if modifying) — understand what's already there
2. The most similar existing implementation in the codebase — reuse patterns
3. The relevant EDD section — understand the *why* behind this task

### Rule 1: Simplest Thing First

Before writing code, ask: "What is the simplest implementation that satisfies the acceptance criteria?"

After writing, check:
- Can this be done in fewer lines?
- Am I building for a hypothetical future requirement not in the EDD?
- Would a staff engineer look at this and say "why didn't you just..."?

### Rule 2: One Task, One Commit

Complete one task fully before starting the next:
- Tests pass
- Type checking passes
- No lint errors
- Commit with a structured message

**Commit message format:**
```
feat(scope): [task title]

Implements EDD-XXX task N: [what this slice delivers]
Verify: [command used]
```

### Rule 3: Never Break the Build

If the verification command fails:
1. Invoke the `test` skill to attempt auto-fix
2. If still failing after 2 attempts, surface to engineer with full context — do not commit

### Rule 4: Follow Project Standards

Before each task, read the project's coding standards (see `CLAUDE.md`, and any rules it references such as a `.claude/rules/` directory) for the conventions that apply to the code being written. Apply them — don't wait for a review comment.

## Handling Blocked Tasks

If a task cannot be completed:

1. State specifically what is blocking (missing dependency, unclear requirement, failing test after 2 attempts)
2. Do not skip to the next task
3. Ask the engineer for direction

## Finishing Up

After all tasks are marked complete:

```
All tasks complete. ✓

Summary:
- [N] tasks implemented
- [N] files changed
- Tests passing ✓
- Type check passing ✓

Next: run `/review` to create the PR.
```

> In **orchestration mode** (parallel worktree streams), the finish is the self-check gate
> instead of this handoff — see [Orchestration Mode](#orchestration-mode) below.

## Orchestration Mode

`/implement` can run as one **stream** in a fleet an engineer orchestrates in parallel — each
stream in its own git worktree, on its own branch, driven from its own Claude session, all
keyed by a single readable **slug**. This lets one engineer keep 5–10 streams moving and
review final diffs instead of keystrokes. One-time project setup (worktrees, auto-mode
permissions) and the full fleet model live in the orchestration guide that ships with TARS
(`docs/ORCHESTRATION.md`); the pointer is soft — everything this skill needs is below.

When running as a worktree stream, three things change:

- **Stay in the stream's worktree.** Use the stream's slug for the branch (`<type>/<slug>`)
  and for commits; never touch another stream's worktree.
- **Auto-mode posture.** Proceed through the increment cycle without pausing for per-step
  confirmation. You still stop on a genuinely blocked task (see [Handling Blocked
  Tasks](#handling-blocked-tasks)) — auto mode speeds the routine, it doesn't suppress
  escalation.
- **The finish is the self-check gate**, not the "run `/review`" handoff.

### The self-check gate

After all tasks are complete, run this in order (fail-fast) **before surfacing anything** to
the engineer:

1. **Tests + build + lint** — via the `test` skill, which reads the project's actual
   commands from `CLAUDE.md`. Any command the project doesn't define is **reported as "not
   run", never silently passed.**
2. **`code-reviewer`** on the cumulative stream diff. Invoke it by **bare name** (Agent tool
   / `subagent_type: "code-reviewer"`) so a project-local `.claude/agents/code-reviewer.md`
   overrides the bundled default — never pin the plugin-namespaced form, never overwrite a
   project-local agent. **If no such agent is available, perform the code review inline** —
   the gate must work on a clean machine with no bundled agents.

Severity → gate: a `code-reviewer` **Critical** finding blocks; **Important** and
**Suggestions** are surfaced in the handoff but do not block.

**On a blocking failure** (a required check failed, or a Critical finding): auto-fix and
re-run the whole gate, **max 2 attempts** (mirrors [Rule 3](#rule-3-never-break-the-build)).
Still failing → escalate that stream with full context and **do not surface the diff**.

`security-auditor` is **not** in the gate — it is opt-in. Invoke it (by bare name) only when
the engineer requests a security/compliance pass for the stream.

### Ready-for-review handoff

When the gate is green, surface exactly one summary — the engineer's cue to review the final
diff:

```
✅ Stream <slug> — gate green
   tests ✓  lint ✓  build not run (none defined)  code-reviewer ✓ (N suggestions)
   Diff: <N> files, +<add> −<del>  ·  branch <type>/<slug>
   Review the diff, or run /review to open the PR.
   (security-auditor not run — request it if this stream needs a security pass)
```

**Graceful degradation:** with no worktree and no bundled `code-reviewer`, `/implement` runs
exactly as the linear flow above — the gate still runs (tests+build+lint via `/test`, code
review performed inline), single-stream, and the standard [Finishing Up](#finishing-up)
handoff applies.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll commit everything at the end" | Uncommitted work is lost work. Each task is a save point. |
| "I'll fix the tests after I finish the feature" | Tests written after the feature describe what the code does, not what it should do. Fix now. |
| "This task is simple, I don't need to read the existing code" | Existing code has patterns, helpers, and constraints invisible from a description alone. Read it. |
| "I'll add error handling in a follow-up" | Error handling that isn't in the task is a missing acceptance criterion. Add it to the task or open a new one. |

## Red Flags

- More than one task's worth of changes uncommitted
- Committing with the test command skipped
- Implementing features not in the task list (scope creep)
- Patterns explicitly banned by the project's standards (e.g. `any` types or stray debug logging in a TS project)
- Starting the next task before the current one's verification command passes
- Surfacing a stream's diff as ready when the self-check gate did not pass cleanly (orchestration mode)

## Verification

After each task:
- [ ] Verification command from the task passes
- [ ] Type checking passes
- [ ] No lint errors
- [ ] Task marked complete in TodoWrite
- [ ] Commit created with EDD reference

After all tasks:
- [ ] All TodoWrite tasks marked complete
- [ ] Full test suite passes
- [ ] Engineer prompted to run `/review`
- [ ] Orchestration mode: self-check gate green (tests+build+lint+`code-reviewer`, or checks that couldn't run reported) before the diff was surfaced; `security-auditor` noted as not run
