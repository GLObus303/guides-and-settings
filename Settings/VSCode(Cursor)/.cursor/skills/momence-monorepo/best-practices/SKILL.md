---
name: best-practices-momence
description: Engineering guidelines for Momence codebase covering TypeScript, React, backend patterns, and database practices
---

# Engineering Guidelines (TL;DR for Agents)

## Tooling & Formatting

- Use **ESLint + Prettier** (VS Code extensions), **format on save**
- Ignore ESLint rules **only if absolutely necessary**
- **No `@ts-ignore`** → cast to `any` if unavoidable
- Prefer **const over let**

## TypeScript & Code Style

- Avoid `any`, type everything
- Prefer **`type` over `interface`**
- Prefer **inferred types**, annotate only when needed
- Prefer **arrow functions**
- Prefer **param objects** over positional args
- Prefer **`undefined` over `null`**
  - `null` only for DB interaction (TypeORM semantics)

## File Structure (order)

1. imports
2. type definitions
3. helpers / utils
4. React component
5. styled components

## React & Components

- Small, reusable components
- Flat structure when possible
- `type Props = {}` for React
- `type Params = {}` everywhere else

## Naming Conventions

- **Enums**
  - name: `PascalCase` (plural) → `UserTypes`
  - keys: `UPPER_SNAKE_CASE`
  - values: `lower-kebab-case`
- **Constants**: `UPPER_SNAKE_CASE`
- **Functions / variables**: `camelCase`
- **Classes / Components / component folders**: `PascalCase`
- **Other folders**: `camelCase`
- Be descriptive, don't shorten names
- All exports are global → name carefully
- Prefix intent:
  - `assert*` → throws on failure
  - `expect*` → test helpers

## Iteration & Control Flow

- Prefer `for (const it of items)` over `.forEach`
- Iterator naming:
  - Prefer full name (`membership`)
  - Use `it` if full name hurts readability
- Avoid `Promise.all` for **N > 10**
  - Use `parallelRun` with limits

## Enums & Strings

- Prefer **enums over strings**
- Exception: FE component props

---

## Backend / API Guidelines

### Endpoints

- Endpoints live in **routes/**
- Always **app-specific**
- Do **not reuse endpoints across apps**
- Shared endpoints only in `routes/api` (rare, no auth)
- Reuse logic via **services**, not endpoints

### Endpoint Responsibilities

1. Security & permissions
2. Request validation
3. Business logic (services)
4. Response serialization

### Security & Auth

- Validate access to **all entities involved**
- Use guards:
  - `permissionGuard`, `memberRoleGuard`, `adminRoleGuard`, `publicGuard`, `hostAddonGuard`
- Use **authAssert / nestAuthAssert** for complex checks
- Prefer exists/count validation queries
- Place auth asserts in `auth/`
- (Optional) Scope DB queries by `hostId`

### Validation

- Never trust input
- Body (POST/PUT/DELETE):
  - Use **superstruct validators** in `validators/`
  - First line: `assert(req.body, validator)`
- Params/query:
  - Use helpers (`getRequiredIntegerParams`, etc.)
- Auth user:
  - `requireAuthenticatedUserId`

### Services

- Live in root **services/**
- No validation inside services
- Single responsibility
- Prefer **Params objects**
- Prefer **IDs over entities**
- Standard params:
  - `triggeredBy`
  - `entityManager`
- Important params first, infra last
- Services are **unit-test targets**

### Service Results

- Return typed **Result** objects
- Simple validators may return boolean
- Prefer **optional results over exceptions** for expected states

---

## Serialization

- Never return entities directly
- Always use **serializers**
- Return only required fields
- Place in `serializers/`

---

## Database & TypeORM

- Prefer **repository API**
- Use query builder only when needed
- Avoid raw SQL unless unavoidable
- Avoid multiple `1:N` joins in one query
- Use short DB transactions
- Stick to transaction manager inside transactions

### Schema Rules

- Use PKs and proper relations (`ManyToOne`, `OneToMany`)
- **Do NOT use `ManyToMany`**
- Correct types:
  - `decimal + transformer` for money
  - `timestamp with time zone` for dates
- Boolean columns prefixed with `is*`
- Use audit columns
- Soft delete via `deletedAt`

### Enums in DB

- Do NOT use TypeORM enums
- Use **lookup tables** + TS enums

---

## Monorepo Rules

- `apps/` = runnable apps
- `libs/` = reusable modules
- Avoid:
  - cyclic deps
  - cross-app deps
  - importing module index from inside same module
- Lib deps should be **unidirectional**
- No alias imports (`@/...`) inside libs

---

## Common Patterns

- **Guards**
  - Live near controllers
  - Return boolean
  - Named `can*`
- **Hooks**
  - `useSomething`
- **Utils**
  - One function per file
  - Shallow structure

---

## Golden Rule

**When in doubt, follow the most common style already used in the codebase.**
