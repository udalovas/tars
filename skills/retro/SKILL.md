---
name: retro
description: End-of-session retrospective that converts friction observed during the session into durable improvements to the consuming project's rules and docs. Run as the last step of the workflow, after the PR has landed and comments are resolved. Curates a short, evidence-linked report of key decisions, rule/standard gaps, and context-gathering inefficiencies, then applies diff-ready improvements after confirmation. Trigger phrases: "run a retro", "session retrospective", "reflect on this session", "/retro".
---

# Session Retrospective

Close the workflow loop: mine the session that just finished for friction — clarifications that shouldn't have been needed, corrections that arrived late, context that was expensive to gather — and turn it into concrete, confirmed edits to the project's rules and docs. The goal is compounding: every session makes the next one faster, cheaper in tokens, and cleaner on the first iteration.

The ideal to measure against: **after the design is approved and reviewed, implementation proceeds without interruption** — tactical engineering questions (approaches, patterns, standards, style) should already be answered by the project's rules. Every mid-implementation clarification and every PR-review correction is a gap in those rules, not just a moment of friction.

## When to Use

- As the **final step** of the workflow chain — the PR has merged, with review comments resolved beforehand (typically via `/resolve-pr-comments` while the PR was still open)
- After any session with noticeable friction: repeated clarifications, style or pattern corrections during implementation or PR review, extensive searching to reconstruct context the docs should have carried
- When the same question or correction has come up more than once across sessions

**When NOT to use:**
- Mid-workflow — the PR hasn't landed or comments are unresolved; finish the chain first so the retro sees the whole picture, including what the review caught
- After a clean session with no notable friction — say so in one or two sentences and stop; **never invent findings to fill a template**
- To review the code itself — that is `/review`; the retro reviews the *process*, not the artifact

## The Process

### Step 1: Confirm the Session Is Closed

Check that the workflow has actually finished (PR merged or approved, comments resolved). If it hasn't, say so and offer to run the retro once it has. A retro on an unfinished session misses the most valuable evidence — what the PR review caught.

### Step 2: Scan the Session Through Three Lenses

Walk back through the conversation and collect candidate observations. Three lenses, in order:

1. **Key decisions** — choices made during the session that shaped the outcome: design directions taken or rejected, scope cuts, trade-offs accepted. These anchor the retro and often deserve a line in the project's docs or an architecture decision record (check `CLAUDE.md` for where the project keeps design/decision docs).

2. **Rule and standard gaps** — every moment the flow *stopped* when it shouldn't have:
   - Clarifying questions asked after design approval (approach, pattern, naming, style, error handling, where things live)
   - Corrections issued by the engineer during implementation
   - PR review comments that a written rule would have prevented
   
   For each: what rule, convention, or doc — had it existed in `CLAUDE.md` or `.claude/rules/` — would have made the interruption unnecessary?

3. **Context-gathering efficiency** — where tokens went into rediscovering rather than building:
   - The same file read multiple times, or broad searches repeated with small variations
   - Knowledge reconstructed from source that a doc, map, or `CLAUDE.md` pointer should have provided (architecture, entry points, command incantations, domain vocabulary)
   - Missing "where things are" signposts that forced exploratory scanning
   
   This assessment is **qualitative** — based on observed tool-call patterns in the session, not token telemetry. Do not fabricate numbers.

### Step 3: Curate

Select the **top 3–5 findings** by expected impact on the next session (speed, token cost, fewer interruptions, better first-iteration quality). This is a cut, not a summary — drop everything below the line. Every finding that survives must cite its **evidence**: the specific session moment (the question asked, the correction given, the repeated search) that motivated it.

### Step 4: Propose Diff-Ready Improvements

For each finding, propose a concrete change:

- **Target file** — exact path in the consuming project: `CLAUDE.md`, a file under `.claude/rules/`, or a project doc. Check what already exists before proposing a new file; prefer extending an existing rule over creating a parallel one.
- **The text itself** — the actual lines to add or change, ready to apply. "Document the testing approach better" is not a proposal; the paragraph that documents it is.

Present the report:

```markdown
## Session Retro

### Key decisions
- [decision + one-line rationale]

### Findings (prioritized)

**1. [finding title]** — [lens: rule gap | context efficiency]
Evidence: [the specific session moment]
Proposal → `[target file]`:
> [the exact text to add/change]

**2. ...**

### Recommendations outside this project (not applied)
- [suggestions targeting user-level config or workflow-skill definitions, if any]
```

Improvements whose natural home is **outside the project** — the user's personal `~/.claude/` config, or the definitions of the workflow skills themselves — are surfaced in the recommendations section only. This skill edits **project files only**.

### Step 5: Confirm, Apply, Restate

Ask the engineer which proposals to apply (`AskUserQuestion`, multi-select). Then:

1. Apply **exactly** the approved edits to the named files — nothing else
2. Declined proposals are dropped, not parked; the report itself is not persisted
3. Restate what changed: file-by-file, one line each

The durable output of a retro is the applied edits — the next session inherits them through the project's own rules and docs.

## Rules

- **Project-agnostic.** Never assume a language, framework, or toolchain. Findings and proposals are phrased in terms of the consuming project's own conventions, read from its `CLAUDE.md` and `.claude/rules/`.
- **Edit project files only.** `CLAUDE.md`, `.claude/rules/`, and project docs. User-level `~/.claude/` files and skill definitions are recommendation-only, even if the engineer's approval seems to imply otherwise — call out the boundary explicitly.
- **Evidence or it didn't happen.** A finding without a citable session moment is an opinion; leave it out.
- **Curate hard.** Five findings maximum. A retro that lists twenty issues gets none of them fixed.
- **Report is chat-only.** No retro log files, no backlog files.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The session went fine, but I should still list some findings" | A forced retro produces noise rules that dilute the real ones. A clean session is a valid, reportable outcome. |
| "I'll phrase it generally so it applies everywhere" | Generic advice ("write better docs") changes nothing. Only a diff-ready proposal aimed at a named file gets applied. |
| "The engineer corrected me once — not worth a rule" | One correction in this session is the second-cheapest time to write the rule down. The cheapest was before the session. |
| "More findings show a more thorough retro" | Impact comes from the top 3–5. Everything after that is where retros go to die. |
| "I remember roughly where the friction was" | Roughly is not evidence. Walk the session and cite the actual moments — the discipline is what keeps findings honest. |

## Red Flags

- A finding with no cited session moment behind it
- A proposal that names no target file or contains no concrete text
- More than 5 findings in the report
- Editing files the engineer didn't approve, or files outside the project
- Running the retro while the PR is still open — the review's corrections are half the evidence
- Writing a retro log file "for the record"

## Verification

- [ ] PR landed and comments resolved before the retro ran (or the skill said "not yet" and stopped)
- [ ] Every finding cites the specific session moment that motivated it
- [ ] Every proposal names an exact project file and contains the ready-to-apply text
- [ ] Report contains at most 5 findings (or honestly reports a clean session)
- [ ] Only engineer-approved edits were applied, only to project files
- [ ] Applied changes were restated file-by-file at the end
