# Design Dialogue Examples

Complete examples of design sessions from start to finish. Use these as templates for the *shape* of the dialogue — the domains and tech below are deliberately generic. In a real session, ground every example in the **host project's** actual architecture (read its `CLAUDE.md` and code first).

## Example 1: Notify on Order Status Change

### Phase 1: Understanding Context

**Claude:**
I'll help you design the order-status notification feature. Let me start by understanding the project context.

*[Reads CLAUDE.md, existing EDDs, searches for how the project currently handles events]*

I see the service already processes order events and has an existing notification component. To clarify the requirements, one question:

**Question:** What triggers a notification?
- A user action (manual)
- A scheduled job
- An order-status change event (event-driven)

**User:** When an order's status changes.

### Phase 2: Exploring Approaches

**Claude:**
Based on the existing event-handling architecture, I've identified three approaches:

**Option 1: Hook into the existing status-change event (Recommended)**
- Extend the current handler to emit a notification when status transitions
- ✓ Real-time, consistent with current architecture, minimal new surface area
- ✗ Couples notification timing to the status-change path

**Option 2: Scheduled diff/poll**
- A periodic job compares statuses and notifies on changes
- ✓ Decoupled from the write path; handles bulk changes well
- ✗ Delayed (up to the poll interval); extra read load

**Option 3: Manual trigger endpoint**
- An endpoint that sends notifications on demand
- ✓ Full control; useful for backfills
- ✗ Not automated; needs human action

Recommendation: Option 1 — it reuses the existing event flow and gives real-time delivery, matching the established pattern in this codebase.

**Question:** Which approach fits better for your needs?

**User:** Option 1. We need it real-time.

### Phase 3: Presenting the Design

**Claude:**
Great — let me design the event-driven flow section by section.

#### Section 1: Architecture Overview

The feature extends the existing status-change handler. When an order transitions to a notify-worthy status, the handler enqueues a notification job; a worker renders and sends it. This follows the project's existing handler → queue → worker pattern.

```
Order status change → Handler → Queue → Worker → Notification channel
```

**Question:** Does this section look right so far?

**User:** Yes.

**Claude:**
Moving on.

#### Section 2: Components and Responsibilities

- **Handler** — detects the qualifying status transition (NEW), enqueues a job (existing plumbing).
- **Worker** — loads order + recipient, renders the message, sends via the notification channel (NEW: the render + send for this message type).
- **Data model** — no schema change; the order record already carries status and recipient.

**Question:** Does this section look right so far?

**User:** How do we decide *who* gets notified?

**Claude:**
Good question — let me revise with a recipient-resolution rule.

#### Section 2 (Revised)

**Recipient resolution:**
- Look up the order's owner; fall back to the account contact if no owner is set.
- If neither exists, log a warning and mark the job failed with a clear reason (don't silently drop).

**Question:** Does this revised section work better?

**User:** Perfect.

#### Section 3: Data Flow

1. Order status changes to `shipped`.
2. Handler detects the transition and enqueues `{ orderId, newStatus }`.
3. Worker loads the order, resolves the recipient, renders the message, sends it.
4. Worker records delivery status (sent / failed + reason).

**Question:** Does this section look right so far?

**User:** Yes.

[Continue for remaining sections: Error Handling, Testing Strategy, Deployment]

### Phase 4: Documentation

**Claude:**
*[Determines next sequence number, reads a recent EDD as a template, writes the EDD]*

EDD complete and saved to `docs/EDD/0NN-order-status-notification.md`.

**Question:** Ready to implement, or refine anything?

**User:** Let's implement.

---

## Example 2: Add Pagination to a List Endpoint

### Phase 1: Understanding Context

**Claude:**
I'll help design pagination for the list endpoint. Let me check the current implementation.

*[Reads the service code and the API spec]*

The endpoint currently returns all records in one response, which risks memory and latency issues as data grows.

**Question:** What's the expected maximum result size?
- Small (< 100)
- Medium (100–1,000)
- Large (> 1,000)

**User:** Thousands over time.

### Phase 2: Exploring Approaches

**Claude:**
For thousands of records, two approaches:

**Option 1: Cursor-based pagination (Recommended)**
- Return a `continuationToken`; the client passes it back for the next page
- ✓ Efficient and stateless; scales to large datasets
- ✗ Can't jump to an arbitrary page number

**Option 2: Offset-based pagination**
- `limit` + `offset` with page numbers
- ✓ Familiar; supports jumping to any page
- ✗ Degrades on large offsets; many data stores scan from the start each time

Recommendation: Option 1 — it matches how the project's data store reads efficiently and the use case doesn't need page numbers.

**Question:** Which fits your needs?

**User:** Option 1 — no page numbers needed.

### Phase 3: Presenting the Design

#### Section 1: API Changes

**Current:**
```
GET /items
Response: { items: [...] }
```

**New:**
```
GET /items?limit=100&continuationToken=abc123
Response: {
  items: [...],
  continuationToken?: "..."   // present only if more results exist
}
```

Default `limit`: 100. Max `limit`: 1000.

**Question:** Does this section look right so far?

**User:** Yes.

[Continue with: Implementation Changes, Testing, Backwards-compatibility]

---

## Key Patterns from Examples

### Question Progression
1. Start broad (trigger / scope)
2. Get narrower (specific details)
3. One question at a time
4. Multiple choice when possible

### Approach Presentation
- Always 2–3 options
- Lead with the recommended one
- Honest about trade-offs
- Reasoning grounded in the actual project

### Incremental Validation
- 200–300 words per section
- Ask after EACH section
- Be ready to revise
- Don't dump 3,000 words at once

### Handling Objections
When the user raises a gap mid-design:
1. Acknowledge it
2. Revise that section
3. Show the revision
4. Ask: "Does this revised section work better?"
5. Continue from there
