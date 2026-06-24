---
name: review
description: Creates a PR with a clean description and automatically responds to review comments — fixing what can be fixed, flagging what needs the engineer. Use when pushing a branch for review, creating a PR, or when review comments have been posted. Trigger phrases: "create a PR", "push for review", "respond to review comments", "address review feedback", "/review".
---

# Push and Review

Create a PR with a clean, EDD-linked description, and respond to review comments — applying mechanical fixes automatically, flagging judgment calls to the engineer.

## When to Use

- After `/test` passes and you're ready to push a branch
- When a PR is open and review comments need responses
- When returning to a PR after addressing feedback

**When NOT to use:** Conducting a review of someone else's code — **delegate that to the `code-reviewer` sub-agent** — invoke it by bare name via the Agent tool (`subagent_type: "code-reviewer"`); a project-local `.claude/agents/code-reviewer.md` overrides the bundled default, so never pin the plugin-namespaced form. For an AWS-hosted change, you may additionally fan out to the optional `aws-reviewer`. This skill is for *creating and responding to* reviews, not conducting them.

## Two Sub-Flows

---

### Sub-flow A: PR Creation

**Trigger:** `/review` with no open PR on the current branch, or `/review create`.

#### Steps

1. **Understand the change:**
   ```bash
   git status
   git log --oneline main..HEAD
   git diff main..HEAD --stat
   ```

2. **Find the relevant EDD** (if the project keeps them; `docs/EDD/` by convention — check `CLAUDE.md`):
   ```bash
   grep -rl "$(git log --oneline -1 | cut -c9-)" docs/EDD/ 2>/dev/null | head -1
   ```
   Read the EDD summary section for description language. Skip this step if the project has no EDDs.

3. **Docs-consistency gate:**

   Verify the change's documentation *before* opening the PR. **Delegate to the `docs-consistency-reviewer` sub-agent when available** — invoke it by bare name via the Agent tool (`subagent_type: "docs-consistency-reviewer"`); a project-local `.claude/agents/docs-consistency-reviewer.md` overrides the bundled default, so never pin the plugin-namespaced form. **If the agent isn't available, perform the check inline** — the skill must work on a clean machine with no custom agents installed.

   Give it the change and the project context:
   - the diff: `git diff main..HEAD`
   - project context: the path to `CLAUDE.md` (and any standards it references)

   It checks two things: **(a) coverage** — new public functionality (APIs, CLI flags, config options, env vars, breaking changes) is documented to the project's standard, read from `CLAUDE.md` / `.claude/rules/` / existing docs, else a built-in floor checklist; **(b) consistency** — the diff hasn't left existing docs stale or contradictory (renamed flags, changed signatures, drifted tables, outdated claims). Scope is the current diff only — not a full-repo docs audit. It reports gaps; it does not write docs.

   **Surface, then confirm:** print the classified report (Blocking / Non-blocking / Suggestion). If it reports any findings, ask the engineer **"Proceed with PR anyway? (y/n)"** before continuing. A clean report proceeds silently. A finding never auto-aborts PR creation — the engineer decides.

   This gate runs in **Sub-flow A only**; it does not run when responding to review comments (Sub-flow B).

4. **Draft PR:**
   - Title: ≤ 70 characters, imperative verb ("Add webhook signature retry logic")
   - Body: three sections only (see template below)
   - Do not describe the *what* — the diff shows that. Describe the *why*.

5. **Push and create:**
   ```bash
   git push -u origin HEAD
   gh pr create --title "..." --body "$(cat <<'EOF'
   ## Summary
   - [why this change is needed — not what it does]
   - [key decision made and why]
   - [any non-obvious side effect]

   ## EDD Reference
   [EDD-XXX: Title](docs/EDD/XXX_Title.md) — or "N/A"

   ## Test plan
   - [ ] [what was tested and how]
   - [ ] [edge case verified]
   EOF
   )"
   ```

6. Return the PR URL.

---

### Sub-flow B: Review Response

**Trigger:** `/review respond` or when the user says "respond to review comments", "address the PR feedback".

#### Steps

1. **Read all open comments:**
   ```bash
   gh pr view --comments
   gh api repos/{owner}/{repo}/pulls/{pr}/comments
   ```

2. **Categorize each comment:**

   | Category | Examples | Action |
   |----------|----------|--------|
   | **AUTO-APPLY** | Style, naming, formatting, typos, missing test case with obvious content, doc update | Apply and reply |
   | **FLAG** | Architecture change, behavior change, API contract change, unclear intent | Reply explaining why it needs engineer judgment |

3. **For AUTO-APPLY comments:**
   - Apply the fix
   - Commit: `fix(review): address PR comment — [short description]`
   - Reply on the comment thread: `"Addressed in [commit SHA]"`

4. **For FLAG comments:**
   - Reply on the comment thread: `"Flagging for engineer: [reason auto-fix was not applied]"`
   - Never silently skip a comment — every comment gets a reply

5. **After all comments processed:**
   ```bash
   git push
   ```
   Report a summary: N comments auto-fixed, M flagged for engineer.

## Policy

**Never silently resolve a comment.** Every comment receives either:
- A fix + `"Addressed in [SHA]"` reply, or
- A `"Flagging for engineer: [reason]"` reply

This keeps the PR conversation readable and reviewers informed.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The PR description will be obvious from the diff" | Reviewers read descriptions first. A missing *why* forces them to guess or ask. |
| "I'll respond to comments later" | Stale PR threads slow merge. Address comments in one focused pass. |
| "This comment is nitpicking, I can ignore it" | Every comment needs a reply. "Won't fix" is a valid response — silence is not. |

## Red Flags

- PR title describing the *what* instead of the *why* ("Update auth.ts" → bad; "Fix session token expiry race condition" → good)
- PR body longer than ~200 words (sign of over-explaining — simplify)
- Any open review comment with no reply before re-requesting review
- Applying a behavior-changing fix from a review comment without flagging it

## Verification

**PR Creation:**
- [ ] Docs-consistency gate run (agent or inline); findings surfaced and engineer confirmed before proceeding
- [ ] Title is ≤ 70 characters and imperative
- [ ] Body has exactly three sections: Summary, EDD Reference, Test plan
- [ ] Summary bullets describe *why*, not *what*
- [ ] PR URL returned to engineer

**Review Response:**
- [ ] Every open comment has a reply (auto-fix acknowledgment or flag)
- [ ] AUTO-APPLY changes committed and pushed
- [ ] FLAG comments have a reason stated
- [ ] `git push` executed after all fixes applied
