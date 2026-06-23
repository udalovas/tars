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
