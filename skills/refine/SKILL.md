---
name: refine
description: Guides engineers through requirement refinement via structured dialogue. Use when starting from a raw idea, a vague Jira ticket, or an unclear brief. Surfaces assumptions, establishes measurable success criteria, and produces a Jira-ready acceptance criteria block. Trigger phrases: "refine this requirement", "help me clarify this idea", "turn this into a Jira ticket", "/refine".
---

# Requirement Refine

Turn a raw idea into a clear, aligned requirement with measurable success criteria before any design work begins.

## When to Use

- Starting from a vague idea, a rough Jira ticket, or a one-liner brief
- Requirements feel ambiguous or assumptions are hidden
- Stakeholders may not be aligned on scope or purpose
- Before running `/design` — a solid requirement makes design faster and reduces rework

**When NOT to use:** Bug fixes with a clear reproduction case; changes where the requirement is already a well-formed Jira ticket with AC.

## The Process

### Step 1: Ingest

Accept input in any of these forms:
- Free text description (from the user's message or any argument passed to the skill)
- Issue-tracker URL (e.g. Jira) → if a tracker integration is available, fetch the existing title, description, and AC
- File path → read the file

### Step 2: Restate and Surface Assumptions

Before asking any questions, produce:

```
How Might We: [one-sentence framing of the problem]

Assumptions I'm making:
1. [assumption]
2. [assumption]
3. [assumption]
→ Correct me on any of these before we continue.
```

This forces hidden constraints into the open immediately. Do not proceed until the user confirms or corrects.

### Step 3: Structured Dialogue

Ask **one question at a time** using `AskUserQuestion`. Prefer multiple-choice. Cover these areas in order — stop early if the user's answers already cover them:

1. **User and pain** — Who specifically experiences this problem? What does their current workaround look like?
2. **Value and cost of inaction** — Why is this worth doing now? **What happens if we don't do this?** Push for the concrete cost of inaction (revenue, risk, manual toil, blocked work) — not "it would be nice". If the answer is "nothing much", that is a signal to deprioritise or drop the increment.
3. **Success criteria** — How will we know this is done? What does a passing acceptance test look like? (Push for something specific and measurable — reject "make it faster" without a number)
4. **Constraints** — Time, dependencies, budget, compliance considerations?
5. **Stakeholders** — Who must align before implementation starts?
6. **Out of scope** — What is this explicitly NOT solving?

### Step 4: Produce Requirement Doc

Once dialogue is complete, produce:

```markdown
## Requirement: [Title]

**Problem:** [one unambiguous sentence]

**Value:** [why this is worth doing now, and the concrete cost of *not* doing it]

**Success Criteria:**
- [ ] [specific, testable criterion]
- [ ] [specific, testable criterion]

**Stakeholders:** [list]

**Assumptions:** [explicit list — confirmed during dialogue]

**Out of Scope:** [explicit list]

**Suggested Jira AC:**
- Given [context], when [action], then [outcome]
- Given [context], when [action], then [outcome]
```

Ask: "Does this look right? Shall I create or update the Jira ticket?"

### Step 5: Persist to Issue Tracker (Optional)

If the user confirms and an issue-tracker integration is available (e.g. a `jira` skill), create a new ticket or update the existing one. The tracker is the single source of truth — no local file is written. If no tracker is available, hand the requirement block back to the user to file themselves.

After the ticket is done: "Requirement refined. Run `/design` to start the EDD."

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The requirement is obvious, I don't need to refine it" | Hidden assumptions are the most common source of rework. A 5-minute refinement prevents days of misaligned design. |
| "I'll clarify requirements during implementation" | By then the design is done and the cost of change is high. |
| "The user already explained it" | Restatement surfaces what you understood, which often differs from what was meant. |
| "Success criteria can be figured out later" | Without them, done is never defined and scope creep is invisible. |

## Red Flags

- Proceeding to `/design` without being able to state the success criteria in a single testable sentence
- Requirements that contain "better", "faster", "improved" without a measurable threshold
- No articulated value — if no one can answer "what happens if we don't do this?", the increment may not be worth building
- No explicit out-of-scope list — scope is defined by what's excluded as much as what's included
- Key stakeholders not identified

## Verification

- [ ] Problem statement is one unambiguous sentence
- [ ] Value is stated, including the concrete cost of *not* doing it ("what if we don't?")
- [ ] Success criteria are specific and testable (not adjectives)
- [ ] Assumptions are listed and confirmed, not buried
- [ ] Out-of-scope list is explicit
- [ ] User has confirmed the output before proceeding
