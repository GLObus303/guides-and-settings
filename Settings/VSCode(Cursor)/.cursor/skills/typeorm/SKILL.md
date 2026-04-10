---
name: typeorm
description: TypeORM patterns for Momence — entity design, migrations, quirks, and query patterns. Use when writing TypeORM queries, working with entities, creating migrations, or debugging unexpected query behavior.
---

# Database Migrations

**Generating migrations:**

```bash
cd backend && yarn generate:migration -n DescriptiveName
```

**Always review generated migrations!** The generator compares current DB to entities and includes ALL differences - not just your changes. You may see unrelated index drops, column changes, etc. Clean these up.

**Enum migrations:**

```typescript
// up(): Use ADD VALUE (no IF NOT EXISTS)
await queryRunner.query(`ALTER TYPE "public"."my_enum" ADD VALUE 'NEW_VALUE'`)

// down(): Do NOT recreate enums to remove values. Just drop columns.
// PostgreSQL ADD VALUE cannot be reversed in a transaction, and leaving
// unused enum values is harmless.
async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "my_table" DROP COLUMN "my_column"`)
    // Enum values are not removed
}
```

**History log tables:**
Some tables (e.g., `gympass_integrations`) have `_history_log` tables with triggers. When adding columns:

1. Add column to main table
2. Add column to `_history_log` table
3. Trigger update migrations are auto-generated

**FK constraints:**
When entities have `@ManyToOne` relations, include FK constraints in migration:

```typescript
await queryRunner.query(
  `ALTER TABLE "my_table" ADD CONSTRAINT "FK_tags_id" FOREIGN KEY ("customer_tag_id") REFERENCES "tags"("id") ON DELETE SET NULL`,
);
```

**Never use `ALTER COLUMN SET NOT NULL` on large tables:**
It acquires `AccessExclusiveLock` and scans every row. Use a CHECK constraint instead:

```sql
-- 1. Backfill NULLs
UPDATE "my_table" SET "source" = 'default' WHERE "source" IS NULL;
-- 2. Add constraint NOT VALID (no row scan, weak lock)
ALTER TABLE "my_table" ADD CONSTRAINT "my_table_source_not_null" CHECK ("source" IS NOT NULL) NOT VALID;
-- 3. Validate (allows concurrent reads/writes)
ALTER TABLE "my_table" VALIDATE CONSTRAINT "my_table_source_not_null";
```

In the entity, keep `nullable: true` + add `@Check` decorator to prevent TypeORM from generating `SET NOT NULL`:

```typescript
@Column('varchar', { name: 'source', nullable: true })  // Keep nullable to prevent SET NOT NULL
@Check('my_table_source_not_null', `"source" IS NOT NULL`)
source: MySourceEnum  // TS type is non-null (constraint enforces it)
```

**Concurrent index creation on large tables:**
For large tables (10+ GB), adding an index locks the table and can cause downtime. Use `CREATE INDEX CONCURRENTLY` instead — but it cannot run on a column added in the same migration. Split into two PRs:

1. PR 1: Add the column (+ migration)
2. PR 2: Add the concurrent index (+ migration)

Large tables to watch: `marketing_sent_messages`, `scheduled_jobs`, `memberships_history_log`, `host_sent_transactional_messages`, `session_bookings`, `sent_email_message_statuses`, `sessions_history_log`, `message_tracking_events`, `host_activity_logs`, `session_bookings_history_log`, `payment_transactions`, `host_campaign_sequence_sent_messages`, `sale_items`, `host_inbox_conversations`.

For small tables, a regular `CREATE INDEX` in the same migration is fine.

## Dangerous Migrations Checklist

Before merging any migration, check for these patterns:

| Pattern                            | Risk                                                           | Safe Approach                                                                                                                      |
| ---------------------------------- | -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Adding index to large table        | Table lock, downtime                                           | Migration uses `CREATE INDEX IF NOT EXISTS`, run `reusable/createIndex` GH Actions script (WITHOUT `IF NOT EXISTS`) before merging |
| Adding non-null column             | Fails for existing rows                                        | Split: nullable column → data fill → NOT NULL constraint                                                                           |
| Adding FK column                   | Long validation on large tables                                | Use `NOT VALID` on FK constraint                                                                                                   |
| Removing a column                  | Old code still references it                                   | PR 1: mark `{ select: false, insert: false, update: false }`, PR 2: drop column                                                    |
| Adding enum value                  | TypeORM generates column re-type (locks table)                 | Replace with `ALTER TYPE ... ADD VALUE`                                                                                            |
| Dropping a default                 | Old code may not provide values                                | Ensure all code already provides values before removing                                                                            |
| Unique constraint with soft delete | NULL `deletedAt` values collapse                               | Use `NULLS NOT DISTINCT` when including `deletedAt`                                                                                |
| Adding unique constraint           | Locks table during creation                                    | Create unique index async first, then `ADD CONSTRAINT ... UNIQUE USING INDEX ...` (instant)                                        |
| Reverting a migration PR           | Safe only if migration is strictly additive and name unchanged |

**Create new DB table:**

```bash
yarn generate:entity -n {NAME}   # Creates entity file
yarn generate:migration -n {NAME} # Creates migration
```

Must register entity in `backend/db/entities/index.ts` barrel file.

**Unique constraints with soft delete:**

```sql
-- ❌ Wrong: deleted rows with NULL deletedAt collapse
CREATE UNIQUE INDEX "UQ_my_table" ON "my_table" ("host_id", "name", "deleted_at")

-- ✅ Correct: NULL values are treated as distinct
CREATE UNIQUE INDEX "UQ_my_table" ON "my_table" ("host_id", "name", "deleted_at") NULLS NOT DISTINCT
```

For large tables: create the index async first, then add the constraint using the existing index.

**Explicit index/FK names (when writing custom migrations):**
If you write a migration with custom index/FK constraint names, the entity **must** use explicit names to match:

```typescript
// Migration uses custom names:
CREATE INDEX "IDX_my_table_host_id" ON "my_table" ("host_id")
ALTER TABLE "my_table" ADD CONSTRAINT "FK_my_table_host_id" FOREIGN KEY...

// Entity MUST specify matching names:
@Column({ name: 'host_id' })
@Index('IDX_my_table_host_id')  // Explicit name matches migration
hostId: number

@ManyToOne(() => Host)
@JoinColumn({ name: 'host_id', foreignKeyConstraintName: 'FK_my_table_host_id' })  // Explicit FK name
host?: Relation<Host>

// Without explicit names, TypeORM generates different names like "IDX_abc123..."
// This causes schema mismatch in CI migration checks
```

---

# Entity Design

**Design Principles:**

- **Only persist dynamic runtime data** — don't store static metadata that's part of code definitions. If a property never changes per-record, it belongs in code, not DB.
- **Prefer `jsonb` for polymorphic data** — use a single `jsonb` column instead of rigid typed columns when different record types have different shapes.
- **Don't denormalize without a clear query need** — if a value is reachable through an existing relation, don't duplicate it as a column. Only denormalize for proven query performance needs.
- **Prefer natural keys in application code** — when an entity has a natural composite key (unique constraint), use that key for lookups instead of the surrogate auto-increment `id`.

## Data Types

- **Numbers:** Use `integer` (or `bigint`) for most cases. Use `decimal` with `ColumnDecimalTransformer` for money/decimals:

  ```typescript
  import { ColumnDecimalTransformer } from '@/db/ColumnDecimalTransformer'
  import BigNumber from 'bignumber.js'

  @Column({ type: 'decimal', name: 'price', transformer: new ColumnDecimalTransformer() })
  price: BigNumber
  ```

- **Strings:** Prefer `varchar(x)` over `text`
- **Dates:** Always use `timestamp with time zone` (timezone is important):
  ```typescript
  @Column({ type: 'timestamp with time zone', name: 'starts_at' })
  startsAt: Date
  ```
- **Booleans:** Prefix with `is*` (e.g., `isActive`, `isPaid`, `isProcessed`):
  ```typescript
  @Column({ type: 'boolean', name: 'is_paid', default: false })
  isPaid: boolean
  ```
- **Enums:** Use lookup tables (see "Enums Using Lookup Tables" section below). Avoid TypeORM `enum` types unless you have a strong reason.
- **`Relation<T>` wrapper is required on custom type references** — entities, enums, `Record<>`, and other non-primitive types on entity columns. Primitives (`string`, `number`, `boolean`) are exempt. Enforced by the `@momence/entity-relation-wrapper` ESLint rule. `assignmentType: Relation<InboxConversationAssignmentTypes>` is **correct**. Do NOT flag `Relation<EnumType>` as wrong in code reviews — the linter enforces this.

## Relations

- Use `@ManyToOne` / `@OneToMany` for relations. **Do not use `@ManyToMany`** — it does not scale and is hard to query. Create a junction table instead.
- **Always define relations as optional** (`?`). When using `.find()` with `relations`, TypeORM will properly type them as required based on loaded relations. Use `WithRelations<Entity, 'relation'>` for function parameters:

  ```typescript
  // Entity definition — relation is optional
  @ManyToOne(() => Hosts, host => host.openAreaVisits)
  @JoinColumn({ name: 'host_id' })
  host?: Relation<Hosts>

  // Repository .find() — automatically types loaded relations as required
  const result = await getRepository(OpenAreaVisits).find({
      where: { id },
      relations: { host: true },
  })
  result[0].host // <- non-nullable, TypeORM infers it's loaded

  // Function parameter — use WithRelations to require loaded relations
  import { WithRelations } from '@/utils/withRelations'
  const process = (visit: WithRelations<OpenAreaVisits, 'host' | 'member'>) => {
      visit.host   // <- non-nullable
      visit.member // <- non-nullable
  }

  // Query builder — use .withRelations() for type-safe joins
  const result = await createQueryBuilder(OpenAreaVisits)
      .withRelations({
          host: { join: 'inner' },        // inner join — non-nullable
          member: true,                    // left join (default)
      })
      .where({ id })
      .getOneOrFail()
  ```

- **Always define both sides of a relation.** If you add a `@ManyToOne` on entity A pointing to entity B, also add the `@OneToMany` inverse on entity B. Missing inverse relations cause silent issues with eager loading, cascades, and relation-based queries.
- **Verify inverse relation callbacks point to the correct property.** A common copy-paste mistake:

  ```typescript
  // ❌ Wrong inverse — points to a different entity's relation
  @ManyToOne(() => Hosts, host => host.sentMarketingMessages)

  // ✅ Correct — points to the matching inverse property
  @ManyToOne(() => Hosts, host => host.conversationEntries)
  ```

- When the FK column is nullable, include `| null` on the relation type:

  ```typescript
  @Column({ name: 'sale_item_id', type: 'integer', nullable: true })
  saleItemId: number | null

  @ManyToOne(() => SaleItems)
  @JoinColumn({ name: 'sale_item_id' })
  saleItem?: Relation<SaleItems> | null
  ```

## Audit Columns

Use audit columns on all new entities:

- **`AuditColumnsWithDelete`** (preferred for new entities) — provides `createdAt`, `createdBy`, `modifiedAt`, `modifiedBy`, `deletedAt`, `deletedBy`
- **`AuditColumns`** — provides `createdAt`, `createdBy`, `modifiedAt`, `modifiedBy` (no soft delete)

```typescript
import { AuditColumnsWithDelete } from "@/db/utils/AuditColumnsWithDelete";

@Entity("my_table")
export class MyEntity extends AuditColumnsWithDelete {
  @PrimaryGeneratedColumn({ type: "integer", name: "id" })
  id: number;
  // ...
}
```

## Soft Delete

Use `deletedAt` column (provided by `AuditColumnsWithDelete`). Always filter `deletedAt: IsNull()` when querying. Do **not** use TypeORM's `@DeleteDateColumn` or an `isDeleted` column — both are deprecated patterns.

**`relations: { ... }` silently loads soft-deleted records.** TypeORM's `.find()` `relations` option performs a LEFT JOIN with no conditions — it loads deleted records too. When the join target uses `AuditColumnsWithDelete`, use `withRelations` with an explicit condition instead:

```typescript
// ❌ Bug: Loads soft-deleted checkIns — inflated payroll/counts
const bookings = await repo.find({
  where: { sessionId },
  relations: { checkIn: true },
});

// ✅ Fix: Use withRelations with deletedAt condition
const bookings = await repo
  .createQueryBuilder("booking")
  .withRelations({
    checkIn: { conditions: "checkIn.deletedAt IS NULL" },
  })
  .typedWhere({ sessionId })
  .getMany();
```

If not extending `AuditColumnsWithDelete`, add the column manually:

```typescript
@Column({ type: 'timestamp with time zone', name: 'deleted_at', nullable: true })
deletedAt: Date | null
```

## Required vs Nullable

When creating a new table, identify required fields and make them **not-nullable**. New columns added to existing tables must be nullable or have defaults (backwards compatibility).

## Properties Order

Order entity properties as follows:

1. **Primary keys** (`id`)
2. **Foreign keys** (`hostId`, `memberId`)
3. **Business columns** (more important higher, e.g., `name`, `email`)
4. **Boolean flags** (`isPaid`, `isProcessed`)
5. **Audit columns** (inherited from `AuditColumns` / `AuditColumnsWithDelete`)
6. **Relations** (all marked optional with `?`)

```typescript
@Entity("open_area_visits")
export class OpenAreaVisits extends AuditColumnsWithDelete {
  // 1. Primary key
  @PrimaryGeneratedColumn()
  id: number;

  // 2. Foreign keys
  @Column({ type: "integer", name: "host_id" })
  @Index()
  hostId: number;

  @Column({ type: "integer", name: "member_id" })
  @Index()
  memberId: number;

  // 3. Business columns
  @Column({
    type: "decimal",
    name: "price",
    transformer: new ColumnDecimalTransformer(),
  })
  price: BigNumber;

  @Column({
    type: "timestamp with time zone",
    name: "starts_at",
    nullable: true,
  })
  startsAt: Date | null;

  // 4. Boolean flags
  @Column({ type: "boolean", name: "is_paid", default: false })
  isPaid: boolean;

  // 5. Audit columns — inherited from AuditColumnsWithDelete

  // 6. Relations
  @ManyToOne(() => Hosts)
  @JoinColumn({ name: "host_id" })
  host?: Relation<Hosts>;

  @ManyToOne(() => RibbonMembers)
  @JoinColumn({ name: "member_id" })
  member?: Relation<RibbonMembers>;
}
```

---

# TypeORM Quirks

## Primary Key Ordering

Auto-generated PK order may NOT correspond to insertion order. When chronological order matters, always sort by a date column (`createdAt`), not by `id`.

## Deprecated Methods — Always Check for Deprecations

TypeORM and the codebase have custom type-safe replacements for many standard methods. **Always check for `@deprecated` annotations** on any method before using it. Common ones:

```typescript
// ❌ Deprecated query builder methods
.where(...)              // → use .typedWhere(...)
.andWhere(...)           // → use .andTypedWhere(...)
.leftJoinAndSelect(...)  // → use .withRelations(...)
.exist(...)              // → use .exists(...)

// ✅ Type-safe replacements
.typedWhere({ hostId, deletedAt: IsNull() })
.andTypedWhere({ status: In([Status.ACTIVE, Status.PENDING]) })
.withRelations({ host: { join: 'inner' }, member: true })
.exists({ where: { id } })
```

When writing any query builder code, prefer the `typed*` and `withRelations` methods — they provide compile-time type safety and are the established pattern in this codebase.

## `withDeleted: true` Has No Effect on `AuditColumnsWithDelete`

TypeORM's `withDeleted: true` option only works with the built-in `@DeleteDateColumn` decorator. Most new entities use `AuditColumnsWithDelete` (manual `deletedAt` column) where `withDeleted` is a no-op. Some legacy entities (~19) still use `@DeleteDateColumn` where `withDeleted` IS effective. For `AuditColumnsWithDelete` entities, always use explicit conditions:

```typescript
// ❌ Does nothing — AuditColumnsWithDelete doesn't use @DeleteDateColumn
const entity = await repo.findOne({ where: { id }, withDeleted: true });

// ✅ Correct: explicit condition
const entity = await repo.findOne({ where: { id } }); // no deletedAt filter = includes deleted
const active = await repo.findOne({ where: { id, deletedAt: IsNull() } }); // excludes deleted
```

## `where` on Nested Relations in `find()` Filters Parents, Not Children

When using `.find()` with a `where` condition on a nested relation, the condition filters which **parent rows** are returned — it does NOT filter which related child records are loaded:

```typescript
// ❌ Bug: still loads ALL roles including soft-deleted ones
const sources = await repo.find({
  relations: { notifiedRoles: true },
  where: { notifiedRoles: { deletedAt: IsNull() } }, // filters PARENTS, not children
});

// ✅ Fix: use withRelations conditions to filter children
const sources = await repo
  .createQueryBuilder("source")
  .withRelations({
    notifiedRoles: { conditions: { deletedAt: { $isNull: true } } },
  })
  .getMany();
```

## `.exists()` not `.exist()`

Use `repository.exists({ where: ... })` — the current TypeORM method. `.exist()` is **deprecated** (TypeORM docs: "use `exists` method instead"). The codebase has legacy `.exist()` calls that should be migrated.

## Fetch Post-Commit Data Inside `executeAfterTransactionCommit`

Data fetched inside a transaction may not reflect the committed state for external systems. Any DB read needed only for post-commit side-effects belongs inside the callback. If there is no active transaction, the logic runs immediately:

```typescript
// ❌ Bug: entity fetched inside transaction, webhook sees uncommitted data
const entity = await manager.getRepository(Entity).findOneOrFail(id);
await executeAfterTransactionCommit(manager, () => sendWebhook(entity));

// ✅ Fix: fetch after commit so webhook gets committed data
await executeAfterTransactionCommit(manager, async () => {
  const entity = await getRepository(Entity).findOneOrFail(id);
  await sendWebhook(entity);
});
```

## Selecting NULL Columns

`findOneOrFail()` throws `EntityNotFoundError` when selecting only columns that contain `NULL` values — even if the entity exists:

```typescript
// ❌ Throws if host exists but has NULL timeZone
await getRepository(Hosts).findOneOrFail(hostId, {
  select: ["timeZone"],
});

// ✅ Include a non-null column (like id) to prevent false EntityNotFoundError
await getRepository(Hosts).findOneOrFail(hostId, {
  select: ["id", "timeZone"],
});
```

## Empty Array with IN Clause

TypeORM fails if you use `IN` with an empty array. Always guard with `safeInArray`:

```typescript
// ❌ Crashes when array is empty
.orWhere('BoughtMemberships.id IN (:...ids)', {
    ids: sharedMemberships.map(m => m.boughtMembershipId),
})

// ✅ Use safeInArray utility
.orWhere('BoughtMemberships.id IN (:...ids)', {
    ids: safeInArray(sharedMemberships.map(m => m.boughtMembershipId)),
})
```

**Warning:** Do NOT use `safeInArray` with `NOT IN` — it produces incorrect results.

## Duplicate Parameter Names

Query builder silently uses the last value when parameter names collide:

```typescript
// ❌ Both use :id — second silently overwrites first
.where('host.id = :id', { id: hostId })
.andWhere('member.id = :id', { id: memberId })

// ✅ Use unique parameter names
.where('host.id = :hostId', { hostId })
.andWhere('member.id = :memberId', { memberId })
```

## Select with Relations

When using both `select` and `relations` in `.find()`, you must explicitly select the join columns (FK columns), otherwise the relation won't load.

## Brackets for AND (x OR y)

TypeORM strips inner brackets from `.andWhere('(id = 2 OR id = 1)')`. Use `Brackets`:

```typescript
// ❌ Brackets get stripped, query is wrong
.andWhere('(id = 2 OR id = 1)')

// ✅ Use Brackets class
.andWhere(
    new Brackets(q =>
        q
            .where('LOWER(BoughtMemberships.email) = :email', { email: memberEmail })
            .orWhere('BoughtMemberships.id IN (:...sharedMembershipIds)', {
                sharedMembershipIds: safeInArray(sharedMemberships.map(m => m.boughtMembershipId)),
            })
    )
)
```

## Multiple Where Conditions

After the first `.where`, use `.orWhere` or `.andWhere`. A second `.where` silently erases the first one.

## Undefined Values in Conditions

`.findOne({ id: undefined })` is the same as `.findOne()` — returns a random record. Always guard against undefined.

## CamelCase with .count/.getCount

Cannot use camelCase column names (TypeScript property names) with count queries. TypeORM doesn't select/rename original snake_case columns:

```typescript
// ✅ Works with getMany()
await getRepository(SessionBookings)
  .createQueryBuilder()
  .where("createdAt > NOW()")
  .getMany();

// ❌ Throws with getCount()
await getRepository(SessionBookings)
  .createQueryBuilder()
  .where("createdAt > NOW()")
  .getCount();

// ✅ Use snake_case column name for count queries
await getRepository(SessionBookings)
  .createQueryBuilder()
  .where("created_at > NOW()")
  .getCount();
```

## Pagination with OneToMany/ManyToMany Relations

Using `skip/take` with relations doesn't return the expected number of root entities — Postgres returns one row per parent-child combination. Split into two queries:

1. First query: Select distinct parent IDs with pagination
2. Second query: Load parents with relations using those IDs

See: https://github.com/typeorm/typeorm/issues/4683

## Enums Using Lookup Tables

Default TypeORM enums lock the entire table when adding/removing values (requires re-typing the column). For large tables or changing enums, use lookup tables:

1. Define enum in `backend/db/entities/enums/`
2. Create a `*_types` lookup table entity with `@LookupTableOf()` decorator
3. Add `@ManyToOne` relation from main entity to lookup table
4. Migration auto-generates INSERT statements for lookup table values

## Upsert with Nullable Conflict Columns

TypeORM's `.upsert()` / PostgreSQL's `ON CONFLICT` does not work when any conflict path column can be `NULL`. PostgreSQL treats `NULL != NULL`, so the conflict clause never fires — duplicate rows are created instead.

```typescript
// ❌ Bug: Creates duplicates when appHostId is NULL
await repo.upsert(data, { conflictPaths: ["deviceToken", "appHostId"] });

// ✅ Fix: Manual find-then-update-or-insert with IsNull()
const existing = await repo.findOne({
  where: { deviceToken, appHostId: appHostId ?? IsNull() },
});
if (existing) {
  await repo.update(existing.id, data);
} else {
  await repo.insert(data);
}
```

## Unique Constraints on Soft-Delete Tables

`@Unique(['hostId'])` on a table with `AuditColumnsWithDelete` permanently blocks re-creation after soft-delete — the deleted row still occupies the unique slot. Always include `deletedAt` in the composite:

```typescript
// ❌ Bug: Can never re-create after soft-delete
@Unique(['hostId'])

// ✅ Fix: Include deletedAt + NULLS NOT DISTINCT in migration
// Entity:
@Unique(['hostId', 'deletedAt'])
// Migration (must add NULLS NOT DISTINCT manually):
// CREATE UNIQUE INDEX "UQ_my_table" ON "my_table" ("host_id", "deleted_at") NULLS NOT DISTINCT
```

## OneToOne FK on Soft-Delete

When soft-deleting a record that holds a OneToOne FK used elsewhere, set the FK to `null` in the same update to free the constraint for reassignment:

```typescript
await repo.update(id, {
  deletedAt: new Date(),
  deletedBy: triggeredBy,
  teacherId: null, // Free the OneToOne constraint
});
```

## Avoid `.upsert().raw[0]` — Use Query Builder with `.returning()`

TypeORM's `.upsert()` returns a `RawResult` where `.raw[0]` is fragile and driver-dependent. When you need the upserted row back, use the query builder with an explicit `RETURNING` clause:

```typescript
// ❌ Fragile: .raw[0] shape is not guaranteed
const result = await repo.upsert(data, {
  conflictPaths: ["hostId", "memberId"],
});
const id = result.raw[0].id; // may break across TypeORM versions

// ✅ Reliable: explicit RETURNING clause
const result = await manager
  .createQueryBuilder()
  .insert()
  .into(Entity)
  .values(data)
  .orUpdateTyped(["value"], ["hostId", "memberId"])
  .returning('"id"')
  .execute();
const id = result.raw[0].id; // RETURNING makes this reliable
```

## Don't Use `repository.merge()` — Typing is Poor

TypeORM's `merge()` returns a loosely-typed result. Prefer explicit object construction or spread:

```typescript
// ❌ Avoid: loose typing
const merged = repo.merge(entity, updates);

// ✅ Prefer: explicit construction
const updated = { ...entity, ...updates };
```

## No Cascade Deletes — Let FK Violations Throw

Don't set `cascade: true` on entity relations. Unhandled FK constraint violations should fail loudly so they are caught, rather than silently removing dependent rows:

```typescript
// ❌ Avoid: silently removes children
@OneToMany(() => Child, child => child.parent, { cascade: true })

// ✅ Prefer: let the FK constraint throw
@OneToMany(() => Child, child => child.parent)
```

## Use TypeORM Property Names (camelCase) in Query Builder

In query builder conditions, use entity property names (camelCase), not raw DB column names (snake_case):

```typescript
// ❌ Avoid: raw DB column name
.where('corporate_id = :id', { id })

// ✅ Prefer: TypeORM property name
.typedWhere({ corporateId: id })
```

## Upsert with @UpdateDateColumn

`.upsert()` doesn't interact correctly with `@UpdateDateColumn` decorator. When using upsert, manually set the column:

```typescript
// ❌ @UpdateDateColumn won't be updated on upsert
await repo.upsert(data);

// ✅ Manually set the date column
await repo.upsert({ ...data, modifiedAt: new Date() });
```

## Renaming Tables in Production

Tables can't be renamed directly due to deployment gap (migrations run before new code). Use the Postgres updatable views approach:

1. Change naming in code (including raw SQL queries)
2. Set explicit FK names in other entities to prevent TypeORM renaming them
3. Migration: Rename sequence → Rename table → Create view with old name
4. Deploy and verify
5. Second migration: Drop the view

See: https://brandur.org/fragments/postgres-table-rename
Example PR: https://github.com/Ribbon-Experiences/momence-monorepo/pull/1025

---

# Querying & Data Patterns

## Repository vs Query Builder

Prefer the **repository pattern** (`getRepository().find()`) — it's fully typed and suitable for common selects (where, relations, ordering). Use **query builder** (`createQueryBuilder`) only for cases the repository can't handle:

- Additional conditions on joins (e.g., `deletedAt IS NULL`)
- Joins on columns not defined as entity relations
- Complex WHERE with ORs or raw SQL
- Non-trivial GROUP BY clauses
- Subqueries

```typescript
// ✅ Repository pattern — fully typed, preferred for standard queries
const boards = await getRepository(AppointmentBoards).find({
  relations: {
    appointmentVenues: { location: true },
    appointmentStaff: { teacher: true },
  },
  where: { hostId, isDeleted: false },
  order: { name: "ASC" },
});
```

Avoid raw SQL unless absolutely necessary (low-level DB optimizations, one-off migration scripts).

**Always use type-safe query methods:** `typedWhere`, `andTypedWhere`, `withRelations`, and entity selects. The standard `.where()`, `.andWhere()`, `.leftJoinAndSelect()` are deprecated in this codebase — see "Deprecated Methods" section under TypeORM Quirks.

## typedRawQuery for Type-Safe Query Builder Results

When using query builder, wrap with `typedRawQuery()` for strongly typed raw results:

```typescript
const roles = await getRepository(Roles)
  .createQueryBuilder("roles")
  .leftJoin("roles.userRoles", "userRoles", "userRoles.deletedAt IS NULL")
  .groupBy("roles.id")
  .where("roles.hostId = :hostId AND roles.deletedAt IS NULL", { hostId })
  .orderBy("roles.name", "ASC")
  .typedRawQuery()
  .addEntitySelects(Roles, "roles", [
    "id",
    "hostId",
    "predefinedRoleType",
    "name",
    "isTeacherRole",
    "isApplicationRole",
  ])
  .addNumber("COUNT(userRoles.id)::int", "userCount")
  .getRawMany();
```

## JOIN vs WHERE for Relation Conditions

A common mistake: putting conditions on a LEFT JOINed table in the WHERE clause instead of the JOIN clause.

```typescript
// ❌ Wrong: WHERE condition on LEFT JOIN eliminates NULL rows, making it an INNER JOIN
qb.leftJoinAndSelect("session.bookings", "bookings").where(
  "bookings.deletedAt IS NULL",
); // Filters OUT sessions with no bookings!

// ✅ Filter ON a relation (e.g., soft delete): put condition in JOIN
qb.withRelations({
  bookings: { join: "left", condition: "bookings.deletedAt IS NULL" },
});

// ✅ Filter BY a relation (e.g., only sessions with paid bookings): put condition in WHERE
qb.leftJoinAndSelect("session.bookings", "bookings").typedWhere({
  bookings: { isPaid: true },
});
```

**Rule of thumb:**

- **Filter a relation** (which related rows to include) → JOIN condition (`withRelations`)
- **Filter by a relation** (which parent rows to return) → WHERE condition (`typedWhere`)

## Relation Filters on Nullable FKs Act as Implicit INNER JOINs

When using `.find()` with a relation filter on a **nullable FK column**, rows where the relation is NULL are silently excluded — the filter acts as an INNER JOIN even though the relation is optional:

```typescript
// ❌ Bug: Excludes all bookings where purchasedByPaymentTransaction is NULL
const bookings = await repo.find({
  where: {
    recurringBookingId,
    purchasedByPaymentTransaction: { paymentStatus: PaymentStatus.UNPAID },
  },
});

// ✅ Fix: Conditionally include the relation filter only when applicable
const bookings = await repo.find({
  where: {
    recurringBookingId,
    ...(isSubscriptionBased
      ? {}
      : {
          purchasedByPaymentTransaction: {
            paymentStatus: PaymentStatus.UNPAID,
          },
        }),
  },
});
```

**When to watch for this:** Any time a `.find()` WHERE condition includes a relation that has a nullable FK column. Ask: "Can this relation be NULL for valid records in this query?"

---

## Entity Subscriber Mutation Trap

TypeORM `EntitySubscriberInterface` hooks (`beforeInsert`, `beforeUpdate`) mutate the in-memory entity object. Without matching `afterInsert`/`afterUpdate` hooks to reverse the mutation, the entity returned by `.save()` contains mutated data (e.g., encrypted ciphertext instead of plaintext). This affects any code that uses the return value of `saveEntity`/`.save()`.

```typescript
// ❌ Bug: beforeInsert encrypts entity, but save() returns encrypted values
const saved = await saveEntity(WebhookConfig, { secretKey: 'plaintext' })
saved.secretKey // → encrypted ciphertext, not 'plaintext'!

// ✅ Fix: Add afterInsert/afterUpdate hooks to reverse the mutation
afterInsert(event) { decryptColumns(event.entity) }
afterUpdate(event) { if (event.entity) decryptColumns(event.entity) }
```

---

## LEFT JOIN + IS NULL Fails with Multiple Rows Per FK

When checking "no matching related record exists," `LEFT JOIN ... WHERE related.id IS NULL` fails if multiple related rows exist (e.g., one failed + one successful invoice). Use `NOT EXISTS` instead:

```typescript
// ❌ Bug: LEFT JOIN finds the failed row (NULL join), ignoring the successful one
qb.leftJoin(
  "transaction.invoices",
  "invoice",
  "invoice.externalId IS NOT NULL",
).where("invoice.id IS NULL");

// ✅ Fix: NOT EXISTS correctly checks absence of any successful record
qb.andWhere(
  (qb) =>
    `NOT EXISTS (${qb
      .subQuery()
      .select("1")
      .from("host_moloni_invoices", "inv")
      .where("inv.payment_transaction_id = transaction.id")
      .andWhere("inv.external_invoice_id IS NOT NULL")
      .getQuery()})`,
);
```

## Avoid Multiple 1:N Joins

Multiple 1:N joins cause **exponential row growth** — each additional 1:N join multiplies the result set:

- **N:1 join (safe):** session → teacher (1 teacher per session via `teacherId`)
- **1:N join (dangerous):** session → sessionBookings (N bookings per session)

Combining two 1:N joins (e.g., session → bookings + session → waitlist) multiplies rows. Solutions:

- Split into separate DB queries
- Reverse join direction if possible
- Rethink what data you actually need
- Prefilter IDs first, then load full data for those IDs

## OR Across Joins → UNION Subqueries

When a TypeORM query uses `OR` to filter across two join paths and is slow, replace with `UNION` of two subqueries — PostgreSQL optimizes each branch independently with proper index usage:

```typescript
// ❌ Slow: OR across joins prevents index usage
qb.where('paymentTransaction.giftCardId = :id OR transactionItems.giftCardId = :id', { id })

// ✅ Fast: UNION lets optimizer use indexes on each branch
const sub1 = repo.createQueryBuilder().select('t.id').from('payment_transactions', 't').where(...)
const sub2 = repo.createQueryBuilder().select('t.id').from('payment_transactions', 't').innerJoin(...).where(...)
qb.where(`paymentTransaction.id IN (${union(sub1, sub2)})`)
```

Use `union()` / `unionAll()` from `backend/utils/database.ts`.

## Partial Updates: `undefined` vs `null`

In partial update services, `undefined` means "don't change this field" while `null` may be a valid explicit clear. Always gate field-resolution calls on `changes.field !== undefined`:

```typescript
// ❌ Bug: Wipes existing teacherId when field is absent from partial update
const teacherId = await getTeacherId(changes.teacherId); // undefined → null

// ✅ Fix: Preserve existing value when field is absent
const teacherId =
  changes.teacherId !== undefined
    ? await getTeacherId(changes.teacherId)
    : reservation.teacherId;
```

## Query Performance Tips

- **Use indexes in WHERE** — filter most data via FK or ID columns. Watch for patterns that prevent index use (large OR clauses, email filtering).
- **Select only needed columns** — instead of deep relation trees, pick what you need
- **Avoid row-dependent subselects** — subselects that return different data for every row are expensive
- **Denormalize for hot listing queries** — if a value is needed in a high-traffic listing query (e.g., inbox contacts, booking lists), store it as a column on the parent entity instead of using subqueries or EXISTS joins. Update the denormalized column when the source data changes. Example: store `activeHandlerUserId` on the conversation entity rather than subquerying the handlers table in every listing query.
- **Leverage native SQL** — aggregate functions, `EXISTS`, etc.
- **Split complex queries** — prefilter relevant IDs in one query, then load full data for those IDs in a second query

## Transactions

Use `getManager().transaction()` for related data manipulations:

```typescript
await getManager().transaction(async (t) => {
  await storePaymentTransactions({ ...params, manager: t });
  await storeSales({ ...params, manager: t });
});
```

**Rules:**

- Keep transactions short (few ms) to avoid DB lock contention
- Use the transaction manager for ALL queries within its scope (both read and write)
- Derive `getRepository` and `createQueryBuilder` from the transaction manager, not from global imports
- Pass the transaction as `manager` parameter to all underlying services

## Insert/Update Patterns

- **Default:** Use `saveEntity`/`saveEntities` helpers (more type-safe than standard TypeORM methods)
- **Performance-sensitive:** Use `insert`, `update`, `upsert` directly (skip entity checks, don't return the resulting entity)

## TypeORM Utilities Reference

| Utility                                         | Purpose                                                                                   |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `withRelations`                                 | Type-safe relation loading with conditions on query builder                               |
| `saveEntity` / `saveEntities`                   | Better-typed wrapper for save operations                                                  |
| `typedRawQuery`                                 | Type-safe raw query results from query builder                                            |
| `typedWhere`                                    | Type-safe WHERE conditions on query builder                                               |
| `batchQueryIterator` / `safeBatchQueryIterator` | Iterate large result sets in batches                                                      |
| `EntityWithRelations<E, { rel: true }>`         | Require loaded relations in function params                                               |
| `WithRelations<E, 'rel'>`                       | Simpler alias for requiring loaded relations                                              |
| `withDatabaseLogging`                           | Enable query logging within a callback scope                                              |
| `executeAfterTransactionCommit`                 | Run callback after transaction commits (e.g., send notifications)                         |
| `withRelations({ rel: { select: false } })`     | Join for filtering only — don't hydrate relation data into memory                         |
| `relationsOf(Entity, relations)`                | Build typed relations object outside query builder chain (identity fn for type inference) |
| `typedWhere(Entity, where)`                     | Build typed WHERE conditions outside query builder chain                                  |
| `InferWithRelations<Entity, Relations>`         | Type helper: infer entity type with loaded relations marked non-optional                  |
