---
name: design-review
description: Structured review of an EDD (Engineering Design Document) before implementation. Spawns design-reviewer and security-auditor personas in parallel — plus an optional aws-reviewer pass on AWS-hosted projects — merges their reports, and appends a verdict to the EDD file. Use before running /plan on any non-trivial design. Trigger phrases: "review this design", "review the EDD", "/design-review".
---

# Design Review

Review an EDD before implementation starts. Runs `design-reviewer` (architecture) and `security-auditor` (security & compliance) in parallel — plus an optional `aws-reviewer` pass when the project is AWS-hosted — and appends a consolidated verdict to the document.

## When to Use

- After `/design` produces an EDD and before `/plan` begins task breakdown
- When reviewing an existing EDD that has changed significantly
- When an EDD covers a new service, a new data model, or a cross-stack change

**When NOT to use:** Minor EDD amendments that only update implementation notes or fix typos.

## The Process

### Step 1: Load the EDD

Read the EDD file from the path the user provided (e.g. `docs/EDD/023-agentic-sdlc-skills.md`).

If no path provided, list recent design docs from the project's EDD directory (`docs/EDD/` by convention — check `CLAUDE.md` for the project's location):
```bash
ls docs/EDD/ | grep -E '^[0-9]+' | sort -n | tail -5
```
Then ask: "Which EDD should I review?"

### Step 2: Parallel Fan-Out

Spawn the reviewers concurrently. Each receives the full EDD content and the project context (the path to `CLAUDE.md` and any project standards it points to).

Prefer dedicated review agents if the host environment provides them (`design-reviewer`, `security-auditor`, and — optionally — `aws-reviewer`). **If those agents are not available, perform the passes inline yourself** — the skill must work on a clean machine with no custom agents installed.

```
├── Reviewer: architecture & correctness  (agent: design-reviewer, if available)
│   Prompt: "Review this EDD for architectural soundness, feasibility,
│            completeness, trade-off analysis (see Step 2a), and alignment
│            with the project standards referenced from CLAUDE.md. Identify
│            blocking and non-blocking issues. EDD content: [full text]"
│
├── Reviewer: security & compliance  (agent: security-auditor, if available)
│   Prompt: "Review this EDD for security vulnerabilities and for any
│            regulatory/compliance exposure relevant to this project (see
│            CLAUDE.md for the applicable regimes — e.g. data-protection,
│            market, or AI-specific regulation). EDD content: [full text]"
│
└── Reviewer: AWS cloud lens  (agent: aws-reviewer, OPTIONAL)
    Run this pass ONLY if the project is AWS-hosted (CLAUDE.md names AWS,
    or the repo has AWS infra-as-code/SDK usage). The agent self-declines
    on non-AWS projects, so it is safe to skip when there is no AWS signal.
    Prompt: "Review this EDD through an AWS Well-Architected lens (compute,
             data access patterns, IAM, storage/encryption, messaging,
             networking). EDD content: [full text]"
```

Wait for all spawned passes to complete before proceeding.

### Step 2a: Trade-Off Analysis Check (architecture pass)

For every **major architectural decision** in the EDD — one with a **high cost of change later** (data model / schema, public API or contract shape, persistence or messaging technology, service boundaries, sync vs async, build vs buy, security model) — confirm the EDD documents:

- **At least one credible alternative** that was considered, and
- **Why it was rejected** (the trade-off: what was gained, what was given up).

A major decision presented with no alternatives and no rejection rationale is a **blocking issue** — record it as "Trade-off analysis missing for: [decision]". Reversible, low-cost-of-change decisions do not require this.

### Step 3: Merge Reports

Synthesise the reports (two, or three when the AWS pass ran) into a single consolidated review:

1. Collect all **Critical** / **High** / **Blocking** findings from every agent — these are **blocking**
2. Collect all **Important** / **Medium** / **Non-blocking** findings — these are **non-blocking but should be addressed**
3. Collect **Suggestions** / **Low** / **Info** — nice to have
4. Note **positive observations** from each pass

### Step 4: Append Verdict to EDD

Append a `## Design Review` section to the EDD file:

```markdown
## Design Review

| Field    | Value                                      |
|----------|--------------------------------------------|
| Reviewed | YYYY-MM-DD                                 |
| Verdict  | APPROVED | APPROVED WITH COMMENTS | NEEDS REVISION |

### Blocking Issues
[List or "None"]

### Non-Blocking Issues
[List or "None"]

### Suggestions
[List or "None"]

### Positive Observations
[List]
```

**Verdict rules:**
- `APPROVED` — no blocking issues
- `APPROVED WITH COMMENTS` — no blocking issues, but non-blocking issues should be addressed before or during implementation
- `NEEDS REVISION` — one or more blocking issues; EDD should be updated before `/plan`

### Step 5: Notify Engineer

State the verdict and blocking issues (if any) in the conversation. A `NEEDS REVISION` verdict is a **warning** — the engineer can still run `/plan`, but should address blocking issues first.

```
Design review complete.

Verdict: NEEDS REVISION

Blocking issues (2):
1. [design-reviewer] No error handling specified for partial batch failures
2. [security-auditor] External payload processed before signature/authentication verified

Full review appended to docs/EDD/NNN_Feature_Name.md

Run `/plan docs/EDD/NNN_Feature_Name.md` when ready to proceed.
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I know this design is fine, the review is overhead" | Design bugs found now cost one EDD edit. Found during implementation, they cost a rewrite. |
| "It's a small change, not worth a full review" | Small changes with a security or compliance angle (new data field, new external call) are exactly what this review catches. |
| "I'll address the blocking issues after I start building" | Blocking issues may invalidate the architecture of the tasks already built. |

## Red Flags

- Proceeding to implementation with unacknowledged blocking issues
- Running design review on a draft EDD that hasn't been through `/design` validation
- A major, hard-to-reverse decision (data model, API contract, persistence tech) with no alternatives or trade-off rationale documented
- Skipping the security & compliance pass for any feature that touches personal data or external APIs

## Verification

- [ ] All review passes completed (architecture + security, plus the optional AWS pass when AWS-hosted) — dedicated agents or inline — and their reports were read
- [ ] Every major / high-cost-of-change decision has a documented alternative + trade-off rationale (else flagged blocking)
- [ ] Blocking vs. non-blocking issues correctly classified
- [ ] Verdict appended to the EDD file
- [ ] Engineer notified of verdict and blocking issues
