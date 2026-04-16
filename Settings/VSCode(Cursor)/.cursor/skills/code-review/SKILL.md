---
name: code-review
description: Code review checklist for Momence PRs. Use when reviewing a PR, analyzing a diff, or when asked to review code changes. Covers logic, tests, performance, security, maintainability, and architecture.
---

# Code Review

Structured checklist for reviewing pull requests. Use this when asked to review a PR or diff.

## How to Use

For self-checking your own implementation before submitting a PR, use `/validate`.

### Deep Review Mode (Recommended)

For thorough reviews, use **parallel review agents** that each get their own context window and deeply search the codebase. This is more accurate than a single-pass review.

**Steps:**

1. Fetch the PR diff: `gh pr diff <PR_NUMBER>`
2. Assess PR scope (Phase 0 below)
3. Identify which file types changed (backend services, frontend components, entities, migrations, agent tools)
4. **Spawn the relevant review agents in parallel** using the Agent tool — each agent gets the diff and list of changed files as context:

| Agent               | When to spawn                                    | What it checks                                                              |
| ------------------- | ------------------------------------------------ | --------------------------------------------------------------------------- |
| `review-reuse`      | **Always** — this is the #1 feedback category    | Searches codebase for existing utils/components that could replace new code |
| `review-backend`    | Backend services, controllers, entities changed  | Service org, manager/audit patterns, NestJS conventions                     |
| `review-frontend`   | Frontend components, hooks, forms changed        | Box/Text vs styled, rems, form patterns, React conventions                  |
| `review-typeorm`    | Entities, migrations, query code changed         | Deprecated methods, entity design, migration quality                        |
| `review-robustness` | Any non-trivial logic changed                    | N+1 queries, race conditions, edge cases, transactions                      |
| `review-security`   | Backend endpoints, controllers, services changed | Auth asserts, multi-tenant scoping, permission guards, data exposure        |
| `review-ai-agent`   | Files in `hostDashboardAgents/` changed          | Tool messaging, policy toggles, argument validation                         |

**Example prompt for spawning agents:**

```
Spawn these review agents in parallel. Pass each one the PR diff and changed file list.
For each agent, tell it: "Review the following PR changes: <diff summary>. Changed files: <file list>"
```

5. Collect findings from all agents
6. Synthesize into the urgency-grouped format below
7. Run Phase 2-8 checks yourself for anything the agents don't cover (logic, security, architecture)

### Quick Review Mode

For small PRs (<100 LOC) or time-sensitive reviews, skip agents and run through the checklist below manually.

---

## Phase 0: PR Scope Check

```bash
# Get PR diff stats
gh pr diff <PR_NUMBER> --stat
gh pr view <PR_NUMBER> --json additions,deletions,changedFiles
```

- [ ] PR is under ~400 changed lines of code (excluding generated files, migrations, lock files)
- [ ] PR has a single coherent purpose (not bundling unrelated changes)

If the PR exceeds 400 LOC or mixes concerns, flag it. Large PRs are harder to review thoroughly and more likely to hide bugs.

---

## Phase 1: Understand the Change

Before reviewing line-by-line, understand the intent:

```bash
# Read PR description
gh pr view <PR_NUMBER> --json title,body

# See commit history
gh pr view <PR_NUMBER> --json commits --jq '.commits[].messageHeadline'

# Get the full diff
gh pr diff <PR_NUMBER>
```

- [ ] PR description clearly explains what and why
- [ ] If PR links a ClickUp ticket (e.g., `https://app.clickup.com/t/<ID>`), fetch it via `mcp__clickup__clickup_get_task` for full requirements/acceptance criteria context
- [ ] Commits tell a coherent story
- [ ] You understand the expected behavior change

---

## Phase 1.5: High-Priority Checks (Most Common PR Feedback)

These are the most frequently flagged issues in PR reviews. Check these FIRST as they account for the majority of review comments.

### Reuse Existing Utilities & Components (TOP PRIORITY)

Before writing ANY new helper, component, or service — search the codebase for an existing one:

- [ ] **Backend utilities:** `groupBy`, `keyBy`, `diffIdArrays`, `parallelRun`, `formatFullName`, `saveEntity`, `softDeleteRecord` — search before writing custom logic
- [ ] **Backend services:** Search for existing services that already do what you need (e.g., `addTagsToCustomer`, `assignTagsToCustomer`, `removeTagsFromCustomer` instead of custom tag logic)
- [ ] **Frontend components:** Use `Box`, `Text`, `Block` instead of creating styled components. Use `TagSingleSelectInput` and other reusable select components before building custom ones
- [ ] **Frontend hooks:** `useMomenceQuery` (not `useRibbonQuery`), check for existing observer hooks (e.g., for window dimensions)
- [ ] **Form helpers:** `emptyToNull`, `z.entityId()`, `isClearable`/`onClear` on inputs, `RibbonForms` with `SwitchInput`
- [ ] **Schema types:** Infer types from Zod schemas (`Infer<typeof schema>`) instead of defining separate types

### Frontend UI Conventions

- [ ] Use `Box`/`Text`/`Block` components — avoid creating styled components when these suffice
- [ ] Use `rems` for sizing (not `px`), follow standard sizing rules (e.g., `0.375rem` not `0.4rem`)
- [ ] Prefix transient styled-component props with `$` to prevent DOM leaking (e.g., `$width` not `width`)
- [ ] Destructure props consistently throughout the component
- [ ] Use `{customer}` translation token (industry-agnostic term)

### Backend Service Organization

- [ ] **One exported service function per file** — never multiple exported services in one file
- [ ] **Services belong in `services/` folder** — not inside `routes/`
- [ ] **No DB access in controllers** — all repository queries (reads AND writes) go through service functions
- [ ] **Get/read services must be pure** — no side effects; return data/flags, let callers handle actions
- [ ] **Always accept `manager?: EntityManager`** with default `manager = getManager()` — pass it through to ALL sub-service calls
- [ ] **Always accept `triggeredAt?: Date`** with default `new Date()`
- [ ] **Use `saveEntity()` without `.create()`** — pass a plain object
- [ ] **Set audit columns:** `triggeredBy`, `deletedAt`/`deletedBy` for soft deletes
- [ ] **Check `deletedAt: IsNull()`** when querying soft-deletable entities

### NestJS Over Express

- [ ] **New endpoints must use NestJS controllers and DTOs** — not Express routes
- [ ] **Validation in DTOs** — use class-validator decorators, not manual checks in controllers
- [ ] **Prefer separate nullable keys** over discriminated unions in DTOs (e.g., `memberId?: number`, `customerLeadId?: number` instead of union with `contactType`)

### Robustness

- [ ] **Wrap read-then-write in transactions** — concurrent invocations can race (e.g., round-robin assignment)
- [ ] **No N+1 queries** — use `In(ids)` + `keyBy`/`groupBy` map instead of DB calls in loops
- [ ] **Scheduled jobs:** Handle crash recovery (auto-reschedule), deduplication, and predictable batch sizes
- [ ] **Falsy number checks:** Use `!= null` not truthiness (`0` is falsy — e.g., `freezeFeeAmount` could be 0)

### AI Agent Tools

- [ ] **Pro-active messaging:** Tool responses should tell the agent what to convey to the customer, not just return data (e.g., "No limit on freezes, you can freeze as many times as you need")
- [ ] **Handle all paths:** If a tool checks policy but can't act on exceptions, either add the capability or tell agent to escalate
- [ ] **Validate tool arguments** — don't silently ignore invalid args
- [ ] **Policy tools available regardless of feature toggles** — the tool gives info, the toggle controls action

### Naming & Comments

- [ ] **No obvious comments** — don't restate what the code does; only comment "why"
- [ ] **Name magic numbers** as `UPPER_SNAKE_CASE` constants
- [ ] **Specific names** — not generic (`data`, `value`, `result`); e.g., `customerTagIdOnCreatedMember` not `customerTagId`
- [ ] **Full words** — no single-letter variables except `it` in callbacks
- [ ] **Don't mutate** — prefer immutable patterns; if a service returns a value, use it instead of mutating a variable

---

## Phase 2: Logic & Functionality

Read changed code carefully for correctness:

- [ ] No logic errors (wrong conditions, inverted booleans, incorrect comparisons)
- [ ] No off-by-one errors (loop bounds, array indexing, pagination)
- [ ] Edge cases handled (empty arrays, null/undefined, zero values, boundary conditions)
- [ ] Falsy checks on numbers use `!= null` (not truthiness - `0` is falsy)
- [ ] Async/await used correctly (no missing `await`, no unhandled promises)
- [ ] Early returns and short-circuits are correct (not skipping required logic)
- [ ] No `RegExp` with `g` flag used with `.test()` on module-level constants (`lastIndex` persists between calls, causing intermittent false negatives)
- [ ] Nested loop `continue`/`break` targets the correct loop level (use labeled breaks when intending to exit an outer loop)
- [ ] Mutable collections (Map/Set/Array) declared outside loops are not unintentionally shared across iterations

---

## Phase 3: Test Coverage

- [ ] New functionality has corresponding tests
- [ ] Modified behavior has updated test expectations (old assertions match new logic)
- [ ] Edge cases from Phase 2 are covered by tests
- [ ] No tests asserting wrong expectations (test passes but verifies incorrect behavior)

For test style checks (AAA pattern, `test.each`, naming, mocking), refer to the `/testing` skill.

---

## Phase 4: Performance

- [ ] No N+1 query patterns (DB calls inside loops)
- [ ] `Promise.all` limited to N <= 10; `parallelRun` used for larger batches
- [ ] No unnecessary DB queries (data already available in scope)
- [ ] Large collections use efficient lookups (`keyBy`/`groupBy` instead of repeated `.find()`)
- [ ] No potential race conditions in concurrent operations — read-then-write patterns (e.g., "get next in queue" → "assign") need transactions
- [ ] No deadlock risk in transaction ordering
- [ ] Pagination used for potentially large result sets
- [ ] No subqueries or EXISTS in hot listing queries — prefer denormalized columns (see `/typeorm` skill)

---

## Phase 5: Maintainability

### Code Clarity

- [ ] Code is readable without needing the author to explain it
- [ ] Names are descriptive and specific (not generic like `data`, `result`, `getFilters`)
- [ ] Functions have a single responsibility
- [ ] No commented-out code left behind
- [ ] No hard-coded values that should be constants or configuration

### Codebase Consistency

- [ ] Follows existing patterns in the codebase for similar functionality
- [ ] Uses established utilities (`groupBy`, `keyBy`, `diffIdArrays`, `saveEntity`, `parallelRun`)
- [ ] Matches style of recent similar files (not legacy patterns)
- [ ] Naming conventions followed (see CURSOR.md)
- [ ] One exported service function per file

### CURSOR.md Compliance

Run `/validate` Phase 2 checks (TypeScript style, type safety, naming, concurrency, API usage).

---

## Phase 6: Security

- [ ] No SQL injection risk (parameterized queries, not string interpolation)
- [ ] No XSS vectors (user input sanitized before rendering)
- [ ] No command injection (user input not passed to shell commands)
- [ ] Authorization checks present (user can only access their own data)
- [ ] Multi-tenant data scoping enforced (hostId filtering)
- [ ] Sensitive data not logged or exposed in error messages
- [ ] No secrets or credentials in code

---

## Phase 7: Error Handling

- [ ] Errors provide meaningful context (not swallowed silently)
- [ ] User-facing error messages are helpful (not stack traces or internal details)
- [ ] Failures don't crash the application (graceful degradation where appropriate)
- [ ] Log messages include context for debugging (`logger.error({ hostId, subscriptionId }, 'Failed to freeze')`)

For `OptionalResult` vs `throw` patterns and logger conventions, refer to `/validate` Phase 2 and CURSOR.md.

---

## Phase 8: Design & Architecture

- [ ] Design was reviewed before implementation for substantial changes (spec/design doc exists)
- [ ] No unnecessary abstraction (don't create helpers for one-time operations)
- [ ] No over-engineering (no feature flags, config, or extensibility beyond what's needed now)
- [ ] Backwards compatible with old frontend during deployment (see `/planning` skill for full guidance)
- [ ] New DB columns are nullable or have defaults
- [ ] No breaking changes to existing API endpoints
- [ ] Migration is clean (only changes for this feature, proper up/down)

---

## Top Bug Classes (from 285 PRs analyzed)

Quick-scan checklist based on the most frequently occurring bugs across Dec 2025 — Mar 2026. See `improve/PR_ANALYSIS.md` for full data.

**#1 — Soft-delete mishandling (12 instances):**

- [ ] `relations: { x: true }` on soft-deletable entities → use `withRelations` with `deletedAt IS NULL` condition
- [ ] Unique constraints on soft-delete tables include `deletedAt`?
- [ ] Agent tool queries include `disabled: false` + `deletedAt: IsNull()` + join-table soft-delete?
- [ ] `doXBelongToHost` calls followed by separate soft-delete check?
- [ ] OneToOne FK nulled on soft-delete?

**#2 — Missing field forwarding (9 instances):**

- [ ] Every optional field explicitly forwarded through pipeline steps (not silently dropped)?
- [ ] Conversion layers (API → internal model) map ALL fields, including ones added by later features?
- [ ] Manual response types (Express routes) match current backend fields?
- [ ] `null` used (not `undefined`) to clear nullable DB fields?

**#3 — Silent error handling (8 instances):**

- [ ] Every `catch` block either reports to Sentry or re-throws — no bare `logger.error`?
- [ ] `return null` only used when absence is an expected condition, not to hide failures?
- [ ] Supplementary updates (metadata, conversation entries) placed after the primary operation or in own try/catch?
- [ ] Empty arrays explicitly guarded before proceeding (not treated as "success with no results")?

**#4 — AI agent prompt issues (8 instances):**

- [ ] No "or" in agent instructions (creates ambiguity → least-effort path)?
- [ ] Tools referenced in prompts actually present in the agent's `tools` array?
- [ ] Agent tool queries match the user-facing endpoint filter stack?
- [ ] Escalation instructions explicitly prohibit followup questions?

**#5 — Feature flag + config mismatch (5 instances):**

- [ ] Config data consumers guard with `flag && data` (not just `data`)?
- [ ] Boolean flags that depend on nullable entities co-validated at save time?
- [ ] New AI agent toggles default to disabled (opt-in)?
- [ ] Conditional Zod fields use `.optional()` + `superRefine` (not required in base schema)?

---

## Presenting Findings

Group review comments by urgency:

### Urgency Levels

| Level | Label              | Meaning                                                     |
| ----- | ------------------ | ----------------------------------------------------------- |
| 1     | **Must-fix**       | Bugs, security issues, data loss risk, broken functionality |
| 2     | **Should-fix**     | Missing tests, performance problems, error handling gaps    |
| 3     | **Recommendation** | Better patterns, improved naming, cleaner structure         |
| 4     | **Nit**            | Style preferences, minor formatting, optional improvements  |

### Output Format

```markdown
## Code Review: PR #<number> - <title>

### Summary

<1-2 sentence overview of the change and overall assessment>

### Must-fix

- **[file:line]** <description of the issue and why it matters>

### Should-fix

- **[file:line]** <description>

### Recommendations

- **[file:line]** <description>

### Nits

- **[file:line]** <description>

### What looks good

<Brief note on well-done aspects - acknowledge good patterns, thorough tests, clean design>
```

---

## Tips

- Don't check what is already automated (compiler errors, lint rules, CI checks)
- Focus on things humans are better at: logic correctness, design quality, edge cases, naming clarity
- For complex changes, read related code (callers, tests, similar implementations) for full context
- Flag when 2-person review is warranted (major architectural changes, security-sensitive code, payment/billing logic)
- If code is hard to understand during review, it will be hard to maintain later - flag it
