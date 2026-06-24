# Git Conventions

Trunk-based development — `main` is the trunk. Branches are short-lived and merge back quickly via PR. Never commit directly to `main`.

## Branch naming

```
<type>/[short-description]
```

**Types:** `feature`, `bugfix`, `hotfix`, `chore`, `docs`

Examples: `feature/add-trade-leg`, `bugfix/correct-trade-leg-side`, `chore/cleanup-deps`

For urgent fixes without a ticket, omit the ticket segment: `hotfix/fix-critical-auth-bug`

## Commit messages

```
<type>[(<ticket-number>)]: <short description>
```

**Types:** `feat`, `fix`, `chore`, `docs`, `refactor`, `perf`, `style`, `revert`, `ci`

The ticket number is optional — omit it only when there is no associated ticket (e.g. an urgent hotfix).

Examples:
- `feat: add forward instrument sub-types`
- `fix: correct trade leg side calculation`

Never add `Co-Authored-By` trailers to commit messages.