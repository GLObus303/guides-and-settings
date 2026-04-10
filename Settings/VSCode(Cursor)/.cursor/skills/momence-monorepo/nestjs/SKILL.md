---
name: nestjs-momence
description: NestJS guidelines optimized for AI agents, focusing on Swagger generation and API structure
---

# NestJS Guidelines (Optimized for AI Agents)

## Why NestJS

- NestJS auto-generates **Swagger/OpenAPI schemas**
- Swagger is the **single source of truth** for:
  - Client-side API generation
  - Validation & serialization
- **No manual BE ↔ FE sync** if routes follow these rules

> ⚠️ Currently NestJS is used mainly for **routing + validation**  
> DI/services may be adopted later (TBD)

---

## Adoption Strategy

- ✅ **All new functionality must use NestJS**
- 🔁 Migrating old routes → optional, allowed if it fits your PR
- 🧠 Use judgment, no forced migration yet

---

## Module & Route Structure

### Max Nesting Depth

**Max 3 levels deep**

```
AppModule
└─ HostModule
└─ HostMembersModule
├─ HostMembersController
└─ HostMembersPaymentsController
```

---

## Naming Conventions

### Modules

- Must start with **parent module name**
- Must end with `Module`
- Example: `HostMembersModule`

### Controllers

- Start with **parent module name**
- End with `Controller`
- Must be registered in `*.module.ts`

### DTOs

- Use parent prefix **when reasonable**
- End with `Dto`

---

## File Naming & Paths

- **kebab-case** filenames
- Required postfixes:
  - `.module.ts`
  - `.controller.ts`
  - `.dto.ts`
  - `.service.ts`

### Standard Structure

```
src
├─ common
│  ├─ decorators
│  └─ dtos
├─ modules
│  ├─ host
│  │  ├─ modules
│  │  │  └─ host-members
│  │  │     ├─ controllers
│  │  │     ├─ dtos
│  │  │     └─ host-members.module.ts
│  │  └─ host.module.ts
│  └─ checkout
└─ app.module.ts
```

---

## Controller Rules

### Paths

- Controllers must define **absolute paths**
- **Each new path = new controller**

```ts
@Controller("/hosts")
export class HostsController {
  @Get()
  getList() {}

  @Get(":hostId(\\d+)")
  get() {}
}

@Controller("/hosts/:hostId(\\d+)/members")
export class HostMembersController {
  @Get()
  getList() {}

  @Get(":memberId(\\d+)")
  get() {}
}
```

---

## Response Decorators (MANDATORY)

### `@OkResponse(dto)`

Every route **must** use this.

- Defines Swagger response type
- Serializes output
- Validates output

```ts
@OkResponse(HostDto)
@OkResponse([HostDto]) // array response
```

---

### `@PaginatedOkResponse(type)`

Used because:

- Swagger ❌ generics
- class-validator ❌ generics

Provides:

- Generic paginated schema
- Full validation + serialization

---

## Enums (IMPORTANT)

Swagger doesn't support **named enums** by default.

✅ Use `enumSchema` helper:

```ts
@ApiQuery({
  name: 'paymentOriginTable',
  required: true,
  ...enumSchema({
    enumName: 'PaymentOriginTablesEnum',
    value: PaymentOriginTablesEnum,
  }),
})
```

- Always use `@Api*` decorators
- Use `@ApiProperty` inside DTOs

---

## DTOs

### Shared DTOs

Use when:

- Web + Mobile share structure
- Partial overlaps (pagination, base entities)

Location:

```
src/common/dtos
```

Benefits:

- Unified naming
- Deduplication
- Safer evolution

---

## Validation & Serialization

- **Validation:** `class-validator`
- **Serialization:** `class-transformer`
- All response DTOs **must use both**

---

## Full Controller Example

```ts
@Controller("/hosts")
export class HostsController {
  @Get()
  @PaginatedOkResponse(HostDto)
  async getList(@Query() params: PaginatedRequestDto) {
    const [hosts, totalCount] = await getHostsPaginated({
      pagination: getTypeOrmPagination(params),
    });

    return getPaginatedResponse({
      request: params,
      totalCount,
      payload: hosts,
    });
  }
}

export class HostDto {
  @IsInt()
  id: number;

  @IsString()
  name: string;

  @IsDate()
  @Type(() => Date)
  createdAt: Date;
}
```

---

## Client-Side API Generation

- Generated **automatically** from Swagger
- **One API package per root module**
- Tooling:

  - `orval`
  - Custom post-processing

Packages live in:

```
frontend/apis
```

Usage:

```ts
import { useHostsGetList } from "@momence/api-host";
```

---

## Generated Client API Includes

For each route:

- `controllerNameRouteName()`
- `useControllerNameRouteName()` (React Query)
- `getControllerNameRouteNameQueryKey()`
- All DTOs as TS types/interfaces

Override naming with:

```ts
@ApiOperationId('customName')
```

---

## Regenerating Client Code

Requirements:

- Backend running on **port 1337**

Command:

```bash
yarn generate-api
```

⚠️ Rules:

- Controllers **must be registered in module**
- **Sub-modules are NOT detected**

  - Controllers must live in **top-level modules**

---

## Adding New Root Modules

### Backend

1. Add module under `src/modules`
2. Register in:

```
backend/services/swagger/setupSwaggerRoutes.ts
```

### Frontend

3. Add module to:

```
frontend/tools/scripts/api-gen.js
```

4. Run:

```bash
yarn generate-api
```
