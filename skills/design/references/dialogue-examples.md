# Design Dialogue Examples

This reference file contains complete examples of design sessions from start to finish. Use these as templates when guiding users through the design process.

## Example 1: CAM Assignment Sync Feature

### Phase 1: Understanding Context

**Claude:**
I'll help you design the CAM assignment sync feature. Let me start by understanding the project context.

*[Reads CLAUDE.md, existing EDDs, searches for HubSpot-related code]*

I see this is a Pre-Trade Services monorepo with a HubSpot integration service already in place. The existing service handles webhook events from HubSpot.

To clarify the requirements, I have a question:

**Question:** What triggers the CAM assignment sync?
- User action (manual trigger)
- Scheduled task (cron job)
- External event (HubSpot webhook)

**User:** HubSpot webhook when CAM assignments change.

### Phase 2: Exploring Approaches

**Claude:**
Based on the existing HubSpot integration architecture, I've identified three approaches:

**Option 1: Event-Driven Webhook Handler (Recommended)**
- Extend existing webhook handler to process CAM assignment change events
- Handler validates, stores event, then worker calls COS API to update
- ✓ Real-time sync, consistent with current architecture, minimal latency
- ✗ Requires webhook configuration in HubSpot

**Option 2: Scheduled Batch Sync**
- Cron job queries HubSpot API every N minutes for changes
- Batch updates to COS
- ✓ Simpler HubSpot configuration, handles bulk changes well
- ✗ Delayed updates (up to N minutes), higher API usage, polling overhead

**Option 3: Manual API Trigger**
- REST endpoint that fetches from HubSpot and pushes to COS on demand
- ✓ Full control over timing, useful for backfills
- ✗ Requires manual intervention, not automated

Recommendation: Option 1 because it leverages the existing webhook infrastructure, provides real-time updates, and follows the established pattern in this codebase.

**Question:** Which approach fits better for your needs?

**User:** Option 1 looks good. We need real-time updates.

### Phase 3: Presenting the Design

**Claude:**
Great! Let me design the webhook-driven CAM sync flow section by section.

#### Section 1: Architecture Overview

The CAM assignment sync extends the existing HubSpot webhook handler to process `company.propertyChange` events where `propertyName` is `cam_owner`. The flow follows the standard handler → DynamoDB → SQS → worker pattern:

```
HubSpot Webhook → API Gateway → Handler Lambda
                                     ↓
                                  DynamoDB (event store)
                                     ↓
                                  SQS Queue
                                     ↓
                                  Worker Lambda → COS API
```

Key changes:
- Handler identifies CAM assignment events by property name
- Worker fetches CAM details from HubSpot API
- Worker calls COS API to update counterparty CAM assignment
- Same error handling and retry logic as existing webhook processing

**Question:** Does this section look right so far?

**User:** Yes, makes sense.

**Claude:**
Great! Moving to the next section.

#### Section 2: Components and Responsibilities

**Handler Lambda** ([hubspot-integration-webhook-handler](../packages/hubspot-integration-webhook-handler/)):
- Validates HubSpot signature (existing)
- Checks for duplicate events (existing)
- **NEW:** Identifies CAM assignment events (`propertyName === 'cam_owner'`)
- Stores event in DynamoDB (existing)
- Enqueues to SQS (existing)

**Worker Lambda** ([hubspot-integration-webhook-worker](../packages/hubspot-integration-webhook-worker/)):
- Fetches event from DynamoDB (existing)
- Marks as "processing" (existing)
- **NEW:** If event is CAM assignment:
  - Fetch company details from HubSpot API
  - Fetch CAM user details from HubSpot API
  - Map HubSpot CAM to COS user ID
  - Call COS API to update counterparty CAM assignment
- Updates status (existing)

**DynamoDB Table:**
- No schema changes needed, `propertyName` and `propertyValue` already captured

**SQS Queue:**
- No changes needed

**Question:** Does this section look right so far?

**User:** How do we map HubSpot CAM to COS user ID?

**Claude:**
Good question! We need a mapping strategy. Let me revise that section.

#### Section 2 (Revised): Components and Responsibilities

[Same as above, but with mapping detail added]

**Mapping Strategy:**
- Use HubSpot user email as the lookup key
- Call COS API `GET /users?email={hubspot_cam_email}` to find COS user ID
- Cache mappings in DynamoDB with TTL (1 hour) to reduce COS API calls
- If no match found, log warning and mark event as "failed" with clear error message

**Question:** Does this revised section work better?

**User:** Perfect.

**Claude:**
Great! Continuing to data flow.

#### Section 3: Data Flow

1. HubSpot sends webhook: `company.propertyChange` for `cam_owner`
2. Handler receives event:
   ```json
   {
     "objectId": "123456",
     "propertyName": "cam_owner",
     "propertyValue": "789"  // HubSpot user ID
   }
   ```
3. Handler stores in DynamoDB and enqueues
4. Worker processes event:
   - Fetch company: `GET /crm/v3/objects/companies/123456?properties=domain,name,cam_owner`
   - Fetch CAM user: `GET /crm/v3/objects/owners/789`
   - Check cache for `cam_email → cos_user_id` mapping
   - If not cached, call COS: `GET /users?email={cam_email}`
   - Call COS: `PATCH /counterparties/{domain}` with `{ "cam_user_id": "{cos_user_id}" }`
5. Worker updates event status to "completed"

**Question:** Does this section look right so far?

**User:** Yes, looks good.

[Continue for remaining sections: Error Handling, Testing Strategy, Deployment]

### Phase 4: Documentation

**Claude:**
I'll now create the EDD document.

*[Determines next sequence number, reads existing EDD as template, writes EDD]*

EDD complete and saved to [docs/EDD/001-cam-assignments.md](../../docs/EDD/001-cam-assignments.md).

**Question:** Ready to implement, or would you like to refine anything?

**User:** Looks good, let's implement.

---

## Example 2: Adding Pagination to Webhook Events API

[Another complete example showing a simpler feature]

### Phase 1: Understanding Context

**Claude:**
I'll help design pagination for the webhook events API. Let me check the current implementation.

*[Reads webhook-service.ts, checks API spec]*

Current implementation returns all events in a single response. For large result sets, this could cause memory issues.

**Question:** What's the expected maximum number of events?
- Small (< 100 events)
- Medium (100-1000 events)
- Large (> 1000 events)

**User:** Could be thousands over time.

### Phase 2: Exploring Approaches

**Claude:**
For handling thousands of events, I've identified two approaches:

**Option 1: Cursor-Based Pagination (Recommended)**
- Use ElectroDB's built-in cursor support
- Return `continuationToken` with each response
- Client passes token for next page
- ✓ Efficient, handles large datasets, stateless
- ✗ Can't jump to arbitrary page numbers

**Option 2: Offset-Based Pagination**
- Use `limit` and `offset` parameters
- Return page numbers
- ✓ Familiar pattern, can jump to any page
- ✗ Inefficient for DynamoDB (scans from beginning each time), slower for large offsets

Recommendation: Option 1 because DynamoDB scan operations natively support cursors and this is more efficient for the dataset size.

**Question:** Which approach fits better for your needs?

**User:** Option 1 is fine, we don't need page numbers.

### Phase 3: Presenting the Design

**Claude:**
Perfect! This will be a simple change to the existing API.

#### Section 1: API Changes

**Current:**
```typescript
GET /webhook-events
Response: { items: WebhookEvent[] }
```

**New:**
```typescript
GET /webhook-events?limit=100&continuationToken=abc123
Response: {
  items: WebhookEvent[],
  continuationToken?: string  // Present if more results exist
}
```

Default `limit`: 100
Max `limit`: 1000

**Question:** Does this section look right so far?

**User:** Yes.

[Continue with remaining sections: Implementation Changes, Testing, etc.]

---

## Key Patterns from Examples

### Question Progression
1. Start broad (trigger mechanism)
2. Get narrower (specific details)
3. One question at a time
4. Use multiple choice when possible

### Approach Presentation
- Always 2-3 options
- Lead with recommended
- Honest about trade-offs
- Context-specific reasoning

### Incremental Validation
- 200-300 words per section
- Ask after EACH section
- Be ready to revise
- Don't dump 3000 words at once

### Handling Objections
When user asks clarifying questions during design:
1. Acknowledge the gap
2. Revise that section
3. Show the revision
4. Ask: "Does this revised section work better?"
5. Continue from there
