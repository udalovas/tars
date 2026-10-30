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

Decide: single PR or multiple? Move in broad strokes, not big-bang. Default to **one PR for the whole increment** (one per independently deployed unit, if the change spans several), layered by commits for review. Every PR boundary costs a CI cycle, a reviewer context switch and a deploy wait, so split only at a **hard boundary**:

- **Published contract consumed by code** — an interface definition, schema or shared package whose new symbols the implementation imports must be published before the consumer builds
- **Deploy-order dependency** — a migration, reference data or another deployable must be live in every environment before the code that depends on it
- **Post-deploy tests** — tests asserting new behaviour that only pass once an environment carries it
- **Infrastructure or delivery-pipeline changes** that ship on a separate path from the application code

Check `CLAUDE.md` / `.claude/rules/` first: a project may name its own boundaries in its own terms (which contract formats, which deploy steps, which test tiers), and those win over this generic list.

Name the boundary behind every extra PR. Size alone (files, LOC, layers) is not a boundary. An unrelated concern from a different context still gets its own PR — don't mix contexts; manage that through task and increment scoping, not by fragmenting one change. Bundle the review-heavy parts (a contract, a data model) together in the PR that goes out first, so reviewers see the important decisions early and in one place.

Tasks inside one PR may stay small (Step 5) — tasks are commits, not PRs.

State this decision explicitly, with the boundary for each extra PR.

### Step 5: Write the Task List

Each task carries the same four fields wherever it is recorded:

- **Accept:** what must be true when done
- **Verify:** exact runnable command for this project (e.g. `npm run test -w packages/<name>`, `pytest tests/x`, `go test ./pkg/...`)
- **Files:** which files will be created or changed
- **Parallel:** yes | no (whether this can run concurrently with other tasks)

These fields populate both places the plan is recorded (Step 7): the durable
`## Implementation Plan` section on the EDD, and the in-session `TodoWrite` list.

### Step 6: Confirm with Engineer

Present the task list as a summary before persisting it:

```
Implementation plan for EDD-023 (7 tasks, 1 PR):

1. [title] — [verify command] — parallel: no
2. [title] — [verify command] — parallel: yes (with 3)
3. [title] — [verify command] — parallel: yes (with 2)
...

Shall I persist this plan? (I'll then offer a clean-context handoff to `/implement`.)
```

Only persist the plan after confirmation.

### Step 7: Persist the Plan (durable)

Persist to **two** places once the engineer confirms:

1. **The EDD — durable, survives a cleared session.** Append an
   `## Implementation Plan` section to the EDD file you read in Step 1, mirroring
   how `/design-review` appends `## Design Review`. This is the artifact
   `/implement` re-reads, so it must be self-contained — everything needed to
   build without the planning conversation:

   ```markdown
   ## Implementation Plan

   | Field   | Value             |
   |---------|-------------------|
   | Planned | YYYY-MM-DD        |
   | PRs     | single / multiple — boundary per extra PR |

   ### Tasks
   1. **[title]** — parallel: no — PR: 1
      - Accept: [what must be true when done]
      - Verify: `[runnable command]`
      - Files: [files created/changed]
   2. **[title]** — parallel: yes (with 3)
      - ...
   ```

2. **`TodoWrite` — in-session progress tracking** for `/implement` to tick
   through. Same tasks, same order.

If `/plan` was run without an EDD (an ad-hoc plan), there is no file to append
to — persist to `TodoWrite` only and say so; the clean-session handoff below
does not apply.

### Step 8: Hand Off to Implementation

Planning is the last broad, tool-heavy phase; implementation is narrow and
code-heavy. Offer a clean-context handoff so design exploration isn't dragged
into coding — **advisory, never required**; continuing in this session behaves
identically:

```
Plan saved to docs/EDD/NNN-topic.md (## Implementation Plan) and the task list.

To implement in a fresh, focused context (recommended for a large plan):
  /clear   then   /implement docs/EDD/NNN-topic.md

Or just say "go" and I'll start implementing in this session.
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I know what to build, I don't need tasks" | Without tasks, it's easy to lose track mid-implementation and end up with a half-built, untestable state. |
| "I'll plan as I go" | Plans made mid-implementation are influenced by what's already built, leading to shortcuts that fit the current state rather than the intended design. |
| "The tasks are too granular" | A task that takes 20 minutes is not too granular. A task that takes 3 hours with no intermediate checkpoint is too large. |
| "Smaller PRs are easier to review" | Each extra PR costs a CI cycle, a reviewer context switch and a deploy wait. Commits give reviewers the layering; PRs follow hard boundaries. |

## Red Flags

- Tasks with no verification command
- Tasks that change more than ~5 files (split the task, not the PR)
- A PR split that names no hard boundary from Step 4 — a PR per task, per layer or per N files is over-splitting; tasks are commits
- A task list where Task 5 must be done before Task 3 (dependency graph violation)
- Starting `/implement` before the engineer has confirmed the plan
- Plan recorded only in `TodoWrite` when an EDD exists — a cleared session loses it

## Verification

- [ ] Every EDD requirement maps to at least one task
- [ ] Every task has an exact, runnable `Verify` command
- [ ] Task order respects the dependency graph
- [ ] Parallel-safe tasks are flagged
- [ ] Engineer confirmed the plan before it was persisted
- [ ] Single vs. multi-PR decision is stated, and every extra PR names its hard boundary
- [ ] Plan persisted to the EDD `## Implementation Plan` section (durable), not just TodoWrite
- [ ] Clean-context handoff offered (advisory) naming the EDD artifact
