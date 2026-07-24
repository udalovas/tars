---
name: test
description: Runs the test suite, auto-fixes mechanical failures, and escalates failures that require judgment. Use when running tests, debugging test failures, checking if tests pass, or verifying a change. Trigger phrases: "run tests", "run integration tests", "test the API", "check if tests pass", "verify handler logic", "debug test failures", "/test".
---

# Smart Test Runner

Run the test suite. Auto-fix what can be fixed without judgment. Escalate the rest to the engineer with enough context to act immediately.

## When to Use

- After every `/implement` increment before committing
- When debugging a test failure
- To verify a change didn't break existing behavior
- When the CI pipeline reports test failures

## Test Infrastructure

**Always check `CLAUDE.md` first for the project's actual test, build, lint, and type-check commands** — they vary by stack. Use whatever the project defines; the commands below are only illustrative examples for a Node/npm workspace.

```bash
# Full suite            (e.g. npm test · pytest · go test ./... · cargo test)
npm test

# Single package/module (e.g. monorepo workspace, or a single test file/path)
npm run test -w packages/<package-name>

# Type checking only    (e.g. npm run test:tsc · mypy · tsc --noEmit)
npm run test:tsc

# Build, when the project defines one (e.g. npm run build · tsc -b · go build ./... · cargo build)
npm run build
```

A **build** step is part of verification when the project defines one — run it alongside tests and lint, and report it the same way. Build failures are escalated, not auto-fixed (they need a code change, not a mechanical one).

If the project uses local infrastructure (databases, queues, servers), the test command often starts it via a pre-test hook. If you suspect infrastructure issues, see the Troubleshooting section.

## Decision Tree

```
Run the project's test command (full or scoped)
        │
   Parse results
        │
  ┌─────┴─────────────────────────────────┐
PASS                                    FAIL
  │                                       │
Report ✓                       Categorize each failure
                                          │
                       ┌──────────────────┴──────────────────┐
                  AUTO-FIX                              ESCALATE
            (no judgment needed)                  (judgment needed)
                       │                                    │
        ├── Lint/format errors               Report with full context:
        ├── Outdated/missing snapshots         - Test file:line
        ├── TS import path errors after        - Exact error message
        │   symbol rename                      - Why auto-fix not applied
        └── Missing imports (clear fix)        - Suggested next step
                       │
              Apply fixes
                       │
              Re-run tests
                       │
         ┌─────────────┴──────────────┐
       PASS                  FAIL (2nd attempt)
         │                             │
       Report ✓              ESCALATE (could not auto-fix)
```

## Auto-Fix Rules

**Apply automatically (no confirmation needed):**
- Lint and format errors: run the project's auto-fix command (check `CLAUDE.md`; e.g. `npm run fix`, `ruff --fix`, `gofmt -w`)
- Outdated snapshots: re-run with the appropriate update flag
- Import errors caused by a renamed symbol where the new name is unambiguous
- Missing imports where there is exactly one candidate in the codebase

**Never auto-fix (always escalate):**
- Test failures that require understanding of business logic
- Assertion failures (the code's behavior changed — that needs a decision)
- Performance regressions
- Security test failures
- Any failure that persists after 2 auto-fix attempts

## Escalation Format

When escalating, give the engineer everything needed to act without re-running:

```
Tests failing — human judgment needed:

❌ packages/<package-name>
   src/service.test.ts:47
   AssertionError: Expected result to equal "foo", got "bar"
   
   Context: Testing idempotency guard in processItem()
   Auto-fix not applied: assertion failure — business logic decision required
   
   Suggested next step: Review idempotency logic in src/service.ts:89
```

Always include: file + line, exact error, why auto-fix was not applied, and a suggested next step.

## Coverage Gap Detection

When running tests on a module with **no existing tests**, propose a test strategy before reporting success. **Delegate this to the `test-engineer` sub-agent whenever it's available** — invoke it by bare name (Agent tool / `subagent_type: "test-engineer"`); running it as a sub-agent keeps the coverage analysis focused and out of this run's context. If no such agent is available, do the coverage-gap analysis inline.

Because the agent is referenced by bare name, a project's own `.claude/agents/test-engineer.md` is used in preference to the bundled default — never pin the plugin-namespaced form or overwrite a project-local agent.

```
⚠️ No tests found for <path/to/new-module>
   Proposing coverage before marking this complete...
```

Do not treat "no tests, no failures" as a pass for newly written code.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Infrastructure connection refused | Check `CLAUDE.md` for the prestart command to bring up local infrastructure |
| Test hangs indefinitely | Local infrastructure may be stuck — stop and restart it |
| Tests fail from package directory but pass from root | Infrastructure hooks often run only at the repo root — run the workspace-scoped test command from root (e.g. `npm run test -w <package>`) |
| Type errors after code-gen change | Re-run the code generation step (see `CLAUDE.md`), then re-run tests |
| Port in use | Check `CLAUDE.md` for the stop command to kill local dev processes |

## Orchestration Mode

When `/implement` runs as a parallel worktree stream, `/test` is the
**tests + build + lint component of the self-check gate** that runs before a diff is
surfaced (see the `implement` skill's Orchestration Mode). Two things matter when invoked as a gate component:

- **Return a structured pass/fail**, not just a log, so `/implement` can compose the result.
  Report each check as `pass`, `fail`, or `not run` **with the reason** (e.g. the project
  defines no build step in `CLAUDE.md`). A check that can't run is reported as **not run —
  never silently treated as a pass.**
- **Auto-fix stays bounded** exactly as above — mechanical fixes only, max 2 attempts, then
  escalate. `/test` reports the result; whether to surface the diff is the caller's decision.

Standalone behavior is unchanged: run directly, `/test` reports and auto-fixes as described
above. Example structured result:

```
gate: tests pass ✓ · lint pass ✓ · build not run (no build step defined in CLAUDE.md)
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The tests pass on my machine" | Run tests the way CI runs them (from root, with infrastructure hooks) — local shortcuts skip setup. |
| "It's just a lint error, I'll fix it later" | Auto-fix takes 2 seconds. "Later" becomes a PR comment. |
| "No tests exist so there's nothing to fix" | Newly written code with no tests is not verified. The `test-engineer` persona should be invoked. |

## Red Flags

- Marking a build complete without running tests
- Committing with known failing tests ("I'll fix them in the next commit")
- Skipping type checking because "runtime tests are enough"
- Running tests from a package directory instead of the monorepo root (when infrastructure hooks live at root)

## Verification

- [ ] Tests run from the correct location (monorepo root if infrastructure hooks are there)
- [ ] All lint errors auto-fixed before escalating test failures
- [ ] Escalated failures include file:line, error text, and suggested next step
- [ ] Newly written modules without tests trigger a coverage gap analysis
- [ ] Type checking passes (not just runtime tests)
- [ ] As a gate component: result reported as structured pass/fail per check, with any check that couldn't run marked "not run"
