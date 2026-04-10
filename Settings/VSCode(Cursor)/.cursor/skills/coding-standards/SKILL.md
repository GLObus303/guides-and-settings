---
name: coding-standards
description: TypeScript coding standards and naming conventions for Momence. Use when writing new code, refactoring, or reviewing code style. Covers function parameters, type safety, error handling, naming conventions, and utility usage.
---

# Coding Standards

## General TypeScript Style

**Core Principles:**

- **Respect ESLint** - Only ignore rules when absolutely necessary
- **Prefer arrow functions** over function declarations
- **Infer types** instead of explicit typing (unless needed for clarity)
- **Prefer `const`** over `let`
- **Name magic numbers** - Extract numeric literals into named `UPPER_SNAKE_CASE` constants (e.g., `const MAX_CANVAS_WIDTH = 630`)
- **One exported service function per file** - Don't combine multiple service functions in a single file
- **Reuse existing services** - Search for existing utilities/services before writing new ones (e.g., `addTagsToCustomer` not a custom tagging function)
- **When in doubt:** Use the style most common in the codebase

**Function Parameters:**

```typescript
// ❌ Avoid: Positional arguments (error-prone)
function assignRole(userId: number, roleId: number)

// ✅ Prefer: Param objects (self-documenting)
type Params = { userId: number, roleId: number }
const assignRole = ({ userId, roleId }: Params) => { ... }
```

**Destructuring:**

```typescript
// ❌ Avoid: Accessing properties repeatedly via object
const handler = (params, args) => {
  log.info({ hostId: params.hostId });
  await getPolicy({ hostId: params.hostId });
  await repo.find({
    where: { hostId: params.hostId, memberId: params.memberId },
  });
};

// ✅ Prefer: Destructure early, use directly
const handler = ({ hostId, memberId, utils: { log } }, { subscriptionId }) => {
  log.info({ hostId });
  await getPolicy({ hostId });
  await repo.find({ where: { hostId, memberId } });
};
```

**Type Safety:**

```typescript
// ❌ Never use @ts-ignore
// ✅ Cast to any if truly needed (explicit intention)
(someUnsafeCode as any)();
```

**Strict Boolean Expressions:**
Don't rely on implicit type coercion to boolean. `0` is falsy, `""` is falsy — use explicit comparisons for all types, not just numbers.

**Null/undefined checks — use `isNil`/`isNotNil`:**

```typescript
// ❌ Avoid: Non-strict equality operators
if (memberId != null) { ... }
if (value == null) { return }

// ✅ Prefer: Type guard utilities from @/utils/typeGuards
import { isNil, isNotNil } from '@/utils/typeGuards'
if (isNotNil(memberId)) { ... }
if (isNil(value)) { return }
```

**Falsy Checks on Numbers (specific case):**

```typescript
// ❌ Avoid: Truthiness check (0 is falsy, breaks valid values)
if (freezeFeeAmount) {
  applyFee();
}

// ✅ Prefer: Use isNotNil when 0 is a valid value
if (isNotNil(freezeFeeAmount)) {
  applyFee();
}
```

**Comments:**

```typescript
// ❌ Avoid: Comments that restate what the code does
const existingSlot = await loadEventTypeSlot({ intentNodeId, manager }) // Load existing slot
const result = await doEventTypeIdentification({ ... }) // ALWAYS re-evaluate with LLM

// ✅ Prefer: Only comment the "why", not the "what"
// Re-evaluate even when a previous slot exists — the member may have clarified their intent
const result = await doEventTypeIdentification({ ... })
```

**Iteration:**

```typescript
// ✅ Prefer for...of over forEach
for (const item of items) { ... }

// ✅ reduce is fine for accumulation/transformation
```

**RegExp with `.test()` — avoid `g` flag on module-level constants:**

```typescript
// ❌ Dangerous: g flag makes .test() stateful (lastIndex persists between calls)
const bodyRegex = /^(Loved|Liked) ".+"$/gi;
const check = (s: string) => bodyRegex.test(s); // alternates true/false on repeated calls!

// ✅ Safe: omit g flag when using .test() on a reusable regex
const bodyRegex = /^(Loved|Liked) ".+"$/i;
const check = (s: string) => bodyRegex.test(s);
```

**Send `null` not `undefined` to clear nullable DB fields:**
`undefined` is stripped from JSON bodies, so `field: undefined` silently skips the update. Use `null` to explicitly clear:

```typescript
// ❌ Bug: field is silently skipped, old value persists
freeTrialEndsAt: data.freeTrialEndsAt ?? undefined;

// ✅ Fix: null explicitly clears the DB column
freeTrialEndsAt: data.freeTrialEndsAt ?? null;
```

**Uniqueness validation on update must exclude the current record:**

```typescript
// ❌ Bug: editing without changing the code always fails uniqueness check
const exists = await repo.exists({ where: { code, hostId } });

// ✅ Fix: exclude the record being edited
const exists = await repo.exists({
  where: { code, hostId, id: Not(entityId) },
});
```

**`null` vs `undefined` on TypeORM relations** — see `/typeorm` skill (Relations section). `undefined` = never loaded, `null` = loaded and absent.

**Never match domain records by translated/user-visible strings:**
Translated strings change with Crowdin/i18n updates. Always use a stable machine-readable identifier (enum column, predefined type) for lookups:

```typescript
// ❌ Bug: breaks when translation changes
const seq = sequences.find((s) => s.name === "Child Maturity Sequence");

// ✅ Fix: stable identifier
const seq = sequences.find(
  (s) => s.predefinedType === PredefinedSequenceType.CHILD_MATURITY,
);
```

**`NaN` is falsy but not nullish — `?? 0` doesn't guard against it:**

```typescript
// ❌ Bug: NaN ?? 0 = NaN (nullish coalescing doesn't catch NaN)
const total = values.reduce((sum, v) => sum + (v ?? 0), 0);

// ✅ Fix: || 0 catches both null/undefined AND NaN
const total = values.reduce((sum, v) => sum + (v || 0), 0);
```

**Exhaustive enum-to-enum mapping via const record:**
When translating between two enums, use a `{ [key in SourceEnum]: TargetEnum }` const — TypeScript enforces completeness with no `switch` needed:

```typescript
const sourceToTarget: { [key in RibbonMemberSources]: CreateUserSource } = {
  [RibbonMemberSources.WIDGET]: CreateUserSource.PLUGIN,
  [RibbonMemberSources.API]: CreateUserSource.PUBLIC_API,
  // ... TypeScript errors on any missing key
};
```

**No self-referencing workspace imports:**
Within a frontend app (e.g., `host-dashboard`), never import using the app's own package name. Use `@/` path aliases or relative imports:

```typescript
// ❌ Bug: circular reference risk
import { Something } from "@momence/host-dashboard/utils/foo";

// ✅ Fix: use alias or relative
import { Something } from "@/app/utils/foo";
```

**Narrow `try/catch` scope:**
Don't wrap entire function bodies in `try/catch`. Scope the catch to the specific operation that can fail:

```typescript
// ❌ Bad: hides which line failed
try { const a = await fetchA(); const b = await fetchB(); await save(a, b) } catch (e) { ... }

// ✅ Good: fallible operation isolated, primary flow continues
const a = await fetchA()
let b: B | undefined
try { b = await fetchB() } catch (e) { captureErrorBySentry(e); return }
await save(a, b)
```

**Hoist invariant computations out of loops:**
Values constant across iterations (timezone lookups, config reads, format strings) go before the loop:

```typescript
// ❌ Wasteful: async lookup on every iteration
for (const item of items) {
  const tz = await getHostTimeZone(hostId);
  formatDate(item.date, tz);
}

// ✅ Hoist: computed once before the loop
const tz = await getHostTimeZone(hostId);
items.map((item) => formatDate(item.date, tz));
```

**Avoid deep subpath imports from packages:**
Internal dist/lib paths (`pkg/dist/...`, `pkg/lib/...`) are fragile — they break on minor version bumps when the package restructures internals. Use public entry points when available:

```typescript
// ⚠️ Fragile: internal path can break on package updates
import { ExtendedError } from "socket.io/dist/namespace";

// ✅ Prefer: public entry point
import { ExtendedError } from "socket.io";
```

Note: the codebase still has some legacy deep imports that haven't been migrated yet.

**Boolean flags depending on nullable entities must be co-validated:**
When saving a feature flag that requires an associated entity (e.g., `showWaiverCheckbox` requires a waiver), assert the dependency exists in the same request. When clearing the dependency, auto-reset the flag:

```typescript
// Backend save — assert dependency
if (!waiver && showWaiverCheckbox)
  throw new BadRequest("Cannot enable without a waiver set.");

// Backend delete — auto-reset flag
await repo.update(hostId, {
  terms: null,
  ...(terms === null ? { showWaiverCheckbox: false } : {}),
});
```

**Conversion layers need full field mapping audits:**
When translating between external API models and internal models (e.g., `convertPublicApiCheckoutToCart`), every field on the internal model must be mapped — especially fields added by later features. Use `null → undefined` coercion (`?? undefined`) for nullable DB fields mapped to optional TS fields.

**Feature flag + config data guards:**
When a feature can be toggled off without clearing its config data, every consumer must guard with `flag && data`:

```typescript
// ❌ Bug: Shows stale trial price when trial is disabled
totalPrice = paidTrialAmount ? paidTrialAmount : regularPrice;

// ✅ Guard with feature flag
totalPrice = freeTrial && paidTrialAmount ? paidTrialAmount : regularPrice;
```

Extract repeated flag+data conditions to a named variable: `const isPaidTrial = !!freeTrial && paidTrialAmount > 0`

**Supplementary updates after the primary operation:**
When adding metadata updates (e.g., writing to a secondary table) alongside a critical operation (e.g., sending an email), place them _after_ the primary operation succeeds, or wrap them in their own try/catch. If inserted before and they throw, the primary operation is aborted:

```typescript
// ❌ Bug: metadata update failure aborts the email send
await updateConversationEntry(entryId, { source }); // throws if source is undefined
await sendEmail(template); // never reached

// ✅ Fix: primary operation first, metadata update can fail independently
await sendEmail(template);
try {
  await updateConversationEntry(entryId, { source });
} catch (e) {
  captureError(e);
}
```

**Concurrency:**

```typescript
// ❌ Avoid Promise.all for N > 10
// ✅ Use parallelRun to limit concurrent promises
import { parallelRun } from "@/utils/parallelRun";
await parallelRun(manyPromises, { limit: 5 });
```

**`Promise.all` won't speed up DB queries:**
DB connection pooling means a single connection can only run one query at a time. `Promise.all` for DB queries just adds overhead. Stick to serial awaits for DB operations. Only use `parallelRun`/`Promise.all` for genuinely independent I/O (external API calls, file operations).

**Money values:**

- Backend: Use `BigNumber` library (`bignumber.js`) for money calculations
- DB: Use `decimal` type with `ColumnDecimalTransformer` in entities
- API boundaries: Use `string` for money values to avoid floating-point precision loss
- Sensitive calculations should be done on backend, not frontend

**Grouping Arrays by Key:**

```typescript
import { groupBy, keyBy } from "@/utils/collections";

// ✅ Use groupBy utility (returns Map<Key, Item[]>)
const tagRowsByMode = groupBy(tagRows, (row) => row.mode);

// ✅ Use keyBy utility for lookups (returns Record<Key, Item>)
const templatesById = keyBy(templates, "id");
```

**Updating Related Entities (Junction Tables):**

```typescript
// ❌ Avoid: Delete all + insert all (loses audit trail)
// ✅ Prefer: Diff + selective delete/insert
import { diffIdArrays } from "@/utils/diffIdArrays";
import { saveEntities } from "@/utils/saveEntities";

const { add: tagIdsToAdd, remove: tagIdsToRemove } = diffIdArrays(
  existingTagIds,
  newTagIds,
);
```

**Audit Columns:**

```typescript
// ❌ Avoid: Hardcoded values (createdBy: -1)
// ✅ Prefer: Pass triggeredBy (userId) through the call chain
type Params = { hostId: number; triggeredBy: number };
```

**Soft Delete (AuditColumnsWithDelete):**

- Prefer `AuditColumnsWithDelete` over `AuditColumns` for new entities
- Always filter `deletedAt: IsNull()` when querying
- Use `softDeleteRecord()` utility for soft deletes
- **Prefer inserting new rows over restoring soft-deleted ones** for junction tables (e.g., tag assignments, membership sharing). Setting `deletedAt: null` on a previously deleted row breaks the audit trail. Instead: fetch non-deleted rows, diff against desired set, insert missing ones as new rows. Exception: explicit undo/restore features where un-deleting is the intended UX.
- For entity design details (data types, relations, properties order), use the `/typeorm` skill

**State-transition updates, upserts, and ownership checks** — see `/typeorm` skill for WHERE guard patterns (`affected === 0` check), `orUpdateTyped` for audit-safe upserts, and `doXBelongToHost` soft-delete caveats.

**Access-gating services must include ALL invalidation conditions in the query:**
Services that gate access to paid content or time-limited resources must filter by every invalidation state (`isVoided`, `deletedAt`, expiry dates) in the DB WHERE clause — not rely on callers to check:

```typescript
// ❌ Bug: Voided/expired bookings still grant access
const booking = await repo.findOneOrFail({ where: { link, memberId } });

// ✅ Fix: All invalidation conditions in the query
const booking = await repo.findOneOrFail({
  where: { link, memberId, isVoided: false, deletedAt: IsNull() },
});
if (booking.endDate && booking.endDate < new Date())
  throw new NotFoundException();
```

**Money-touching parameters in recursive/fan-out calls:**
When a parent action fans out to child records, any parameter that controls charges (`applyFee`, `chargeNow`, `skipPayment`) must be explicitly reviewed at each fan-out point. Hardcode business constraints at the recursion boundary — don't pass through from callers.

**Service Function Parameters (Testability):**

```typescript
// ✅ Services should accept optional manager and triggeredAt for testability
type Params = {
  hostId: number;
  manager?: EntityManager; // Allows transaction context & testing
  triggeredAt?: Date; // Consistent timestamps across batch operations
};

// ✅ Prefer: defaults in destructuring
export const myService = async ({
  hostId,
  manager = getManager(),
  triggeredAt = new Date(),
}: Params) => {
  // Use manager.getRepository() directly — no alias needed
};

// ❌ Avoid: alias + fallback pattern
export const myService = async ({ manager: managerParam }: Params) => {
  const manager = managerParam ?? getManager(); // unnecessary indirection
};
```

**Result Pattern (OptionalResult):**

```typescript
// ✅ Use OptionalResult for operations that can fail without throwing
import { success, Success } from "@/utils/success";
import { failure, Failure } from "@/utils/failure";
import { isFailure, isSuccess, OptionalResult } from "@/utils/optionalResult";

// Service returns success or failure with typed data/error
export const validateFreeze = async (
  params: Params,
): Promise<OptionalResult<FreezeData, string>> => {
  if (freezeCount >= maxFreezes) {
    return failure(`Max freezes reached (${freezeCount}/${maxFreezes})`);
  }
  return success({ freezeCount, remaining: maxFreezes - freezeCount });
};

// Caller uses type guards to handle result
const result = await validateFreeze(params);
if (isFailure(result)) {
  return { error: result.error }; // result.error is typed as string
}
// result.data is typed as FreezeData
const { freezeCount, remaining } = result.data;
```

**When to use OptionalResult vs throwing:**

- ✅ Use `OptionalResult` for expected failures (validation, policy checks, user input)
- ✅ Use `OptionalResult` when caller needs to handle failure gracefully with context
- ❌ Use `throw` for unexpected errors (DB failures, programming bugs)

**Time Calculations (Use dayjs):**

```typescript
// ❌ Avoid: Manual milliseconds math (error-prone, hard to read)
const deadline = new Date(request.sentAt.getTime() + hours * 60 * 60 * 1000);

// ✅ Prefer: dayjs for readable time calculations
import dayjs from "dayjs";
const deadline = dayjs(request.sentAt).add(hours, "hours").toDate();
```

**String Literals vs Enums:**

```typescript
// ❌ Avoid: String literal types (refactoring risk)
type ReminderType = "reminder1" | "reminder2";

// ✅ Prefer: Enums for type safety and refactoring
export enum ReminderType {
  REMINDER_1 = "reminder1",
  REMINDER_2 = "reminder2",
}
```

**When NOT to use enums:** Enums are for fixed compile-time sets. Don't use enums (or lookup tables) for dynamic values defined by workflows or configuration at runtime — use plain strings instead.

**Document Entity Properties:**
Write doc-blocks over entity properties with full description of the feature/behavior driven by the property. Omit for obvious fields (`createdAt`, `name`).

**Avoid Arbitrary Defaults:**
Don't use meaningless defaults in code. Force explicit values. If defaults are necessary, use non-arbitrary ones (`0`, `""`, `null`). For mock generators: always allow overriding any property.

**saveEntity Usage:**

```typescript
// ❌ Avoid: Using .create() with saveEntity (redundant)
await saveEntity(Entity, repo.create({ field: value }));

// ✅ Prefer: Pass object directly to saveEntity
await saveEntity(Entity, { field: value }, entityManager);
```

**Deprecated APIs:**
Check for `@deprecated` JSDoc tags on methods before using them. Prefer the non-deprecated replacement:

```typescript
// ❌ Avoid: Deprecated method
await myJob.findOneBy({}); // @deprecated — use typedFindOneBy
await myJob.findBy({}); // @deprecated — use typedFindBy

// ✅ Prefer: Current method
await myJob.typedFindOneBy({});
await myJob.typedFindBy({});
```

**Trace ID pattern for async job chains:**
When a job fans out to batched sub-jobs, generate a UUID at the outermost entry point and thread it through all metadata. Include it in every log line via a shared context object:

```typescript
const traceId = uuid();
const logContext = { traceId, hostId, jobId };
logger.info(logContext, "Job started");
// ... pass traceId in job metadata to sub-jobs
```

**Failure classifier for batch operations:**
When a batch operation can fail per-item (e.g., sending SMS to N recipients), create a pure `classifyError(error): { kind }` function and aggregate counters. Log one structured summary at batch end:

```typescript
logger.info(
  {
    sentCount,
    failedCount,
    classifiedFailures: { invalid_number: 3, provider_error: 1 },
  },
  "Batch complete",
);
```

**Logger Messages (Pino):**

```typescript
// ❌ Avoid: logger.info with only data object (no message)
logger.info({ windowStart, windowEnd, count: reminders.length });

// ✅ Prefer: Always include a message string as 2nd argument (enables Datadog search/grouping)
logger.info(
  { windowStart, windowEnd, count: reminders.length },
  "Processing reminders",
);

// ❌ Avoid: Interpolating values into the message string (creates unique messages, breaks Datadog grouping)
logger.info(
  `Processing ${reminders.length} reminders for window ${windowStart}-${windowEnd}`,
);

// ✅ Prefer: Static message + structured params (searchable and groupable in Datadog)
logger.info(
  { windowStart, windowEnd, count: reminders.length },
  "Processing reminders",
);
```

**SMS: Store hostLimitedSentSmsId:**
When using `sendLimitedHostSms`, the `onSuccess` callback receives the sent message. Always store `message.id` as `hostLimitedSentSmsId` in `HostSentTransactionalMessages`:

```typescript
onSuccess: async (message) => {
  await saveEntity(
    HostSentTransactionalMessages,
    {
      // ... other fields
      hostLimitedSentSmsId: message.id,
    },
    entityManager,
  );
};
```

---

## Naming Conventions

**Enums:**

```typescript
enum UserTypes {
  // PascalCase, plural
  ADMIN_USER = "admin-user", // Keys: UPPER_SNAKE_CASE, Values: lower-kebab-case
}
```

**Constants:** `UPPER_SNAKE_CASE`
**Functions/Variables:** `camelCase`
**Classes/Components:** `PascalCase`
**File names:**

- **Frontend (React):** `PascalCase` for components (e.g., `HostDetail.tsx`), `camelCase` for utils/hooks
- **Backend (NestJS):** `kebab-case` for all files (e.g., `host-members.controller.ts`, `host-member.dto.ts`)
- **Backend (Express/services):** `camelCase` (e.g., `getMemberDetails.ts`)
  **Folders:** `camelCase` for regular folders, `PascalCase` for component folders
  **Database Columns:** `snake_case` (TypeScript: `camelCase`) - TS property must be a direct camelCase conversion of the DB column name (e.g., `pool_source_id` → `poolSourceId`, NOT `poolRecordSourcedId`). Name columns by purpose/context, not just data type.
  **FK Column Names:** Include the full referenced entity name as prefix. Match the entity class name, not just the table suffix:

```typescript
// ❌ Avoid: Dropping the entity prefix
inboxConversationId; // references HostInboxConversations

// ✅ Prefer: Full entity prefix in FK column name
hostInboxConversationId; // matches HostInboxConversations
```

**Internal vs External IDs:** When storing both our internal ID and a third-party external ID for the same concept, make the distinction explicit:

```typescript
// ❌ Ambiguous: whose ID is this?
exportId: number;

// ✅ Clear: prefix indicates origin
internalExportId: number; // our system's ID
externalFiskalyExportId: string; // third-party's ID
```

**Enum Scope in Names:** Enum names must reflect their actual scope. A narrowly-used enum with a broad name is misleading:

```typescript
// ❌ Implies universal reusability
enum TimeUnits {
  MINUTES = "minutes",
  HOURS = "hours",
}

// ✅ Scoped to actual usage
enum BookingTimeWindowUnits {
  MINUTES = "minutes",
  HOURS = "hours",
}
```

**Exports - Be Specific:**

```typescript
// ❌ Too generic
export const getFilters = () => { ... }

// ✅ Prefixed and specific
export const getAppointmentListFilters = () => { ... }
```

**Function Naming:**

- **Be descriptive** - Exports are global
- **Don't shorten words** - `getUserInfo` not `getUsrInf`
- **Use `assert*`** - When function throws on invalid state (e.g., `assertProductCodeIsUnique`)
- **Use `expect*`** - For test helpers
- **Use `can*`** - For guard functions that return boolean (e.g., `canAccessReport`)

**`continue` vs `break` in nested loops:**
When the intent is "stop processing this inner iteration and advance the outer loop", use `break` (not `continue`). `continue` advances the _inner_ iterator, not the outer one:

```typescript
// ❌ Bug: continue advances inner loop, outer never processes new entry
for (const journey of journeys) {
  for (const step of steps) {
    if (denied) {
      journeys.set(nextId, next);
      continue;
    } // wrong — stays in inner loop
  }
}

// ✅ Fix: break exits inner loop, outer loop advances to new entry
for (const journey of journeys) {
  for (const step of steps) {
    if (denied) {
      journeys.set(nextId, next);
      break;
    } // correct — returns to outer loop
  }
}
```

**Extract complex boolean conditions to named variables:**

```typescript
// ❌ Avoid: condition repeated or hard to understand
if (futureBookingsExists || currentBookingsCount > 1) { ... }

// ✅ Prefer: named variable documents the business concept
const isRetained = futureBookingsExists || currentBookingsCount > 1
if (isRetained) { ... }
```

**Store IDs in state, derive objects from fresh query data:**
For components with polling/refetch, never put full entity objects into `useState`. Store only the `id` and derive the object from the latest query data via `useMemo`:

```typescript
// ❌ Bug: object in state goes stale after refetch
const [selected, setSelected] = useState<Item | null>(null);

// ✅ Fix: store ID, derive from fresh data
const [selectedId, setSelectedId] = useState<number | null>(null);
const selected = useMemo(
  () => items.find((i) => i.id === selectedId),
  [items, selectedId],
);
```

**Iterator Variables:** Use full name or `it` (NOT `x` or `a`)

---

## Domain Terminology

| Business Term        | Code Name                        | Notes                                                                                    |
| -------------------- | -------------------------------- | ---------------------------------------------------------------------------------------- |
| Host                 | `Host` / `Hosts`                 | Business/individual that is a direct Momence client                                      |
| Member / Customer    | `RibbonMembers`                  | End user of a Host. Use `{customer}` placeholder in translations                         |
| Class / Session      | `Sessions`                       | In code always "Session". `FITNESS` type = regular/default                               |
| Membership           | `Memberships`                    | Types: `Subscription`, `PackageEvents`, `PackageMoney`, `OnDemandSubscription`, `Patron` |
| Package / Pack       | `PackageEvents` / `PackageMoney` | Both used in code and UI                                                                 |
| Class Credits        | `ClassCredits`                   | Legacy name: `EventCredits`                                                              |
| Bought Membership    | `BoughtMemberships`              | An instance of a purchased membership                                                    |
| Teacher / Instructor | varies                           | Customizable per host via wording system                                                 |

---

**Props vs Params:**

- React components: `Props` (include component name when exporting: `export type HostDetailProps = { ... }`)
- Everything else: `Params` (include function name when exporting: `export type AssignRoleParams = { ... }`)
- Non-exported types can use plain `Props` or `Params`

---

## Backend Utilities Registry (Commonly Missed)

Before writing custom logic, check if one of these already exists in `backend/utils/`.

**Collections (`collections.ts`):**

| Instead of...                   | Use                               | Notes                                               |
| ------------------------------- | --------------------------------- | --------------------------------------------------- |
| `Array.reduce` for grouping     | `groupBy` / `keyBy`               | `Map<Key, Item[]>` / `Record<Key, Item>`            |
| Manual add/remove diff logic    | `diffIdArrays` / `getIdsDiff`     | Returns `{ add, remove }` for junction tables       |
| `[...new Set(arr)]`             | `deduplicate` / `deduplicateBy`   | Handles objects via key function                    |
| Two `.filter()` calls for split | `partition(arr, predicate)`       | Returns `[matches, nonMatches]`                     |
| Manual chunking loop            | `splitArrayIntoChunks(arr, size)` | Or `iterateChunks` (generator, memory-efficient)    |
| `arr.reduce((a,b) => a+b, 0)`   | `sum(arr)` / `sumBy(arr, field)`  | Also handles BigNumber via `sumBigNumberProperties` |

**Async / Control flow:**

| Instead of...                    | Use                                          | Notes                                            |
| -------------------------------- | -------------------------------------------- | ------------------------------------------------ |
| `Promise.all` for >10 promises   | `parallelRun(items, N, callback)`            | Concurrency-limited (positional args)            |
| Side effects inside transactions | `executeAfterTransactionCommit(manager, fn)` | Runs only after tx commits                       |
| Manual retry loops               | `createRetry({ maxRetries, retryDelay })`    | Reusable retry wrapper                           |
| 100k+ IDs in single `IN` clause  | `loadByIds(ids, loadFn)`                     | Auto-chunks to stay under PG's 65536 param limit |

**Formatting:**

| Instead of...                 | Use                                     | Notes                                      |
| ----------------------------- | --------------------------------------- | ------------------------------------------ |
| `${first} ${last}`            | `formatFullName({firstName, lastName})` | Handles null/trim correctly                |
| Raw timezone string           | `humanizeTimeZoneName`                  | User-friendly display                      |
| `toLocaleString` for currency | `formatPrice(price, currency)`          | Consistent formatting                      |
| `n * 100` for Stripe amounts  | `convertCurrencyToStripeAmount`         | Handles zero-decimal currencies (JPY, KRW) |
| Manual `n * pct / 100`        | `calculatePercentage`                   | BigNumber-safe                             |
| Naive amount splitting        | `divideAmountAndPreserveTotal`          | Distributes remainder cents correctly      |

**Type guards (`typeGuards.ts`):**

| Instead of...                       | Use                                 | Notes                                                       |
| ----------------------------------- | ----------------------------------- | ----------------------------------------------------------- |
| `!!value` for null check            | `isNotNil(value)`                   | Type-narrows; `!!0` is false but `isNotNil(0)` is true      |
| Missing `default` in switch         | `assertUnreachable(x)`              | Compile-time exhaustiveness check                           |
| `if (!check) throw new Forbidden()` | `authAssert(check, msg)`            | One-liner auth assertion                                    |
| Manual `isFailure` + throw          | `assertSuccessOrBadRequest(result)` | Also: `assertSuccessOrNotFound`, `assertSuccessOrForbidden` |

**Result pattern:**

| Instead of...                   | Use                                | Notes                                 |
| ------------------------------- | ---------------------------------- | ------------------------------------- |
| Custom `{ ok, error }` objects  | `success(data)` / `failure(error)` | Standard `OptionalResult`             |
| `try { } catch { return null }` | `tryTo(fn)`                        | Wraps async fn into OptionalResult    |
| Manual isSuccess unwrap         | `getSuccessOrThrow(result)`        | Unwraps or calls fallback that throws |

**Database:**

| Instead of...              | Use                       | Notes                                                  |
| -------------------------- | ------------------------- | ------------------------------------------------------ |
| `IN ()` with empty array   | `safeInArray(arr)`        | Returns `[null]` for empty arrays (prevents SQL error) |
| Manual host currency query | `getHostCurrency(hostId)` | Cached                                                 |
| Manual host timezone query | `getHostTimeZone(hostId)` | Cached                                                 |
