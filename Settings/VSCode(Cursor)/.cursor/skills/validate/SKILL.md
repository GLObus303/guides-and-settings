---
name: validate
description: Post-implementation validation checklist for Momence. Use after completing a feature to verify code follows codebase practices, patterns from similar recent files, and CLAUDE.md guidelines.
---

# Post-Implementation Validation

Run this checklist after completing any significant implementation to ensure code quality and consistency.

## How to Use

For reviewing others' PRs, use `/code-review`.

### Deep Validation Mode (Recommended for significant implementations)

For thorough self-checks, use **parallel review agents** that deeply search the codebase for issues before you submit a PR.

**Steps:**

1. Gather the list of files created/modified: `git diff --name-only main`
2. Get the full diff: `git diff main`
3. **Spawn relevant review agents in parallel** using the Agent tool:

| Agent               | When to spawn                            | What it checks                                                         |
| ------------------- | ---------------------------------------- | ---------------------------------------------------------------------- |
| `review-reuse`      | **Always**                               | Searches codebase for existing utils/components you should use instead |
| `review-backend`    | Backend services, controllers, entities  | Service org, manager/audit patterns, NestJS conventions                |
| `review-frontend`   | Frontend components, hooks, forms        | Box/Text vs styled, rems, form patterns                                |
| `review-typeorm`    | Entities, migrations, queries            | Deprecated methods, entity design, migration quality                   |
| `review-robustness` | Any non-trivial logic                    | N+1 queries, race conditions, edge cases                               |
| `review-security`   | Backend endpoints, controllers, services | Auth asserts, multi-tenant scoping, data exposure                      |

4. Collect findings and **fix issues** before proceeding to manual phases below
5. Run Phase 0.5-6 below for anything the agents don't cover
6. Run Phase 6 (build/lint/test) to verify everything compiles

### Quick Validation Mode

For small changes (<50 LOC), skip agents and run through the checklist below manually.

### Manual Phases

1. Gather the list of files created/modified in this implementation
2. Run through each validation phase below
3. Fix any issues found before considering the task complete

---

## Phase 0.5: Reuse Check (Most Common PR Feedback)

Before anything else — the #1 reason PRs get comments is failing to reuse existing code. For EVERY new function, component, hook, or utility:

- [ ] **Search for existing backend services** that already do the same thing (e.g., `addTagsToCustomer`, `formatFullName`, `groupBy`, `keyBy`)
- [ ] **Search for existing frontend components** — use `Box`/`Text`/`Block` instead of styled components, check for reusable select inputs (e.g., `TagSingleSelectInput`)
- [ ] **Search for existing hooks** — `useMomenceQuery` (not `useRibbonQuery`), window dimension hooks, etc.
- [ ] **Search for existing form helpers** — `emptyToNull`, `z.entityId()`, `isClearable`/`onClear` on inputs
- [ ] **Infer types from schemas** — use `Infer<typeof schema>` instead of defining separate type interfaces
- [ ] **No styled components** when `Box`/`Text` with props can achieve the same layout
- [ ] **Use rems** (not px), follow standard sizing (e.g., `0.375rem` not `0.4rem`)

```bash
# Search for existing utilities before writing new ones
grep -r "export.*function\|export const" backend/services/ --include="*.ts" -l | xargs grep -l "<keyword>"
grep -r "TagSingleSelectInput\|TagMultiSelectInput" frontend/ --include="*.tsx" -l | head -5
```

---

## Phase 1: Similar File Comparison

For each NEW file created, find 2-3 similar recent files in the same directory or domain:

```bash
# Find similar files by pattern (prefer recent ones - check git log dates)
ls -lt backend/db/entities/SimilarEntity*.ts | head -5
git log -1 --format="%ci" -- <file>  # Check when file was last modified
```

**Check for:**

- [ ] Same import style and ordering
- [ ] Same decorator patterns and ordering
- [ ] Same type definition patterns
- [ ] Same function signature patterns (params object vs positional)
- [ ] Same error handling patterns
- [ ] Same naming conventions

**Why recent files matter:** Older files may use legacy patterns. Prefer files modified in last 6 months as reference.

---

## Phase 2: CLAUDE.md Compliance

### TypeScript Style

- [ ] Arrow functions (not `function` declarations)
- [ ] Param objects with explicit types (not positional args)
- [ ] `const` over `let` — no variable mutation; extract helper functions that return values instead of `let` + reassignment
- [ ] `for...of` over `.forEach()`
- [ ] No comments that restate what the code does (e.g., `// Load existing slot` above `loadEventTypeSlot()`) — only comment the "why"

### Type Safety

- [ ] No `@ts-ignore` (use `as any` if truly needed)
- [ ] Enums for string literals (not union types)
- [ ] Enum naming: PascalCase plural, UPPER_SNAKE_CASE keys, kebab-case values

### Database Patterns

- [ ] `AuditColumnsWithDelete` for new entities (not `AuditColumns`)
- [ ] `deletedAt: IsNull()` filter when querying soft-deletable entities
- [ ] `saveEntity()` with direct object (not `.create()`)
- [ ] `softDeleteRecord()` utility for soft deletes
- [ ] `triggeredBy` passed through call chain (not hardcoded)
- [ ] Optional `manager` and `triggeredAt` params for testability

### Concurrency

- [ ] `parallelRun` for N > 10 promises (not `Promise.all`)
- [ ] `groupBy`/`keyBy` utilities for array operations

### API Usage

- [ ] No deprecated methods (check IDE warnings, e.g., `findOneBy` → `typedFindOneBy` on scheduled jobs)
- [ ] Using latest utility signatures (e.g., `formatFullName`, `groupBy`, `keyBy`)

### Frontend Forms

- [ ] `useRibbonFormContext()` from `@momence/ui-components` (NOT `useFormContext` from `react-hook-form`)

### Naming

- [ ] Specific export names (not generic like `getFilters`)
- [ ] Full words (not abbreviations like `getUsrInf`)
- [ ] `Props` for React, `Params` for everything else
- [ ] Exported types include name prefix (`export type HostDetailProps`, `export type AssignRoleParams`)
- [ ] File names: Frontend `PascalCase` for components, NestJS `kebab-case`, Express/services `camelCase`
- [ ] Folders: camelCase for regular folders, PascalCase for component folders

### Error Handling

- [ ] `OptionalResult` for expected failures (validation, policy checks, user input)
- [ ] `throw` only for unexpected errors (DB failures, programming bugs)
- [ ] Error context included for caller to handle gracefully

---

## Phase 3: Entity-Specific Checks

If creating TypeORM entities:

### Enum Files (`db/entities/enums/`)

- [ ] Exported as named export
- [ ] Enum name matches filename
- [ ] Values are kebab-case strings

### Lookup Tables

- [ ] `@LookupTableOf` decorator BEFORE `@Entity` decorator
- [ ] Single `id` column with `Relation<EnumType>`
- [ ] Table name ends with `_lookup`

### Main Entities

- [ ] Extends `AuditColumnsWithDelete`
- [ ] `@Index()` on frequently queried columns
- [ ] FK columns use `Relation<EnumType>` for lookup refs
- [ ] jsonb columns use `Relation<Record<string, unknown>>`
- [ ] `@ManyToOne` with `@JoinColumn` for FK relations
- [ ] **Every FK column has a corresponding `@ManyToOne` relation** — including `hostId` (e.g., `host?: Relation<Hosts>`). Don't skip common FKs.
- [ ] snake_case DB columns, camelCase TypeScript props
- [ ] **TS property name matches DB column name** — `pool_source_id` → `poolSourceId` (not `poolRecordSourcedId`). The camelCase should be a direct conversion of the snake_case.

### Exports

- [ ] All new entities exported in `db/entities/index.ts`
- [ ] Alphabetical ordering maintained

---

## Phase 4: Migration Checks

If creating/modifying DB entities:

### Verify Migration is Clean

```bash
# Check schema matches DB state (detects pending migrations)
yarn test-migrations

# Check for dangerous operations (large table alterations, index drops)
yarn check-migrations
```

- [ ] `yarn test-migrations` passes (no schema mismatch)
- [ ] `yarn check-migrations` passes (no dangerous operations)

### Migration Content (if migration generated)

- [ ] Only contains changes for THIS feature (no unrelated index/column changes)
- [ ] Lookup tables created before main table
- [ ] Lookup values inserted before FK constraints
- [ ] Proper indexes created
- [ ] Partial unique index uses `WHERE deleted_at IS NULL` for soft-delete tables
- [ ] FK constraints reference correct tables
- [ ] Down migration reverses in correct order (FKs first, then indexes, then tables)
- [ ] Parameterized queries for INSERT statements (`$1`, not string interpolation)

---

## Phase 5: Service Function Checks

- [ ] Uses param objects with explicit type definitions
- [ ] Arrow function syntax
- [ ] Optional `manager?: EntityManager` with default `getManager()` — use `manager = getManager()` in destructuring (not `manager: managerParam` + `const manager = managerParam ?? getManager()`)
- [ ] Optional `triggeredAt?: Date` with default `new Date()`
- [ ] `triggeredBy` parameter (not hardcoded synthetic user)
- [ ] Returns typed result (not `any`)
- [ ] **Manager passed to all sub-service calls** — if a service accepts `manager`, pass it through to every service/repository call it makes, including sub-services
- [ ] **Multi-step read-then-write wrapped in transaction** — if a service reads data and then writes based on that data (e.g., get next handler → assign), wrap in `manager.transaction()` to prevent concurrent issues

---

## Phase 6: Build, Lint & Test

```bash
# Backend
cd backend && yarn build
yarn lint:base path/to/new/files/
yarn test --testPathPattern="fileNamePattern"

# Frontend (if applicable)
cd frontend && yarn build
yarn lint path/to/new/files/
```

- [ ] Build passes without errors
- [ ] Lint passes without warnings
- [ ] No type errors in modified files
- [ ] Tests pass for modified/related files

---

## Phase 7: Domain-Specific Skills

Check if implementation touches domains with dedicated skills:

| Domain         | Skill             | Check                                       |
| -------------- | ----------------- | ------------------------------------------- |
| AI Agent       | `/ai-agent`       | Tag filtering, settings, workflow patterns  |
| Frontend UI    | `/frontend-ui`    | Box/Text, ChoiceInput, translations, Zod    |
| Tests          | `/testing`        | AAA pattern, mocking, test groups           |
| Scheduled Jobs | `/scheduled-jobs` | Cron patterns, self-scheduling, superstruct |
| Planning/Specs | `/planning`       | Feature toggles, backwards compatibility    |

---

## Phase 8: AI Agent Tool Checks

If creating/modifying agent tools in `hostDashboardAgents/agentToolHandlers/`:

### Tool Structure

- [ ] Uses `defineAgentTool<Args>()` pattern
- [ ] Returns `{ next_step, note }` response objects
- [ ] Uses `logAction()` with proper `SupportAgentEffectTypes`
- [ ] Helper functions placed after main export (e.g., `getFreezePolicyNote`)

### Error Handling

- [ ] Error responses include context for agent to communicate to customer
- [ ] Example: `{ next_step: 'cannot_proceed', note: 'Error message', freezesUsed: 2, freezesRemaining: 0 }`

### Response Quality

For agent response patterns (short-circuit, terminology, don't-assume-outcomes), refer to the `/ai-agent` skill.

### New Effect Types (if adding)

- [ ] Added to `SupportAgentEffectTypes` enum (`db/entities/enums/`)
- [ ] Added to `getAgentEffectTypeOptions.ts` (options for UI)
- [ ] Added superstruct validator in `supportAgentActedLog.ts`
- [ ] Added to `SupportAgentActionLog` union type in `types.ts`

---

## Quick Reference Commands

```bash
# Find similar recent files
git log --since="6 months ago" --name-only --pretty=format: -- "backend/db/entities/*.ts" | sort | uniq -c | sort -rn | head -20

# Check file modification dates
git log -1 --format="%ci %s" -- <file>

# Run backend build
cd backend && yarn build 2>&1 | tail -30

# Run lint on specific files
yarn lint:base path/to/file.ts

# Verify entity exports
grep -n "export.*from.*Entity" backend/db/entities/index.ts | tail -10
```
