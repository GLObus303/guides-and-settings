---
name: quick-wins
description: Scan files you touched for pre-existing issues that are trivial to fix. Use after completing a feature or during code review to find low-effort improvements in nearby code. Never fixes automatically — lists findings and asks the user.
---

# Nearby Quick Wins

Scan the files in your current diff for **pre-existing issues** that would be trivial to fix while you're already in the area. These are NOT bugs in your code — they're existing tech debt that can be cleaned up opportunistically.

## How to Use

1. Get the list of files you modified: `git diff --name-only main`
2. Read each file (not just your diff — the full file)
3. Look for the patterns below
4. List findings and ask the user which ones (if any) they want to fix

## What to Look For

### Deprecated APIs (high value — prevents future migration work)

- `useRibbonQuery` → `useMomenceQuery` from `@momence/momence-query`
- `useRibbonMutation` → `useMomenceMutation`
- `.exist()` → `.exists()` (TypeORM deprecated method)
- `useFormContext()` → `useRibbonFormContext()` (crashes inside RibbonForm)
- `NullablePositiveIntegerDeprecated` → `NullablePositiveInteger`
- `forEach` → `for...of` (coding standard)
- Raw `.where()` / `.andWhere()` → `.typedWhere()` / `.andTypedWhere()`
- `leftJoinAndSelect` string form → `.withRelations()`
- `PageFormContainer` → `PageContainer` + `RibbonForm`

### Styling / UI (if frontend files changed)

- `styled.div` / `styled.span` that could be `<Box>` / `<Text>`
- `px` values that should be `rem` (use standard spacing: 0.25, 0.375, 0.5, 0.75, 1rem)
- Missing `$` prefix on styled-component transient props (DOM leaking)
- Hardcoded hex colors that should use theme (`theme.palette.shades.gray[400]`)
- `!important` in CSS (signals wrong specificity — restructure instead)
- `0.4rem` or other non-standard spacing values

### Code Quality (always applicable)

- Magic numbers without named `UPPER_SNAKE_CASE` constants
- `console.log` / `console.warn` left in production code (use `logger`)
- Inline types that should be extracted to `Params` / `Props`
- `as any` casts that could be properly typed with minimal effort
- Dead code: unused imports, unreachable branches, commented-out blocks
- `// TODO` comments that reference completed work or merged PRs
- `@ts-ignore` that could be replaced with `as any` (explicit intention)

### Soft-Delete Gaps (high value — prevents data bugs)

- Missing `deletedAt: IsNull()` on queries in the same file
- `relations: { x: true }` on soft-deletable entities (loads deleted records)
- Missing `hostId` scoping on multi-tenant queries

### TypeORM Patterns

- `findOneOrFail` with `select` that might strip needed columns
- `IN ()` with potentially empty arrays (needs `safeInArray`)
- Manual `repo.save(repo.create({...}))` → `saveEntity(Entity, {...})`

## How to Present Findings

```markdown
## Nearby Quick Wins (optional, outside your PR scope)

I noticed these pre-existing issues in files you touched:

### high-value (prevents future bugs/migration)

1. **[file.ts:42](path/file.ts#L42)** `useRibbonQuery` → `useMomenceQuery` (deprecated)
2. **[file.ts:89](path/file.ts#L89)** Missing `deletedAt: IsNull()` on member query

### low-effort cleanup

3. **[component.tsx:15](path/component.tsx#L15)** `styled.div` → `<Box direction="row" gap="0.5rem">`
4. **[component.tsx:67](path/component.tsx#L67)** `16px` → `1rem`

Want me to fix any of these? They're small changes that improve the files you're already modifying.
```

## Rules

- **Only scan files in the current diff** — don't audit the whole codebase
- **Only flag issues that are genuinely quick** (< 5 lines each to fix)
- **NEVER fix without asking** — the user may want to keep the PR focused
- **Group by priority** (high-value first, cosmetic last)
- **Skip entirely** if the PR is already large (> 300 LOC changed)
- **Skip if the user is in a hurry** — this is optional, not blocking
- Include file:line references so the user can review each one
