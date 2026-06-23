---
name: resolve-pr-comments
description: Review, classify, and auto-resolve PR comments. Classifies each comment by impact (minor/major/critical), makes code changes for major+critical, pushes a single commit, and replies to addressed comments with the commit reference.
---

# PR Comment Resolution

Fetch all unresolved review comments on a PR, classify them by impact, fix the ones that matter, push, and reply.

## Invocation

```
/resolve-pr-comments [PR number]
```

If no PR number is given, auto-detect from the current branch.

---

## Step 1 — Identify the PR

If a PR number was supplied as an argument, use it. Otherwise detect it:

```bash
gh pr view --json number,headRefName,baseRefName,url,state
```

Abort with a clear message if:
- No PR is open for the current branch
- The PR is already merged or closed

Also fetch the repo owner and name:

```bash
gh repo view --json owner,name
```

---

## Step 2 — Fetch Unresolved Comment Threads

Use the GitHub GraphQL API to get all **unresolved, non-outdated** review threads with their comments. This is the most reliable way to know what still needs attention.

Paginate until `pageInfo.hasNextPage` is false, passing `pageInfo.endCursor` as the `after` argument on each subsequent request:

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!, $after: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          isResolved
          isOutdated
          id
          comments(first: 10) {
            nodes {
              databaseId
              url
              body
              path
              line
              author { login }
            }
          }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F pr=PR_NUMBER -F after=''
```

Repeat the request with `-F after=END_CURSOR` until `pageInfo.hasNextPage` is false, then merge all pages' `nodes` arrays.

Filter the result: keep only threads where `isResolved = false` AND `isOutdated = false`.

For each qualifying thread, take the **first** (root) comment as the canonical comment to classify and reply to. Note its `databaseId`, `url`, `body`, `path`, and `line`.

Also fetch general (non-review) issue comments on the PR — these are top-level discussion comments, not inline code comments. Use `--paginate` to retrieve all pages:

```bash
gh api repos/OWNER/REPO/issues/PR_NUMBER/comments --paginate
```

Include all of these in the set to classify.

---

## Step 3 — Classify Each Comment

Read each comment body and classify it as **minor**, **major**, or **critical** using the criteria below. Apply your own judgment; these are guidelines, not rigid rules.

### Critical
Fix immediately. These block safety, correctness, or data integrity:
- Security vulnerabilities: injection, auth bypass, exposed secrets, XSS
- Bugs that break functionality or cause data loss
- Incorrect business logic or wrong API contract
- Race conditions or data integrity violations

### Major
Fix in this pass. These cause real problems over time:
- Missing error handling for expected failure cases
- Incorrect types or type-safety violations (`any`, unsafe casts)
- Missing input validation at system boundaries
- Code that deviates from established project patterns in a way that will cause confusion
- Performance issues with meaningful impact
- Logic that is wrong but doesn't fully break things yet

### Minor
Do not fix automatically. Surface to the user for their own judgment:
- Style, formatting, or naming nitpicks
- Optional refactoring suggestions
- "Consider..." or "could also..." wording
- Documentation wording improvements
- Very small readability tweaks with no correctness impact

---

## Step 4 — Present Classification

Before making any changes, display a summary table to the user:

```
## PR Comment Classification

| # | File / Location       | Reviewer | Impact   | Summary                              |
|---|-----------------------|----------|----------|--------------------------------------|
| 1 | src/handler.ts:42     | alice    | CRITICAL | SQL injection via unsanitised input  |
| 2 | src/service.ts:18     | bob      | MAJOR    | Missing error handling on null case  |
| 3 | src/types.ts:7        | alice    | MINOR    | Rename `x` to `multiplier`          |
...

Will address: N critical + N major comments.
Will skip:    N minor comments (listed for your review below).
```

Then proceed without waiting — the classification display IS the intent declaration. Do not ask for confirmation unless you are genuinely uncertain about classification of a specific comment.

---

## Step 5 — Address Major and Critical Comments

For each major or critical comment, make the necessary code changes. Work through them one at a time:

1. Read the relevant file at the indicated path/line
2. Understand what the reviewer is asking
3. Implement the fix — follow the project's existing patterns and standards (see `CLAUDE.md`)
4. Do not add comments to the code explaining the fix — the commit message will do that

Group all fixes into a single working set (do not commit after each one).

---

## Step 6 — Commit and Push

After all fixes are applied, run the project's full verification — auto-fix/format, type-check, and tests. **Use the commands defined in `CLAUDE.md`**; the block below is only an illustrative Node/npm example.

```bash
# Auto-fix / format   (e.g. npm run fix · ruff --fix · gofmt -w)
npm run fix

# Type checking       (e.g. npm run test:tsc · mypy · tsc --noEmit)
npm run test:tsc

# Tests               (e.g. npm test · pytest · go test ./...)
npm test
```

If any of these fail, do not push. Report the failures to the user and stop.

Stage only modified/created files (never `git add -A` — avoid accidentally staging unrelated files):

```bash
git add <file1> <file2> ...
```

Write the commit message using this format:

```
fix(review): address PR review comments

- <one-line summary of fix 1> [comment: URL1]
- <one-line summary of fix 2> [comment: URL2]
...
```

Commit:

```bash
git commit -m "$(cat <<'EOF'
fix(review): address PR review comments

- Fix missing null guard in webhook handler [comment: https://github.com/...]
- Add input validation for batchId parameter [comment: https://github.com/...]
EOF
)"
```

Push:

```bash
git push
```

Capture the resulting commit SHA:

```bash
git rev-parse HEAD
```

---

## Step 7 — Reply to Addressed Comments

For each comment that was addressed, post a reply on GitHub referencing the commit.

**For inline review comments** (have a `databaseId` from the review thread), post a reply in the same thread:

```bash
gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments \
  -X POST \
  -f body="Fixed in COMMIT_SHA: <one-sentence description of what was changed>." \
  -F in_reply_to=COMMENT_DATABASE_ID
```

**For general issue comments**, post a new top-level comment on the PR:

```bash
gh api repos/OWNER/REPO/issues/PR_NUMBER/comments \
  -X POST \
  -f body="Addressed in COMMIT_SHA: <one-sentence description of what was changed>."
```

Keep replies concise — one sentence describing the change, plus the commit SHA. No apologies, no padding.

---

## Step 8 — Final Report

Print a summary:

```
## Resolution Summary

Commit: abc1234 — pushed to <branch>

### Addressed (N comments)
- [CRITICAL] src/handler.ts:42 — Fixed SQL injection via parameterised query
- [MAJOR]    src/service.ts:18 — Added null guard before owner lookup

### Left for your review (N minor comments)
- src/types.ts:7 — Rename `x` to `multiplier` (alice)
- src/utils.ts:31 — Consider extracting helper (bob)
```

---

## Error Handling

- If `gh` is not authenticated: tell the user to run `gh auth login` and stop.
- If no unresolved comments exist: say so and stop — nothing to do.
- If a comment references a file that no longer exists or a line that has moved significantly: classify it as **minor**, include it in the minor list with a note explaining the file/line could not be located, and do not attempt to fix it.
- If type-checking fails after fixes: report the errors, do not push, ask the user to resolve before retrying.
- Never force-push. Never amend existing commits.

---

## Classification Quick-Reference

| Signal in comment text           | Likely classification |
|----------------------------------|-----------------------|
| "security", "injection", "secret", "token", "leak" | Critical |
| "bug", "wrong", "broken", "fails", "crash"         | Critical |
| "missing error", "null", "undefined", "exception"  | Major    |
| "type", "any", "unsafe", "validation"              | Major    |
| "pattern", "convention", "architecture"            | Major    |
| "nit", "nitpick", "minor", "consider", "optional"  | Minor    |
| "style", "format", "rename", "naming"              | Minor    |
| "could also", "alternatively", "suggestion"        | Minor    |
