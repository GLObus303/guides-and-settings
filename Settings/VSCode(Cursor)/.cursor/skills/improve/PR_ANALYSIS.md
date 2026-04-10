# PR Analysis: Top Patterns from 285 PRs (Dec 2025 — Mar 2026)

Analysis of ~285 merged PRs across the Momence monorepo — 42 via review comment analysis, 243 via deep code diff analysis.

---

## Top Bug Classes (by frequency)

### 1. Soft-Delete Mishandling (12 instances) — #1 BUG CLASS

The codebase uses `AuditColumnsWithDelete` extensively, but `deletedAt: IsNull()` is easy to forget. Manifests in 6 distinct ways:

| Variant                                             | Example PRs    | Impact                           |
| --------------------------------------------------- | -------------- | -------------------------------- |
| `relations: { x: true }` loads soft-deleted records | #15737         | Payroll inflation (money)        |
| Nullable relation filter = implicit INNER JOIN      | #15675         | Bookings silently excluded       |
| Unique constraint without `deletedAt`               | #15201, #15765 | Blocks re-creation permanently   |
| Agent tools missing `disabled`/`deletedAt` filters  | #15286, #15612 | Agent suggests unavailable items |
| `doXBelongToHost` doesn't check soft-delete         | #15000, #15362 | Can operate on deleted records   |
| OneToOne FK not nulled on soft-delete               | #15449         | Blocks reassignment              |

**Why it keeps happening:** TypeORM's `.find()` with `relations` silently includes deleted records. The `doXBelongToHost` pattern only checks host scoping. Agent tools reimplement queries without matching the full filter stack.

### 2. Missing Field/Parameter Forwarding (9 instances)

When data flows through multi-step pipelines (conversion layers, job metadata, serializers), optional fields silently drop out:

| Variant                                        | Example PRs                              |
| ---------------------------------------------- | ---------------------------------------- |
| Optional contact IDs not forwarded             | #15758 (userId), #14774 (customerFields) |
| Conversion layer missing new fields            | #15378 (stripeConnectedAccountId)        |
| Pipeline not threading field through all steps | #14777 (tierId), #14772 (hostId)         |
| `undefined` vs `null` semantics wrong          | #15494, #14771                           |
| Manual response type missing backend field     | #15288                                   |

**Why it keeps happening:** TypeScript optional fields compile fine when absent. Pipeline functions accept partial objects. Manual response types (Express routes) drift from backend.

### 3. Silent Error Handling (8 instances)

Catch blocks that swallow errors without alerting, or functions that return `null` instead of throwing:

| Variant                                     | Example PRs | Impact                                   |
| ------------------------------------------- | ----------- | ---------------------------------------- |
| `catch` with only `logger.error`, no Sentry | #15759      | Emails stop sending, no alert            |
| TypeORM `.update()` throws on empty SET     | #15751      | Caught silently, entire flow aborted     |
| `return null` hides validation failure      | #15734      | Signature processing silently skipped    |
| Post-success steps poison failure recording | #15682      | Successful invoices recorded as failures |
| Generic error message discards real error   | #15500      | Users see opaque "payment failed"        |

**Why it keeps happening:** Defensive `try/catch` around non-critical operations (conversation entries, metadata updates) silently catches critical exceptions. `return null` is used as a "safe" fallback where `throw` is appropriate.

### 4. AI Agent Prompt/Tool Issues (8 instances)

LLM behavior surprises from prompt wording, tool schema, and query design:

| Variant                                          | Example PRs    |
| ------------------------------------------------ | -------------- |
| "or" in instructions → LLM picks least effort    | #15655, #15658 |
| Missing tool in agent's `tools` array            | #15660         |
| LLM passes "any"/"\*" as search queries          | #15347         |
| Agent tool query missing business filters        | #15286         |
| `deletedAt` filter excludes records agent needs  | #15612         |
| Copy-paste transposition in symmetrical branches | #15397         |
| Regex `g` flag causes stateful alternation       | #15556         |

**Why it keeps happening:** LLM behavior is unintuitive — "or" creates ambiguity the model resolves toward less work. Agent tools reimplement queries without the full filter stack. Symmetrical code blocks invite copy-paste transposition.

### 5. Query/Performance Issues (7 instances)

| Variant                                      | Example PRs |
| -------------------------------------------- | ----------- |
| OR across joins → can't use indexes          | #15336      |
| Relations loaded but not needed              | #15248      |
| Conditional join breaks downstream alias     | #15498      |
| LEFT JOIN + IS NULL fails with multiple rows | #14794      |
| Sequential await in loop (N+1)               | #15766      |
| Missing `hostId` → multi-tenant data leak    | #15234      |
| Cursor pagination missing unique tiebreaker  | #15640      |

### 6. Feature Flag + Config Data Mismatch (5 instances)

| Variant                                  | Example PRs          |
| ---------------------------------------- | -------------------- |
| Config data used without checking flag   | #15265 (trial price) |
| No data migration when renaming fields   | #15706 (consent)     |
| Boolean flag enabled without dependency  | #15390 (waiver)      |
| Default should be opt-in, set to opt-out | #15339 (AI agent)    |
| Required Zod fields + absent API data    | #15730 (form lock)   |

### 7. Financial/Money Bugs (5 instances)

| Variant                                  | Example PRs | Impact                |
| ---------------------------------------- | ----------- | --------------------- |
| Mixed VAT basis in arithmetic            | #15761      | Wrong renewal charge  |
| Fee applied multiple times in recursion  | #15264      | Overcharged customers |
| Soft-deleted records in financial counts | #15737      | Inflated payroll      |
| Payment method asymmetry (card vs debit) | #15565      | Wrong retry fee       |
| `undefined` fails to clear a price       | #14771      | Stale trial price     |

### 8. TypeORM Quirks (5 instances)

| Quirk                                      | PR     |
| ------------------------------------------ | ------ |
| Entity subscriber mutates in-memory object | #15720 |
| Upsert ignores NULL in conflict columns    | #15524 |
| `ALTER COLUMN SET NOT NULL` locks table    | #15279 |
| `.update()` throws on all-undefined fields | #15759 |
| `.exist()` deprecated, use `.exists()`     | #14829 |

---

## Top PR Review Comment Concerns (from 42 comment-analyzed PRs)

### 1. Missed Reuse of Existing Components/Services (15+ instances)

The single most common review feedback across the entire team. Reviewers flagged:

- Manual `getTags()` + `ComboboxInput` instead of `TagSingleSelectInput`
- Raw `FlatDateTimePicker` binding instead of `IsoDateInput`
- Custom styled components instead of `Box`/`Text`
- `useRibbonQuery` instead of `useMomenceQuery`
- Inline tag operations instead of `addTagsToCustomer`/`assignTagsToCustomer`
- Manual name formatting instead of `formatFullName`
- Custom sort instead of `orderMembershipList`

### 2. Destructuring / Naming / Style (10+ instances)

- "Destructure early" — accessing `params.hostId` repeatedly
- One-letter variable names (`a`, `b`) instead of `it` or full names
- Magic numbers not extracted to `UPPER_SNAKE_CASE` constants
- Enum names too generic for their actual scope (`TimeUnits` vs `BookingTimeWindowUnits`)
- Missing "why" comments (only "what" comments)

### 3. Frontend Patterns (8+ instances)

- `px` instead of `rem` for spacing
- Missing `$` prefix on styled-component transient props
- `grouped: true` + `wrap: true` on `ChoiceInput` (visually broken)
- Inline `[]` default creating reference instability
- `useFormContext` instead of `useRibbonFormContext` (crashes)
- Abbreviations in translation strings

### 4. AI Agent Tool Design (7+ instances)

- Tool/prompt alignment: tool available but no prompt guidance (or vice versa)
- Read-only tools gated behind action toggles
- Tool responses with `null` fields instead of sparse objects
- Missing `SupportAgentEffectTypes` for action tools
- Agent-perspective messaging vs system/host perspective

### 5. Entity/Migration Design (6+ instances)

- `AuditColumnsWithDelete` not used for new entities
- Missing `deletedAt: IsNull()` in queries
- FK constraints not named explicitly → entity/DB drift
- `@ManyToMany` used instead of junction table
- Missing both sides of a relation
- Enum values not matching between backend and frontend

### 6. Testing Gaps (5+ instances)

- No tests for new services or bug fixes
- Tests that only check job enqueue status, not final DB state
- Missing tests for edge cases (zero values, null fields, concurrent access)
- `toEqual` too strict for responses with optional fields → `expect.objectContaining`

---

## Cross-Cutting Observations

### The "Silent Failure" Meta-Pattern

The single most dangerous meta-pattern across all categories: **code that fails without any visible signal**. This manifests as:

- `try/catch` with only `logger.error` (no Sentry)
- `return null` instead of `throw`
- TypeScript optional fields that compile fine when absent
- TypeORM queries that return empty results instead of erroring
- `default: break` in switches that silently drops new enum values
- Feature flags that default to enabled instead of disabled

### The "Two Code Paths" Risk

Many bugs occurred when a feature had two entry points (dashboard vs plugin, card vs debit, member vs lead) and one path was updated while the other was forgotten:

- Dashboard vs plugin diverging on job metadata (#15735)
- Card vs direct debit creating different DB state (#15565)
- Manual response types diverging from generated types (#15288)
- Agent tools reimplementing queries without the full filter stack (#15286)

### Time Investment Pattern

Bug fixes averaged ~50 lines changed. The bugs with the highest blast radius (money, data integrity, silent failures) were typically 1-5 line fixes — a missing field, a wrong operator, an inverted condition. The complexity was in _finding_ the root cause, not in the fix itself.
