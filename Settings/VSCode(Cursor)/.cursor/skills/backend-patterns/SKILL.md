---
name: backend-patterns
description: Backend endpoint and service patterns for Momence. Use when creating Express routes, NestJS controllers, service functions, or working with guards, auth asserts, validators, and serializers.
---

# Backend Patterns

> New endpoints should use NestJS. Express routes are legacy but still maintained. For NestJS-specific patterns (controllers, DTOs, `@ApiField`, modules, pagination), use the `/nestjs` skill.

---

## Endpoint Patterns

> Express routes and NestJS controllers follow the same conceptual structure. Request validation and response serialization differ (superstruct vs DTOs), but the core responsibilities are the same.

**Endpoint Responsibilities (in order):**

1. Security and permissions (guards + auth asserts)
2. Request validation
3. Do the actual work (call services — **all DB access (reads AND writes) must go through service functions**, never query repositories inline in the controller/route handler)
4. Serialize the response

**Folder Structure (Express):**

- Endpoints in `routes/`, organized by app (`host-dashboard`, `member-portal`, `plugin`, `mobile`)
- **Don't reuse endpoints across apps** — each app has different auth, parameters, and context
- App folders divided by business domain (`appointments`, `staffAccounts`)
- Each domain folder has: controller files, `validators/`, `serializers/`, `auth/` subfolders
- Reusable logic belongs in `services/`, not in routes

**Guard Middleware:**

```typescript
permissionGuard(HostPermissions.X); // Host dashboard — specific permissions
permissionWildcardGuard; // Host dashboard — no specific permissions (rare for new endpoints)
memberRoleGuard; // Member portal endpoints
adminRoleGuard; // Admin panel endpoints
publicGuard; // Public endpoints (be explicit, don't leave blank)
hostAddonGuard(ApplicationAddonTypes.X); // Check host has specific add-on (requires hostId param)
```

**Auth Asserts:**
Validate the caller can access ALL entities being handled, not just the primary one:

```typescript
// Check primary entity
nestAuthAssert(await canAccessWorkout({ hostId, workoutId }));

// Also check related entities being modified
if (isNotNil(body.workoutTrackId)) {
  nestAuthAssert(
    await canAccessWorkoutTrack({
      hostId,
      workoutTrackId: body.workoutTrackId,
    }),
  );
}
```

Place auth assert functions in `auth/` subfolder. They typically perform simple validation queries (`exists`, `count`, `select`) to verify access.

**Guard Functions (NestJS):**
Guards live in `guards/` directory near controllers. Named with `can*` prefix, return `boolean`:

```typescript
// guards/canAccessCorporateReportRun.ts
export const canAccessCorporateReportRun = async ({
  hostId,
  reportRunId,
}: Params): Promise<boolean> => {
  return getRepository(CorporateReportRuns).exists({
    where: { id: reportRunId, hostId },
  });
};

// In controller:
assertGuard(await canAccessCorporateReportRun({ hostId, reportRunId }));
```

Don't import guards across modules — they belong to a single module. Keep guards simple, import services into them if needed.

**Request Validation (Express):**

- **Body:** Create superstruct validators in `validators/` subfolder, call `assert(req.body, validator)` as first action in endpoint
- **Path/Query params:** Use typed helpers (`getRequiredIntegerParams`, `getOptionalIntegerParams`, `getRequiredBooleanParams`, etc.)
- **Auth user:** `requireAuthenticatedUserId(req)` for `triggeredBy`

```typescript
import { object, size, string, array } from "superstruct";
import {
  email,
  positiveInteger,
  nullablePositiveInteger,
} from "@/utils/validation";

export const createUserValidator = object({
  email: size(email, 1, 100),
  firstName: size(string(), 1, 100),
  lastName: size(string(), 1, 100),
  roleIds: size(array(positiveInteger), 1, Infinity),
  hourlyRateId: nullablePositiveInteger,
});
```

**Request Validation (NestJS):** Use `@ApiField` in DTOs — see `/nestjs` skill for full details.

**Serializers:**

- **Never return full entities** from endpoints — it leaks data and couples API to DB model
- Serializers ensure endpoint stability — DB model changes don't accidentally change API responses

**Express routes:** Create serializer functions in `serializers/` subfolder using `serializeFields`:

```typescript
import { serializeFields } from "@/utils/objects";

export const roleSerializer = (role: Roles) =>
  serializeFields(role, [
    "id",
    "hostId",
    "predefinedRoleType",
    "name",
    "isTeacherRole",
    "isApplicationRole",
  ]);

// Usage in endpoint
res.json(roleSerializer(role));
```

**NestJS routes:** Use `@OkResponse(Dto)` decorator — the interceptor handles serialization via `plainToInstance`. For complex mapping, use serializer functions with `plainToInstance` (see `/nestjs` skill).

---

## Service Patterns

**Core Rules:**

- Services live in root `services/` folder (not in `routes/`)
- A service should **NOT validate its inputs** — the endpoint is responsible for permissions and providing correct parameters. This allows services to be reused across endpoints.
- One service = one responsibility. If a service is too long, break it into smaller services.
- **Get/read services must be pure** — no side effects (writes, notifications, assignments). If a get-or-create function needs to trigger actions on creation, return a flag (e.g., `{ id, isNew }`) and let the caller handle the side effect.
- **Don't add speculative features to existing services** — don't add extra queries or return fields unless there's a production consumer. If an existing service already handles the use case (e.g., upsert), don't add a `findOneBy` before it just to get an `isNew` flag that nothing uses.
- **Services vs Utils:** Services contain business logic on top of entity model. Utils are app-agnostic and could be used in any project (Stripe client, SMS client, reusable validators, dayjs fixes).

**Parameter Ordering:**
Maintain consistent parameter order in type definition, service signature, and all call sites:

1. Most important params first (IDs, entities)
2. Business logic params (flags, options)
3. Service properties last (`triggeredBy`, `manager`)

**Prefer ID Params Over Entities:**

- Services should be standalone and load their own data — prefer `appointmentReservationId` over `appointmentReservation`
- If passing an entity, don't rely on relations being loaded — state it explicitly in the param type or split into separate params (e.g., separate `appointmentAttendee`, `paymentTransaction`, `saleItem` instead of one entity with relations)

**Returning from Services:**

- Return an object defined in a `Result` type (prefix with service name if exported: `RecalculateCartResult`)
- Simple services can return plain values if the return type is obvious (e.g., boolean validation checks)

```typescript
type Result = {
  roleId: number | null;
  permissions: HostDashboardPermissions[];
};

export const translateRoleToPermissions = (
  userRole: EntityWithRelations<UserRoles, { role: { permissions: true } }>,
): Result => {
  // service implementation
};
```

---

## Backend Validation Patterns

**Never put input/schema validation logic in controllers — use DTOs for that.**
**Always use `@ApiField` in DTOs** (wraps class-validator, class-transformer, and Swagger in one decorator):

```typescript
import { ApiField } from "@/src/common/decorators/api-field";
import { ArrayMinSize, ValidateIf } from "class-validator";

export class SaveSettingsDto {
  @ApiField({
    type: "enum",
    enum: HostSupportAgentResponseCriteriaMode,
    optional: true,
    nullable: true,
  })
  responseCriteriaMode?: HostSupportAgentResponseCriteriaMode | null;

  @ValidateIf((o) => o.responseCriteriaMode != null)
  @ArrayMinSize(1, { message: "At least one tag is required when mode is set" })
  @ApiField({ type: "integer", array: true })
  responseCriteriaTagIds: number[];
}
```

Use raw class-validator decorators (`@ValidateIf`, `@ArrayMinSize`) only for advanced validation beyond what `@ApiField` provides. For full details on `@ApiField` types, DTOs, controllers, and modules, use the `/nestjs` skill.

**When controller validation IS appropriate:**

- Database-dependent validation (checking if IDs exist)
- Authorization checks (user permissions)
- Business logic that spans multiple entities

---

## Error Handling

**HTTP Error Classes:**
| Class | Code | Use When |
|-------|------|----------|
| `BadRequest` | 400 | Request can't be completed with provided params (most common) |
| `Forbidden` | 403 | User not authorized (wrong permissions, wrong scope, wrong hostId) |
| `NotFound` | 404 | Resource doesn't exist |
| `AppError` | — | For jobs and non-HTTP contexts |

**Error options:**

- `payload` — sent to client (user-facing context)
- `extra` — logged only (debugging context, not sent to client)
- `skipReporting` — suppress Sentry reporting
- `customFingerprint` — custom Sentry grouping

**Automatic throws:**

- `assert(condition)` → 400
- `authAssert(condition)` → 403
- `findOneOrFail()` → EntityNotFoundError
- `permissionGuard` → 401/403

Never rethrow 3rd party errors to client — catch, log, and throw your own error with appropriate context.

---

## Caching

**Internal caching library:**

```typescript
// 1. Define prefix in cachePrefixes.ts
export const MY_CACHE_PREFIX = "my-feature";

// 2. Create handler
const cache = createPrefixedCacheClient(MY_CACHE_PREFIX);

// 3. Cache-or-fetch pattern
const data = await cache.cachedCallback(
  `key-${hostId}`,
  async () => fetchExpensiveData(hostId),
  { ttl: 300 }, // seconds
);

// 4. Invalidate
await cache.unset(`key-${hostId}`); // specific key
await cache.clear(); // all keys with this prefix
```

**Caveat:** Cache serializes to JSON, so `Date` objects become `string` on retrieval.

**Alternative:** `responseCacheMiddleware` for caching entire HTTP responses.

---

## Diagnosing Slow Endpoints

Common causes: slow DB query, slow TypeORM parsing (many relations/rows), slow execution (`dayjs.isBefore` is slow in loops), 3rd party API calls.

**Debug steps:**

1. Use `withDatabaseLogging` to get SQL from TypeORM
2. Run `EXPLAIN ANALYZE` against DEV replica
3. Check for multiple 1:N joins multiplying rows (20 bookings \* 200 teachers = 4K rows for TypeORM to parse)
4. Any listing endpoint without pagination is a potential future problem

---

## Backend Code Generators

```bash
yarn entity:generate -n Name            # new DB entity
yarn async-job:generate -n name         # new async job
yarn scheduled-job:generate -n name     # new scheduled job
yarn migration-script:generate -n name  # new migration script
yarn feature-flag:generate -n flagName  # new feature flag
```

---

## Adding New Permissions

**Backend:**

1. Add to enum in `backend/permissions/hostPermissions.ts` or `teacherPermissions.ts`
2. Configure default roles in `backend/permissions/predefinedRoles/*.ts`
3. Keep read and write permissions separate

**Frontend:**

1. Add to `HostPermissions`/`TeacherPermissions` enum in `frontend/libs/api/src/responseTypes/auth.ts`
2. Add to category in `frontend/libs/domain-components/src/domains/hostPermissions/permissionCategories.ts`
3. Add title/description translations
4. Run `yarn permissions:check` to verify

---

## Adding Transactional Email Templates

1. Use `appointmentConfirmationInPersonTemplate` as reference
2. Add `isNew: dayjs().isBefore(dayjs('YYYY-MM-DD'))` property for new templates
3. If new type: add to `HostTransactionalMessageTypes` enum with `ALTER TYPE ... ADD VALUE` migration
4. Must alter BOTH `host_transactional_templates_message_type_enum` AND `host_sent_transactional_messages_message_type_enum`
5. Register in `backend/emails/transactional/member/index.ts`

---

## Integration Patterns

**Always find ALL entry points when modifying integration behavior.**

Integrations (USC, ClassPass, Gympass, etc.) may have multiple endpoints handling the same flow. For example, USC has:

- A deprecated webhook handler (`webhooks/` module)
- An active instant booking handler (`integrations/` module)

Before adding behavior (auto-tagging, logging, validation) to an integration flow:

1. Search broadly: `grep -r "<integrationName>.*<action>"` across the entire backend
2. Check both Express routes (`backend/routes/`) and NestJS controllers (`backend/src/modules/`)
3. Look for deprecated endpoints that may still receive traffic
4. Check async jobs that might also trigger the same flow
