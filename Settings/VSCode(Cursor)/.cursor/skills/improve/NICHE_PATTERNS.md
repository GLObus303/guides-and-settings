# Niche Patterns & Domain-Specific Knowledge

Patterns too specific for the main skills but worth knowing when working in these areas. Discovered during analysis of ~365 PRs (Sep 2025 — Mar 2026).

---

## Domain-Specific Entity Quirks

### SessionBookings: `hiddenAt` vs `deletedAt`

On `SessionBookings`, `deletedAt` means "cancelled" (cancelled bookings are still shown in some views). `hiddenAt` is the true soft-delete column. Active booking queries must filter both:

```typescript
where: { deletedAt: IsNull(), hiddenAt: IsNull() }
```

Filtering only `deletedAt: IsNull()` is a classic recurring bug ("the classic active booking issue").

### Phone Numbers Live in SmsContacts, Not RibbonMembers

To get a member's phone number, query `SmsContacts` with `{ memberId, hostId }` ordered by `id DESC`, then deduplicate by `memberId` using `distinctOn`. Don't look for it on the `RibbonMembers` entity.

### API V2 Uses "Tax" Not "VAT"

In `backend/src/modules/api-v2/`, field names use `Tax` (e.g., `priceIncludingTaxInCurrency`) — not `VAT`. Internal/host-dashboard code uses `Vat`. Don't "fix" API V2 names to match internal naming.

### Payment Transaction: `null` relation vs `undefined` relation

- `undefined` = relation was never loaded (programming error — log a warning)
- `null` = relation was loaded and is genuinely absent (valid data state — handle gracefully, don't throw)

This matters for: `purchasedByPaymentTransaction`, `membership`, `boughtMembership.membership`

---

## Payment/Checkout Patterns

### Mixed Weight Modes in Cart

The cart's `calculateWeights` has a mode switch: any `weightRelative` on any payment method switches the whole cart to relative mode. Always use `weightRelative` in automated/off-session flows; `weightAmountIncludingVat` only for POS flows.

### `isFree` Must Be Computed After All Price Transformations

Don't derive `isFree` from the raw base price — compute it after discount rules, dynamic pricing, and price rules are applied. Return `isFree` as part of the price metadata object.

### Card vs Direct Debit Create Different DB State on Failure

Card failures create a new `BoughtMembership` with `paymentStatus = FAILED` + `failure` relation. Direct debit failures may not. Detect failures via data (`paymentStatus + failure relation`), not job metadata (`isAutomaticRerun`).

### Stripe Amount Conversion for Zero-Decimal Currencies

Use `convertCurrencyToStripeAmount` — it handles JPY, KRW, etc. where 1 unit = 1 cent. Don't manually `* 100`.

---

## NestJS-Specific

### `@HttpCode` Required on Non-Default Status Endpoints

NestJS defaults to 201 for POST, 200 for GET. DELETE endpoints returning 200 (not 204), or any non-default status, must have `@HttpCode(HttpStatus.OK)`. Always add `@ApiResponse` too.

### Don't Manually Cast Return Values to DTO Type

NestJS serializes automatically when the response DTO is a subset of the service return. Don't add `as ResponseDto` or spreads — just return the service result.

### `@ApiExtraModels` for Discriminated Union Members

When a DTO uses discriminated unions and concrete types are only referenced via `$ref`/`allOf`, add `@ApiExtraModels(ConcreteTypeA, ConcreteTypeB)` on the controller action. Otherwise Swagger silently omits those model schemas.

### Nested DTOs Each Need Their Own `.dto.ts` File

All DTO classes — including nested/embedded ones — must be in their own `.dto.ts` files. The nestjs skill previously said non-exported DTOs could share a file; reviewers explicitly corrected this.

---

## Scheduled Jobs Domain

### Failed Payment in Recurring Job Should Reverse the Triggering State

When a scheduled job's payment fails (e.g., freeze fee), immediately reverse the triggering state change (unfreeze) and notify both parties. Don't silently retry — members stay stuck.

### Cancellation Scope Must Match or Exceed Scheduling Scope

Items can leave "active" status after scheduling but still need job cleanup. Query by the record's own state (`scheduledAt IS NOT NULL`), not derived activity status.

---

## i18n / Translation Gotchas

### Crowdin Pluralization Stem Collision

When a key has `_one`/`_other` suffixed siblings, Crowdin treats the shared stem as a pluralization root. A key using the stem without suffix is ignored. Use a different name for the non-plural variant.

### `{customer}` Placeholder Applies Cross-App

Not just host-dashboard — corporate-dashboard and member-portal must also use `{customer}` (not "member" or "donor").

### Named Placeholders Over Positional

Prefer `{{limit}}` / `{{percent}}` over `{{0}}` / `{{1}}` for readability.

---

## Testing Patterns

### Test Array Operations by Targeting Middle Items

When testing slice/range operations, target items in the middle so boundary items on both sides are provably untouched.

### Test Fixture Emails Must Be Semantically Valid

Use `@momence.com` or `@example.com` — never pass integers or structurally invalid strings as email fields.

### E2E Feature Flag Setup Belongs in Playwright Fixtures

Use fixtures with cleanup in the `use()` clause, not inline in the test body. Fixture failures are immediately identifiable as setup issues.

### Don't Expand Existing E2E Tests for New Features

Add separate tests to keep failure attribution clear. Modifying an existing test for a new feature flag makes failures look like regressions in the original feature.

### Test Names Must Match Test Content

A test named "with insurance provider" that doesn't create an `InsuranceProviderDetails` fixture is misleading. All entities mentioned in the test name must exist as fixtures.

---

## AI Agent Domain

### Effect Type Groups Are Mandatory

When adding a new `SupportAgentEffectTypes`, always assign it to at least one `SupportAgentEffectTypeGroups`. Using `groups: []` silently hides it from the agent logs filter UI.

### Agent Log Queries Must Filter by Current Entity State

Agent logs can persist after the associated member/lead is soft-deleted or dissociated. Traverse the relation chain (`hostMemberLog → member → hosts`) to verify current membership.

### Adding a New Inbox Intent: 4 Required Changes

1. Enum: `HostDashboardInboxIntentTypes`
2. Migration: insert into `host_dashboard_inbox_intent_types_lookup`
3. Intent definition: `defineInboxIntent({ intent, description, examples })`
4. Routes: `getInboxIntentAgentsRoutes` + `getAllInboxIntents`

### Durable Workflow Init-Resolve Step Pattern

First workflow step takes minimal trigger params (`hostId` + message IDs), resolves entities/eligibility, returns full run params or `null` to terminate. `step()` requires JSON-serializable returns — use `?? null` not `?? undefined`.

---

## Infrastructure / DevOps

### Node 24: `useDefineForClassFields: false` Required

Without this tsconfig flag, class field initializers break TypeORM/NestJS entity decorator metadata.

### Sentry v8 Removes Hub API

`getCurrentHub()` is gone. Use `Sentry.getCurrentScope()` directly. `configureScope`, `startTransaction`, `transaction.finish()` all replaced. `@sentry/integrations` package merged into `@sentry/node` core.

### History Log Trigger Migration When Adding Columns

Tables with PostgreSQL audit triggers need a separate migration to regenerate all three trigger functions (INSERT/UPDATE/DELETE) when columns are added.

### Backfill Script Patterns

- Cursor-based batching: `id > :lastId` with `BATCH_SIZE` constant
- LEFT JOIN to find missing records: `.leftJoin(B, 'b', ...).andWhere('b.id IS NULL')`
- Always `--dry-run` by default
- `console.time` / `console.timeEnd` for duration tracking
