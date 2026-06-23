# EDD Templates and Patterns

Stack-neutral templates and patterns for Engineering Design Documents. Use these as guides when creating new EDDs. Anything stack-specific (languages, frameworks, infra) should come from the **host project's** `CLAUDE.md` and existing EDDs — adapt the examples below to match.

## Standard EDD Template

```markdown
# EDD-{NUMBER}: {Feature Name}

**File**: `docs/EDD/{NUMBER}-{kebab-case-name}.md` (sequential number; `docs/EDD/` is a convention — check CLAUDE.md)
**Created**: {YYYY-MM-DD}
**Status**: 🚧 In Progress | ✅ Complete | 🔄 In Review
**Last Updated**: {YYYY-MM-DD}
**Type**: {project-appropriate, e.g. Frontend | Backend | Full-Stack | Infrastructure | Library}

## SUMMARY

{2-4 sentences explaining what will be built and why. Focus on WHAT will happen.}

## VALUE

{Why this is worth doing now, and the concrete cost of NOT doing it. Carried over from /refine if available.}

## TECHNICAL SPECIFICATIONS

### Affected Files

**CREATE / MODIFY / DELETE:**
- `{relative/path/to/file}` - {Description}

### Architecture & Design

Describe the design in the project's own terms. Cover the elements that apply:

- **Entry points / interfaces** — APIs, commands, events, or UI surfaces this exposes or changes. Include operation name, method/route or signature, request/response shape.
- **Core logic / components** — the modules or services involved and their responsibilities.
- **Data model** — entities, keys/indexes, or schema changes (if any).
- **Integration points** — external systems or internal services called.

### Trade-Off Analysis (required for major decisions)

For each decision with a **high cost of change later** (data model, public API/contract, persistence or messaging technology, service boundaries, sync vs async, build vs buy, security model), document:

| Decision | Chosen approach | Alternatives considered | Why rejected (trade-off) |
|----------|-----------------|-------------------------|--------------------------|
| {e.g. persistence} | {chosen} | {alt A, alt B} | {what was gained / given up} |

Reversible, low-cost-of-change decisions do not need this. This section is what `/design-review` checks for.

### Dependencies & Prerequisites

- **New packages / tools** (if any) — and why
- **Environment variables / config** (if any)
- **Standards to follow** — point at the project's coding standards (see `CLAUDE.md`)

## IMPLEMENTATION PHASES

### Phase 1: {Phase Name}

**Objective**: {What this phase achieves}
**Can Execute in Parallel**: ❌ No | ✅ Yes — {reason}

**Tasks**:
- [ ] {Specific, actionable task}
  - File: `{relative/path/to/file}`
  - Notes: {Implementation details}

**Validation**:
- [ ] {Validation step}
- [ ] Type-check / lint passes (use the project's commands — see CLAUDE.md)

## TESTING & VALIDATION

- [ ] Automated tests pass (the project's test command)
- [ ] Auto-fix/format applied
- [ ] Manual testing checklist:
  - [ ] {Test case}
- [ ] Infrastructure/deploy validation, if applicable (e.g. an infra dry-run / synth / plan)

## RISKS & MITIGATIONS

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| {Risk description} | High/Medium/Low | High/Medium/Low | {How we address it} |

## IMPLEMENTATION NOTES

### Deployment / Rollout Order
1. {Step}

### Rollback Plan
1. {Step}

### Monitoring
- {Metrics/alerts and where they go}

## OPEN QUESTIONS

- [ ] {Question that needs answering before/during implementation}

## REFERENCES

- Project standards & overview: `CLAUDE.md` (and any rules it references)
- Related EDDs / ADRs / RFCs: {links}
- External docs: {links}
```

## Pattern: Small Change to an Existing Component

For adding a feature to an existing handler/module, a minimal EDD is enough:

```markdown
# EDD-{NUMBER}: {Feature Name}

## Overview
{What this adds to the existing component}

## Value
{Why now; cost of not doing it}

## Requirements
- Extend {component} to handle {new case}
- {Downstream effect}
- Handle {error scenarios}

## Design
### Changes
- {Concrete change 1}
- {Concrete change 2 — note if no schema/contract change is needed}

### Data Flow
[Simple numbered list — no complex diagrams needed]

## Testing Strategy
- Unit: {component handles {case} correctly}
- Integration: end-to-end flow for {case}
- Manual: trigger {source}, verify {outcome}

## Risks
- Low risk — follows existing patterns. Reuse existing error handling/monitoring.
```

## Pattern: New Infrastructure / Major Component

For new infrastructure or a new service, be more comprehensive: include an architecture diagram (Mermaid is fine), the **Trade-Off Analysis** table, resource configuration with rationale, a deployment order, and a rollback plan. Express infrastructure in whatever the project actually uses (IaC tool, container platform, serverless, etc.) — don't assume a specific cloud.

## EDD Anti-Patterns

**❌ Avoid:**
- Restating what the code does without explaining why
- Over-documenting implementation details (code is the source of truth)
- Creating EDDs for trivial changes (use PR descriptions instead)
- Leaving Open Questions unresolved at implementation time
- Presenting a major, hard-to-reverse decision with no alternatives considered

**✅ Prefer:**
- Explaining architectural decisions and trade-offs
- Documenting non-obvious design choices
- Capturing business context, value, and requirements
- Resolving Open Questions before writing code
- Linking to relevant RFCs, ADRs, or other EDDs

## When to Create an EDD

**Create one when:** adding a feature with business impact; making significant architectural changes; integrating with external systems; the work needs multiple-stakeholder input; implementation spans multiple PRs; design decisions need a record.

**Skip it when:** fixing bugs (use the PR description); refactoring without behavior change; trivial UI changes; documentation updates; dependency upgrades.

## EDD Lifecycle

1. **Draft** — sections validated incrementally during design
2. **Review** — `/design-review` pass; user approves
3. **Implementation** — EDD guides development; Open Questions resolved
4. **Completion** — archived as a design record

**Note:** EDDs are design documents, not living documentation. Code and `CLAUDE.md` are the source of truth for current implementation.
