---
name: plan
description: Decomposes an approved EDD into an ordered, verifiable task list. Use when you have an EDD and need to break it into implementable tasks before starting /implement. Trigger phrases: "create an implementation plan", "break this down into tasks", "plan the implementation", "/plan".
---

# Implementation Plan

Decompose an EDD into small, ordered, verifiable tasks. Good task breakdown is the difference between an agent that ships reliably and one that gets lost halfway through.

## When to Use

- After `/design` or `/design-review` — you have an approved (or acknowledged) EDD
- A feature feels too large to start without a map
- You need to identify what can be built in parallel vs. what must be sequential
- Before `/implement` on any change touching more than one file

**When NOT to use:** Single-file changes with obvious scope. If you can describe the entire change in one sentence, just do it.

## The Process

### Step 1: Read the EDD

Read the EDD file from the path the user provided. If no path provided, list recent design docs from the project's EDD directory (`docs/EDD/` by convention — check `CLAUDE.md`):
```bash
ls docs/EDD/ | grep -E '^[0-9]+' | sort -n | tail -5
```
Ask which EDD to plan.

Check for a `## Design Review` section — note any non-blocking issues that should be addressed during implementation.

### Step 2: Map the Dependency Graph

Identify what must exist before what can be built. Read `CLAUDE.md` for the project's specific layers; a typical pattern:

```
Schema / spec definition
    └── Generated types / contracts
            └── Data access layer
                    └── Service layer
                            └── Handler / controller
                                    └── Infrastructure update
                                            └── Tests
```

Build sequentially from the bottom. Do not design tasks that violate this order.

### Step 3: Slice Vertically

Group work into thin vertical slices — each slice delivers working, testable functionality end-to-end, not just a horizontal layer.

**Bad (horizontal):**
```
Task 1: All data-model entities
Task 2: All service functions
Task 3: All request handlers
Task 4: All infrastructure changes
Task 5: All tests
```

**Good (vertical):**
```
Task 1: Create data layer + service + handler for operation A — tests pass
Task 2: Add operation B end-to-end — tests pass
Task 3: Infrastructure update — validation passes
```

Each vertical slice leaves the codebase in a passing, committable state.

### Step 4: Size the Change

Decide: single PR or multiple?

- **Single PR** if total change is under ~500 LOC or stays within one service boundary
- **Multiple PRs** if the change crosses service boundaries or requires an infrastructure deployment between steps

State this decision explicitly.

### Step 5: Write Tasks via TodoWrite

Create tasks using `TodoWrite`. Each task must have:

```
content:     [imperative description: "Create OrderItem data entity and service"]
activeForm:  [present continuous: "Creating OrderItem data entity and service"]
status:      pending
```

Include in the task content:
- **Accept:** what must be true when done
- **Verify:** exact runnable command for this project (e.g. `npm run test -w packages/<name>`, `pytest tests/x`, `go test ./pkg/...`)
- **Files:** which files will be created or changed
- **Parallel:** yes | no (whether this can run concurrently with other tasks)

### Step 6: Confirm with Engineer

Present the task list as a summary before writing to TodoWrite:

```
Implementation plan for EDD-023 (7 tasks, 1 PR):

1. [title] — [verify command] — parallel: no
2. [title] — [verify command] — parallel: yes (with 3)
3. [title] — [verify command] — parallel: yes (with 2)
...

Shall I write this to the task list and start with `/implement`?
```

Only write to TodoWrite after confirmation.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I know what to build, I don't need tasks" | Without tasks, it's easy to lose track mid-implementation and end up with a half-built, untestable state. |
| "I'll plan as I go" | Plans made mid-implementation are influenced by what's already built, leading to shortcuts that fit the current state rather than the intended design. |
| "The tasks are too granular" | A task that takes 20 minutes is not too granular. A task that takes 3 hours with no intermediate checkpoint is too large. |

## Red Flags

- Tasks with no verification command
- Tasks that change more than ~5 files (split them)
- A task list where Task 5 must be done before Task 3 (dependency graph violation)
- Starting `/implement` before the engineer has confirmed the plan

## Verification

- [ ] Every EDD requirement maps to at least one task
- [ ] Every task has an exact, runnable `Verify` command
- [ ] Task order respects the dependency graph
- [ ] Parallel-safe tasks are flagged
- [ ] Engineer confirmed the plan before TodoWrite was called
- [ ] Single vs. multi-PR decision is stated
