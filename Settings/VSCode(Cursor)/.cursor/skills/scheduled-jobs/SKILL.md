---
name: scheduled-jobs
description: Patterns for creating scheduled jobs in Momence. Use when creating cron jobs, self-scheduling jobs, or working with job metadata and superstruct schemas. Includes guidance on when to use async jobs instead.
---

# Scheduled Jobs

> **IMPORTANT: Prefer async jobs over scheduled jobs when possible.**
> Scheduled jobs use the `scheduled_jobs` DB table as a queue, which is a known performance bottleneck. **Async jobs** use SQS message queues and should be used whenever you need to defer work to background and **don't need it to start at a specific future date**. Only use scheduled jobs when you need time-based scheduling (run at specific date/time, recurring cron-like patterns, windowed processing).

## Job Metadata Schema

```typescript
// ❌ Avoid: TypeScript type for job metadata
type JobMeta = { windowEnd: string }
export const myJob = defineScheduledJob<JobMeta>({ ... })

// ✅ Prefer: Superstruct schema for job metadata
import { object, optional, string } from 'superstruct'

const metadataSchema = optional(
    object({
        windowEnd: string(),
    })
)

export const myJob = defineScheduledJob({
    schema: metadataSchema,
    run: async ({ metadata }) => { ... },
})
```

## Key Principles

- **Store entity ID in job metadata, not job ID on the entity.** Never FK-reference `scheduled_jobs` from entities. The job owns the reference (`metadata: { giftCardId: 123 }`), not the entity (`giftCardId → scheduledJobId`).
- **Reschedule when the triggering date is edited.** Any PUT/PATCH endpoint that modifies a date a scheduled job is keyed to must cancel + recreate the job.
- **Filter consumed items in reminder jobs.** Reminder jobs targeting expiring items must also filter `balance > 0` / `quantity > 0` — don't send reminders for fully consumed items.
- **Use superstruct schema, not TypeScript type** - Runtime validation is essential for job metadata
- **Keep metadata minimal** - Compute derived values at runtime, don't store them
- **Self-scheduling jobs need init scripts** - For crash recovery, ensure jobs reschedule on startup
- **Jobs must be self-contained** - Don't import constants, types, or helpers from other jobs. If two jobs share a value, redefine it locally or extract to a shared utility outside of jobs. Cross-job imports create unexpected coupling that makes jobs harder to reason about, test, and deploy independently.

## Self-Scheduling Pattern

For jobs that schedule their next run dynamically:

```typescript
export const myRecurringJob = defineScheduledJob({
    schema: metadataSchema,
    run: async ({ metadata, scheduleNext }) => {
        // Do work...

        // Schedule next run
        const nextRun = dayjs().add(1, 'hour').toDate()
        await scheduleNext({ runAt: nextRun, metadata: { ... } })
    },
})
```

## Crash Recovery

Self-scheduling jobs can be lost if the server crashes before scheduling the next run. Add an init script:

```typescript
// In job file or separate init script
export const ensureJobScheduled = async () => {
    const existingJob = await findScheduledJob(myRecurringJob)
    if (!existingJob) {
        await scheduleJob(myRecurringJob, {
            runAt: new Date(),
            metadata: { ... },
        })
    }
}
```

**Init scripts: align to window boundary.** When initializing periodic jobs, schedule at the nearest aligned boundary — not an arbitrary future time:

```typescript
// ❌ Avoid: Arbitrary offset (misaligns windows)
const windowEnd = dayjs().add(5, "minutes").toDate();

// ✅ Prefer: Round up to next window boundary
const now = dayjs();
const currentMinute = now.minute();
const nextBoundary = Math.ceil((currentMinute + 1) / 5) * 5;
const windowEnd = now.startOf("hour").add(nextBoundary, "minutes").toDate();
```

## Job Deduplication

**Do NOT match by `scheduledAt` for deduplication.** Jobs scheduled in the past are auto-adjusted to `now()` by the scheduler, so exact timestamp matching will fail:

```typescript
// ❌ Won't work — scheduledAt may have been adjusted
const existing = await myJob.findOneBy({ scheduledAt: nextWindowEnd });

// ✅ Check if any scheduled job of this type exists
const existing = await myJob.typedFindOneBy({});

if (!existing) {
  await myJob.schedule({ scheduledAt: nextWindowEnd }, metadata);
} else {
  logger.info(
    { existingJobId: existing.id },
    "Next job already scheduled, skipping",
  );
}
```

## Time Window Jobs

For jobs that process items within a time window, **store only `windowEnd` in metadata** and derive `windowStart` at runtime:

```typescript
// ❌ Avoid: Storing both start and end (redundant, can drift)
const metadataSchema = optional(
  object({ windowStart: string(), windowEnd: string() }),
);

// ✅ Prefer: Store only windowEnd, compute windowStart from window size
const WINDOW_SIZE_MINUTES = 5;

const metadataSchema = optional(
  object({
    windowEnd: string(),
  }),
);

export const windowedJob = defineScheduledJob({
  schema: metadataSchema,
  run: async ({ metadata }) => {
    const windowEnd = metadata?.windowEnd
      ? new Date(metadata.windowEnd)
      : new Date();
    const windowStart = dayjs(windowEnd)
      .subtract(WINDOW_SIZE_MINUTES, "minutes")
      .toDate();

    // Query items in window
    const items = await repo.find({
      where: {
        createdAt: Between(windowStart, windowEnd),
      },
    });

    // Process items...
  },
});
```
