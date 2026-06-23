---
name: test
description: Runs the test suite, auto-fixes mechanical failures, and escalates failures that require judgment. Supersedes the integration-tests skill. Use when running tests, debugging test failures, checking if tests pass, or verifying a change. Trigger phrases: "run tests", "run integration tests", "test the API", "check if tests pass", "verify handler logic", "debug test failures", "/test".
---

# Smart Test Runner

Run the test suite. Auto-fix what can be fixed without judgment. Escalate the rest to the engineer with enough context to act immediately.

## When to Use

- After every `/implement` increment before committing
- When debugging a test failure
- To verify a change didn't break existing behavior
- When the CI pipeline reports test failures

**Supersedes `integration-tests`** — all previous trigger phrases now activate this skill.

## Test Infrastructure

Check `CLAUDE.md` for project-specific test commands and infrastructure setup. Common patterns:

```bash
# Full suite
npm test

# Single package (if monorepo with workspaces)
npm run test -w packages/<package-name>

# Type checking only
npm run test:tsc
```

If the project uses local infrastructure (databases, queues, servers), `npm test` typically starts it via `pretest` hooks. If you suspect infrastructure issues, see the Troubleshooting section.

## Decision Tree

```
Run tests (npm test or scoped variant)
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
- Lint and format errors: `npm run fix` (or the project's equivalent)
- Outdated snapshots: re-run with the appropriate update flag
- TypeScript import errors caused by a renamed symbol where the new name is unambiguous
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

When running tests on a module with **no existing tests**, invoke the `test-engineer` persona to propose a test strategy before reporting success:

```
⚠️ No tests found for packages/new-service/src/handlers/my-handler.ts
   Invoking test-engineer to recommend coverage...
```

Do not treat "no tests, no failures" as a pass for newly written code.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Infrastructure connection refused | Check `CLAUDE.md` for the prestart command to bring up local infrastructure |
| Test hangs indefinitely | Local infrastructure may be stuck — stop and restart it |
| Tests fail from package directory but pass from root | Infrastructure hooks only run at root — always use `npm run test -w <package>` from root |
| Type errors after code-gen change | Re-run the code generation step (see `CLAUDE.md`), then re-run tests |
| Port in use | Check `CLAUDE.md` for the stop command to kill local dev processes |

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
- [ ] Newly written modules without tests trigger `test-engineer` coverage gap analysis
- [ ] Type checking passes (not just runtime tests)
