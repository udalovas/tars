---
name: design
description: This skill should be used when the user asks to "brainstorm a design", "create an EDD", "design a feature", "spec out requirements", "explore approaches", "plan implementation", or mentions "engineering design document". Transforms ideas into validated Engineering Design Documents through collaborative dialogue.
---

# Design: Ideas Into EDDs

## Overview

Transform ideas into validated Engineering Design Documents (EDDs) through collaborative dialogue. Guide from initial concept through requirements clarification, approach exploration, and incremental design validation before implementation.

## When to Use This Skill

**Use for:**
- Planning new features or significant changes
- Creating Engineering Design Documents (EDDs)
- Exploring requirements before implementation
- Evaluating alternative approaches

**Don't use for:**
- Simple bug fixes or trivial changes
- Pure research tasks (use Explore agent instead)
- When user explicitly requests to skip design phase

## The Process

### Phase 1: Understanding Context

**Goal:** Achieve clarity on WHAT to build and WHY

**Tools:** Read (CLAUDE.md, EDDs, code), Glob (find related files), Bash (git history), AskUserQuestion (clarify requirements)

**Steps:**

0. **Load requirement source (if available):**
   - If the user passed a Jira ticket URL or a `refine` output doc, read it now and treat it as the canonical requirements source throughout. Do not re-ask questions already answered there.

1. **Read project documentation:**
   - Review CLAUDE.md for project architecture
   - Check existing EDDs in docs/EDD/ for patterns
   - Read relevant code sections

2. **Scan the codebase for related patterns:**
   - Search `docs/EDD/` for EDDs that touch the same domain: `grep -rl "topic" docs/EDD/`
   - Find similar implementations: `grep -rl "topic" packages/ cdk/` (limit to 5 most relevant files)
   - Check recent commits: `git log --oneline --grep="topic" -10`
   - Note existing patterns to reuse — don't design what already exists

3. **Clarify the idea:**
   - Ask ONE question at a time using AskUserQuestion
   - Prefer multiple-choice questions when possible
   - Focus on: purpose, constraints, success criteria, user experience

**Example questions:**
- "What triggers this feature? (User action / Scheduled task / External event)"
- "How should errors be handled? (Retry with backoff / Fail fast / Log and continue)"
- "Where does this fit in the architecture? (Lambda handler / Service layer / DTO)"

**Exit criteria:**
- ✓ Read CLAUDE.md and relevant EDDs
- ✓ Identified similar features in codebase
- ✓ Clear on WHAT to build and WHY
- ✓ Constraints and success criteria understood

### Phase 2: Exploring Approaches

**Goal:** Present validated alternatives with trade-offs

**Tools:** Read (existing implementations), Grep (search patterns), AskUserQuestion (get preference)

**Steps:**

1. **Identify 2-3 viable approaches**
2. **Lead with the recommended option**
3. **Consider:**
   - Complexity vs. maintainability
   - Performance implications
   - Testing strategy
   - Alignment with existing architecture

**Format:**

```markdown
Three approaches identified:

**Option 1: [Name] (Recommended)**
- [How it works in context of this codebase]
- ✓ [Key benefit - be specific]
- ✗ [Main drawback - be honest]

**Option 2: [Name]**
- [Alternative approach]
- ✓ [Benefit]
- ✗ [Drawback]

**Option 3: [Name]**
- [Another alternative]
- ✓ [Benefit]
- ✗ [Drawback]

Recommendation: Option 1 because [reasoning based on project constraints and architecture].
```

**Then ask:** "Which approach fits better for your needs?"

**Exit criteria:**
- ✓ Presented 2-3 alternatives with trade-offs
- ✓ User selected preferred approach
- ✓ Trade-offs clearly understood

### Phase 3: Presenting the Design

**Goal:** Build validated design section by section

**Tools:** Read (existing patterns), AskUserQuestion (validate each section)

**Steps:**

1. **Break design into sections** (200-300 words each):
   - Architecture overview
   - Components and responsibilities
   - Data flow / API contracts
   - Error handling and edge cases
   - Testing strategy
   - Deployment considerations

2. **After EACH section, ask:** "Does this section look right so far?"

3. **Be ready to iterate** - If something doesn't resonate, revisit and clarify

4. **Apply YAGNI ruthlessly:**
   - Remove "nice to have" features
   - Simplify to minimum viable solution
   - Question every abstraction
   - Focus on immediate requirements only

**YAGNI Gate — required for every design element:**

Before including any component, endpoint, entity, or abstraction, answer: *"Which stated requirement does this directly address?"* If there is no direct link to a requirement from the current scope, remove it. Do not keep elements because they seem useful, because they might be needed later, or because they appear in similar designs.

- [ ] Can directly name the requirement this element addresses
- [ ] Solves a current problem, not a future one
- [ ] Reuses an existing pattern rather than introducing a new abstraction
- [ ] Is the simplest solution (boring over clever)

**Exit criteria:**
- ✓ All sections validated incrementally
- ✓ Design focuses on MVP, not "nice to haves"
- ✓ User approved each section
- ✓ Design is complete and unambiguous

### Phase 4: Documentation

**Goal:** Create comprehensive EDD file

**Tools:** Bash (find next number), Read (template), Write (create EDD)

**Steps:**

1. **Determine next sequence number:**
   ```bash
   ls docs/EDD/ | grep -E '^[0-9]+' | sort -n | tail -1
   # Increment by 1 for new EDD
   ```

2. **Read existing EDD as template:**
   - Find a recent EDD in docs/EDD/
   - Follow the same pattern for consistency

3. **Create EDD file:** `docs/EDD/{next_number}-{topic}.md`

**EDD Structure:**

```markdown
# {Title}

## Overview
Brief description and purpose

## Requirements
What problem this solves

## Design
Architecture, components, data flow

## Testing Strategy
How to validate it works

## Risks & Mitigations
What could go wrong

## Implementation Notes
Key considerations for developers
```

4. **Keep it concise and scannable:**
   - Use bullet points liberally
   - Include diagrams using markdown (mermaid if needed)
   - Link to relevant code with file paths
   - Focus on "why" not just "what"

5. **Validation checklist:**
   - [ ] All requirements addressed
   - [ ] Approach clearly explained
   - [ ] Trade-offs documented
   - [ ] Testing strategy defined
   - [ ] Risks identified
   - [ ] Implementation path clear

**Exit criteria:**
- ✓ EDD saved to docs/EDD/{number}-{topic}.md
- ✓ All sections complete
- ✓ Validation checklist passed

## Key Principles

- **Understand first, solve second** - Achieve clarity before proposing solutions
- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice when possible** - Faster decision-making than open-ended
- **YAGNI ruthlessly** - Remove everything that isn't immediately essential
- **Show, don't tell** - Use concrete examples from the actual codebase
- **Validate incrementally** - Get feedback section by section, not all at once
- **Keep it simple** - Favor boring, proven, maintainable solutions

## Common Pitfalls

**❌ Don't overwhelm with questions:**
```
Which approach do you prefer? Also, what's the timeline? And who are the stakeholders?
```

**✅ Ask one focused question:**
```
Which approach fits better for your needs? (We'll discuss timeline next)
```

**❌ Don't design everything upfront:**
- Designing edge cases before core flow
- Adding "nice to have" features
- Over-engineering for scale

**✅ Start minimal, iterate:**
- Core flow first
- Essential features only
- Simplest viable solution

**❌ Don't skip validation:**
```
Here's the complete design [3000 words]. Let me know if you have feedback.
```

**✅ Validate incrementally:**
```
Here's the architecture overview section [300 words]. Does this section look right so far?
```

## Completion

After writing the EDD:

1. Confirm it's saved to docs/EDD/{number}-{topic}.md
2. Prompt: "EDD saved. Run `/design-review docs/EDD/{file}` to get a code-reviewer + security-auditor pass before implementation, or `/plan docs/EDD/{file}` to go straight to task breakdown."
3. If implementing, the main conversation continues with the EDD as reference

## Additional Resources

For detailed examples and advanced patterns, consult:
- **`references/dialogue-examples.md`** - Complete design session examples
- **`references/edd-patterns.md`** - EDD templates and patterns from this project
