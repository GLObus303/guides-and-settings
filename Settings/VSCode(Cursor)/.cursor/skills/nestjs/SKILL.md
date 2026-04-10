---
name: nestjs
description: NestJS patterns and conventions for Momence backend. Use when creating modules, controllers, DTOs, or working with decorators, validation, or API documentation.
---

# NestJS Patterns

NestJS is used for defining routes, validation, and Swagger generation. Service logic lives outside NestJS (no DI/services pattern). New functionality should use NestJS; existing Express routes can be migrated opportunistically.

**NestJS Quirks:**

- All DTO files **MUST** have `.dto.ts` suffix — the compiler plugin only processes files with this suffix
- Booleans in `@Query()` must use `@IsBooleanString()` decorator (query params are always strings)
- POST endpoints with `@OkResponse` need `@HttpCode(HttpStatus.OK)` — NestJS defaults to 201 which breaks Swagger
- Optional query params with `ParseIntPipe` must explicitly set type `number | undefined` (not just `number?`)

---

## Module Organization

**Max 3 levels deep:**

```
AppModule
  -> HostModule
     -> HostMembersModule
        -> HostMembersController
        -> HostMembersPaymentsController
```

**Naming rules:**

- Sub-module names start with parent module name: `HostMembersModule` (not `MembersModule`)
- Class postfix: `Module`
- Controllers registered in the module's `.module.ts` file
- Sub-module controllers are NOT visible to Swagger if nested under another module — place controllers in **top-level** modules

```typescript
@Module({
  controllers: [HostMembersController, HostMembersPaymentsController],
  imports: [HostMembersPaymentsModule],
})
export class HostMembersModule {}
```

---

## File Naming & Path Structure

```
src/
  common/                              # Shared utilities
    decorators/
      api-field.ts
      ok-response.ts
      paginated-ok-response.ts
    dtos/
      base-paginated-request.dto.ts
      paginated-response.dto.ts
    utils/
      enum-schema.ts
      get-paginated-response.ts
  modules/                             # Root modules
    host/
      modules/
        host-members/
          controllers/
            host-members.controller.ts
            host-members-sessions.controller.ts
          dtos/
            host-member.dto.ts
            host-member-session.dto.ts
          serializers/                  # Optional
            host-member.serializer.ts
          host-members.module.ts
      host.module.ts
```

**Rules:**

- **kebab-case** for all file names
- Postfixes: `.module.ts`, `.controller.ts`, `.dto.ts`, `.service.ts`, `.serializer.ts`
- Each module has its own `controllers/`, `dtos/`, and optionally `serializers/`, `guards/`, `validation/` directories

---

## Controller Conventions

**Every controller must have an absolute path.** Each new route path gets its own controller.

```typescript
@Controller('/hosts/:hostId(\\d+)/members')
export class HostMembersController {
    @Get()
    @PaginatedOkResponse(HostMemberDto)
    async getList(
        @Param('hostId', ParsePositiveInt32Pipe) hostId: number,
        @Query() params: HostMembersListRequestDto,
    ): Promise<PaginatedResponseDto<HostMemberDto[]>> { ... }

    @Get('/:memberId(\\d+)')
    @OkResponse(HostMemberDto)
    async get(
        @Param('hostId', ParsePositiveInt32Pipe) hostId: number,
        @Param('memberId', ParsePositiveInt32Pipe) memberId: number,
    ): Promise<HostMemberDto> { ... }
}
```

**Key rules:**

- Use `(\\d+)` regex for numeric path params
- Use `ParsePositiveInt32Pipe` for param validation
- Every route handler **must** have `@OkResponse(Dto)` or `@PaginatedOkResponse(Dto)`

---

## @ApiField — Primary DTO Decorator

`@ApiField` is the standard decorator for all DTO properties. It combines Swagger docs, class-validator, and class-transformer in one decorator. **Do not use raw `@ApiProperty`, `@IsString()`, `@IsInt()` etc. directly** unless you have an edge case requiring it.

```typescript
import { ApiField } from "@/src/common/decorators/api-field";
```

### Type Options

```typescript
// Strings
@ApiField({ type: 'string' })
@ApiField({ type: 'string', minLength: 3, maxLength: 100 })
@ApiField({ type: 'string', pattern: /^[A-Z]+$/ })
@ApiField({ type: 'string', in: ['option1', 'option2'] })

// Numbers
@ApiField({ type: 'integer' })               // 32-bit integer
@ApiField({ type: 'integer', min: 0, max: 100 })
@ApiField({ type: 'big-integer' })            // 64-bit integer
@ApiField({ type: 'real' })                   // Float/double

// Boolean
@ApiField({ type: 'boolean' })

// Date/time
@ApiField({ type: 'date-time' })              // Returns Date object
@ApiField({ type: 'military-time' })          // HH:mm format

// Special
@ApiField({ type: 'big-number' })             // BigNumber (bignumber.js)
@ApiField({ type: 'url' })
@ApiField({ type: 'url', urlOptions: { protocols: ['https'] } })

// Enum
@ApiField({ type: 'enum', enum: MyEnum })
@ApiField({ type: 'enum', enum: MyEnum, in: [MyEnum.OPTION1, MyEnum.OPTION2] })  // Subset

// Nested object
@ApiField({ type: 'object', schema: () => NestedDto })

// Generic object (Record<string, unknown>)
@ApiField({ type: 'object' })
```

### Modifiers

```typescript
@ApiField({ type: 'string', nullable: true })     // Allows null
@ApiField({ type: 'string', optional: true })      // Allows undefined (field can be omitted)
@ApiField({ type: 'string', array: true })         // Array of strings
@ApiField({ type: 'integer', array: true })        // Array of integers
@ApiField({ type: 'object', array: true, schema: () => ItemDto })  // Array of objects

// Documentation
@ApiField({ type: 'string', description: 'User email', example: 'john@example.com' })
@ApiField({ type: 'integer', default: 0 })
```

### Combining Nullable and Optional

```typescript
// Required, non-null
@ApiField({ type: 'string' })
name: string

// Required, can be null
@ApiField({ type: 'string', nullable: true })
name: string | null

// Optional, non-null when provided
@ApiField({ type: 'string', optional: true })
name?: string

// Optional and nullable
@ApiField({ type: 'string', optional: true, nullable: true })
name?: string | null
```

### Deprecated Types (avoid in new code)

```typescript
// ❌ Deprecated
@ApiField({ type: 'date-time-string' })    // Use 'date-time' instead
@ApiField({ type: 'big-number-string' })   // Use 'big-number' instead
```

---

## DTO Patterns

### Response DTO

Only fields decorated with `@ApiField` are returned — the decorator controls both validation and serialization:

```typescript
export class HostMemberDto {
  @ApiField({ type: "integer" })
  id: number;

  @ApiField({ type: "string" })
  firstName: string;

  @ApiField({ type: "date-time" })
  createdAt: Date;

  @ApiField({
    type: "object",
    schema: () => HostMemberAddressDto,
    nullable: true,
  })
  address: HostMemberAddressDto | null;
}
```

### Request DTO (Query/Body)

```typescript
export class HostMembersListRequestDto extends BasePaginatedRequestDto {
  @ApiField({ type: "string", optional: true })
  searchQuery?: string;

  @ApiField({ type: "enum", optional: true, enum: MemberListTypes })
  type?: MemberListTypes;
}
```

### Shared Parent DTOs

When multiple APIs share the same base shape, extract a parent DTO:

```typescript
// In common/dtos/ or higher in the folder structure
class MemberBaseDto {
  @ApiField({ type: "integer" })
  id: number;

  @ApiField({ type: "string" })
  firstName: string;
}

// Route-specific DTOs extend the parent
export class HostMemberDto extends MemberBaseDto {
  @ApiField({ type: "object", schema: () => MemberVisitsDto })
  visits: MemberVisitsDto;
}

export class MobileMemberDto extends MemberBaseDto {
  @ApiField({ type: "boolean" })
  hasActiveSubscription: boolean;
}
```

### @ApiSchema for Custom Naming

Override the Swagger schema name when the class name differs from the desired API type name:

```typescript
@ApiSchema({ name: "HostMemberDto" })
export class ApiV2HostMemberDto {
  // Swagger schema will be named 'HostMemberDto' instead of 'ApiV2HostMemberDto'
}
```

### Nested DTOs

Non-exported DTOs can be defined in the same file as the parent DTO:

```typescript
// Not exported — internal to this DTO file
class InstallmentDto {
  @ApiField({ type: "integer" })
  id: number;

  @ApiField({ type: "big-number" })
  amount: BigNumber;

  @ApiField({ type: "boolean" })
  isPaid: boolean;
}

export class PaymentPlanDto {
  @ApiField({ type: "integer" })
  id: number;

  @ApiField({ type: "object", array: true, schema: () => InstallmentDto })
  installments: InstallmentDto[];
}
```

---

## Advanced Validation

For complex validation logic beyond what `@ApiField` provides, combine with raw class-validator decorators:

```typescript
import { ValidateIf, IsArray, ArrayMinSize } from "class-validator";

export class SettingsRequestDto {
  @ApiField({ type: "boolean" })
  criteriaEnabled: boolean;

  @ApiField({ type: "enum", enum: CriteriaMode })
  criteriaMode: CriteriaMode;

  // Conditional validation — only when criteriaEnabled is true
  @ValidateIf((o) => o.criteriaEnabled === true)
  @IsArray()
  @ArrayMinSize(1, {
    message: "At least one tag is required when criteria is enabled",
  })
  @ApiField({ type: "integer", array: true, nullable: true })
  criteriaTagIds: number[] | null;
}
```

When falling back to raw decorators, disable the lint rule:

```typescript
// eslint-disable-next-line @momence/api-field
@IsArray()
@Expose()
@ApiProperty({ type: 'array', items: { type: 'object' } })
attendees: (KnownAttendee | UnknownAttendee)[]
```

### @IsTemporaryOptional — Backwards Compatibility

Mark fields as temporarily optional during deployment transitions:

```typescript
import { IsTemporaryOptional } from '@/src/common/decorators/is-temporary-optional'

@ApiField({ type: 'integer', nullable: true, optional: true })
@IsTemporaryOptional('2025-09-15', 'Field added later, old clients do not send it')
newField?: number | null
```

---

## Enum Handling

### In DTOs (standard)

`@ApiField` handles enum schemas automatically:

```typescript
@ApiField({ type: 'enum', enum: MembershipTypes })
type: MembershipTypes
```

### In @ApiQuery / @ApiParam (use enumSchema)

For query parameters and path params, use the `enumSchema` helper for orval-compatible named enums:

```typescript
import { enumSchema } from '@/src/common/utils/enum-schema'

@Get('/:paymentOriginId(\\d+)/info')
@ApiQuery({
    name: 'paymentOriginTable',
    required: true,
    ...enumSchema({
        enumName: 'PaymentOriginTablesEnum',
        value: PaymentOriginTablesEnum,
    }),
})
async getVoidInfo(
    @Query('paymentOriginTable') paymentOriginTable: PaymentOriginTablesEnum,
): Promise<HostVoidInfoDto> { ... }
```

---

## Response Decorators

### @OkResponse

Validates output, generates Swagger schema, and serializes response:

```typescript
import { OkResponse } from '@/src/common/decorators/ok-response'

// Single object
@OkResponse(HostMemberDto)

// Array of objects
@OkResponse([HostMemberDto])
```

### @PaginatedOkResponse

For paginated list endpoints:

```typescript
import { PaginatedOkResponse } from '@/src/common/decorators/paginated-ok-response'

@PaginatedOkResponse(HostMemberDto)
async getList(@Query() params: MyRequestDto): Promise<PaginatedResponseDto<HostMemberDto[]>> { ... }
```

---

## Pagination

### Request DTO

Extend `BasePaginatedRequestDto` (not the deprecated `PaginatedRequestDto`):

```typescript
import { BasePaginatedRequestDto } from "@/src/common/dtos/base-paginated-request.dto";

export class MyListRequestDto extends BasePaginatedRequestDto {
  @ApiField({ type: "string", optional: true })
  searchQuery?: string;
}
```

`BasePaginatedRequestDto` provides: `page`, `pageSize`, `sortOrder?`, `sortBy?`

### Response

Use `getPaginatedResponse` to build the response:

```typescript
import { getPaginatedResponse } from '@/src/common/utils/get-paginated-response'
import { getTypeOrmPagingParams } from '@/utils/pagination'

@PaginatedOkResponse(ItemDto)
async getList(@Query() params: MyListRequestDto): Promise<PaginatedResponseDto<ItemDto[]>> {
    const paging = getTypeOrmPagingParams(params)

    const [items, totalCount] = await repo.findAndCount({
        skip: paging.skip,
        take: paging.take,
    })

    return getPaginatedResponse({
        request: params,
        totalCount,
        payload: items,
    })
}
```

---

## Common Decorators Reference

### Authentication & Authorization

```typescript
@LoggedUser() user: AuthUser              // Logged-in user (required)
@OptionalLoggedUser() user: OptionalLoggedUser  // Logged-in user (optional)
@HostIdScope() hostId: HostIdScope        // Scoped host ID
@HostPermission(HostPermissions.CUSTOMERS_READ)  // Permission guard
@MemberRole()                             // Member role guard
@PublicGuard()                            // Public endpoint guard
@CheckoutSession()                        // Checkout session guard
```

### Swagger

```typescript
@ApiOperation({ summary: 'Get members' })
@ApiSecurity('OAuth2')
@ApiTags('host')
@ApiQuery({ name: 'search', type: 'string', required: false })
```

### Rate Limiting

```typescript
import { RateLimited } from '...'
import parseDuration from 'parse-duration'

@RateLimited({
    interval: parseDuration('10m'),
    limit: 100,
    banInterval: parseDuration('1h'),
    prefix: 'my-endpoint',
})
```

### Pipes

```typescript
import { ParsePositiveInt32Pipe } from '@/src/common/decorators/parse-positive-int32.pipe'

@Param('hostId', ParsePositiveInt32Pipe) hostId: number
```

---

## Serializers

For complex entity-to-DTO mapping, use plain serializer functions (not classes):

```typescript
import { plainToInstance } from "class-transformer";

export const hostMemberSerializer = (customer: Customer): HostMemberDto => {
  return plainToInstance(HostMemberDto, {
    id: customer.id,
    firstName: customer.firstName,
    address: customer.address
      ? plainToInstance(HostMemberAddressDto, customer.address)
      : null,
  });
};
```

For simple cases, return plain objects directly from controllers — the `@OkResponse` interceptor handles `plainToInstance` transformation.

---

## Complete Controller Example

```typescript
import { Controller, Get, Param, Query } from "@nestjs/common";
import { HostPermission } from "@/src/common/decorators/host-permission";
import { HostPermissions } from "@/permissions/hostPermissions";
import { OkResponse } from "@/src/common/decorators/ok-response";
import { PaginatedOkResponse } from "@/src/common/decorators/paginated-ok-response";
import { PaginatedResponseDto } from "@/src/common/dtos/paginated-response.dto";
import { ParsePositiveInt32Pipe } from "@/src/common/decorators/parse-positive-int32.pipe";
import { getPaginatedResponse } from "@/src/common/utils/get-paginated-response";
import { getTypeOrmPagingParams } from "@/utils/pagination";

@Controller("host/:hostId(\\d+)/member-payment-plans")
export class HostMemberPaymentPlansController {
  @Get("/list")
  @HostPermission(HostPermissions.PAYMENT_PLANS_READ_WRITE)
  @PaginatedOkResponse(PaymentPlanDto)
  async getList(
    @Param("hostId", ParsePositiveInt32Pipe) hostId: number,
    @Query() params: PaymentPlansListRequestDto,
  ): Promise<PaginatedResponseDto<PaymentPlanDto[]>> {
    const { type, searchQuery, sortBy, sortOrder } = params;
    const paging = getTypeOrmPagingParams(params);

    const { plans, totalCount } = await getPaymentPlansPaginated({
      hostId,
      skip: paging.skip,
      take: paging.take,
      sortBy,
      sortOrder,
      type,
      searchQuery,
    });

    return getPaginatedResponse({
      request: params,
      payload: plans,
      totalCount,
    });
  }

  @Get("/:planId(\\d+)")
  @HostPermission(HostPermissions.PAYMENT_PLANS_READ_WRITE)
  @OkResponse(PaymentPlanDetailDto)
  async get(
    @Param("hostId", ParsePositiveInt32Pipe) hostId: number,
    @Param("planId", ParsePositiveInt32Pipe) planId: number,
  ): Promise<PaymentPlanDetailDto> {
    return getPaymentPlan({ hostId, planId });
  }
}
```

---

## Client-Side Code Generation

### Workflow

1. **Backend:** Add/update controllers and DTOs with `@ApiField` decorators
2. **Backend:** Register controller in the module's `.module.ts` file
3. **Backend:** Build backend: `cd backend && yarn build`
4. **Frontend:** Run `yarn generate-api` (requires backend running on port 1337)
5. **Frontend:** Import from `@momence/api-<module>`

### Generated Code

Every NestJS route generates:

- `controllerNameRouteName()` — direct API call function
- `useControllerNameRouteName()` — React Query hook wrapper
- `getControllerNameRouteNameQueryKey()` — query key for invalidation
- All DTOs as TypeScript types/interfaces

Naming can be overridden with `@ApiOperationId('customName')` on the route handler.

### Adding a New Root Module

1. Create module in `backend/src/modules/<module-name>/`
2. Register in `backend/src/app.module.ts`
3. Add to `backend/services/swagger/setupSwaggerRoutes.ts` (via `getSwaggerDocuments.ts`)
4. Add to `frontend/tools/scripts/api-gen.js` modules list
5. Run `yarn generate-api` to create the new `@momence/api-<module>` package

### Swagger UI

Browse API schemas at:

- UI: `http://localhost:1337/api-schemas/<module>` (e.g., `/api-schemas/host`)
- JSON: `http://localhost:1337/api-schemas/<module>.json`
- YAML: `http://localhost:1337/api-schemas/<module>-yaml`

---

## Root Modules Reference

| Module                 | Purpose                    |
| ---------------------- | -------------------------- |
| `admin`                | Admin panel routes         |
| `affiliates`           | Affiliate system           |
| `api` / `api-v2`       | Public API for hosts       |
| `auth`                 | Authentication             |
| `checkout`             | Checkout pages             |
| `corporate`            | Corporate dashboard        |
| `feed`                 | Feed viewer                |
| `health-check`         | Service health checks      |
| `host`                 | Host dashboard             |
| `host-schedule-plugin` | Host scheduler plugin      |
| `integrations`         | Third-party integrations   |
| `kiosk`                | Kiosk mode                 |
| `member`               | Member dashboard           |
| `micro-apps`           | Micro-applications         |
| `mobile-v3`            | Mobile API (v3)            |
| `on-demand`            | On-demand app              |
| `poll`                 | Polling                    |
| `private-api`          | Internal APIs              |
| `public`               | Publicly accessible routes |
| `sign-up`              | Sign-up flow               |
| `webhooks`             | Webhook endpoints          |
| `website`              | Static website routes      |
| `workouts-wod`         | Workouts/WOD               |

---

## Public API V2

Behind feature flag. Docs: https://api-docs.momence.com. Swagger UI: `http://localhost:1337/api-schemas/api-v2`.

```typescript
// Key decorators for Public API V2 endpoints
@ApiSecurity('OAuth2')
@UsePublicApiV2Guard()
@MemberIdScope() memberIdScope: MemberIdScope
@HostIdScope() hostIdScope: HostIdScope

// Override OpenAPI schema name to remove internal prefix
@ApiSchema({ name: 'MemberInfoDto' })
export class ApiV2MemberInfoDto { ... }
```

Supports OAuth2 `password` and `authorization_code` flows.

---

## Validation Rules Summary

**Use `@ApiField` for:**

- All standard field validation (types, ranges, lengths, patterns, enums)
- Nullable/optional modifiers
- Array types

**Combine with raw class-validator for:**

- `@ValidateIf()` — conditional validation
- `@ArrayMinSize()` / `@ArrayMaxSize()` — array size constraints
- Union types / polymorphic fields (with `// eslint-disable-next-line @momence/api-field`)

**Controller validation is appropriate for:**

- Database-dependent validation (checking if IDs exist)
- Authorization checks (user permissions)
- Business logic spanning multiple entities
