---
name: setup
description: Guide for setting up the Momence development environment. Use when someone asks about backend setup, frontend setup, static server setup, database refresh, or migrations.
---

# Momence Setup Guide

## Backend Setup Steps

1. **Install eslint-plugin dependencies:**

   ```bash
   cd eslint-plugin && yarn
   ```

2. **Install backend dependencies:**

   ```bash
   cd backend && yarn
   ```

3. **Refresh Docker credentials:**

   ```bash
   aws sso logout
   ```

4. **Docker Desktop requirements:**
   - Min 8 GB RAM allocated
   - Min 128 GB disk space

5. **Initialize environment:**

   ```bash
   task init  # Downloads images, runs pg_restore (~3 mins)
   ```

6. **Build backend:**

   ```bash
   yarn build
   ```

7. **Apply migrations:**

   ```bash
   task  # Run to apply latest DB migrations
   ```

8. **Start development (run in parallel):**

   ```bash
   # Terminal 1:
   yarn swc:dev  # Build and watch changes

   # Terminal 2:
   yarn dev      # Start backend server
   ```

9. **Verify:** Visit http://localhost:1337 (or $PORT from .env)
   - Route error is expected/ok

### Database Refresh

Production database dump is made daily with trimmed data (~300MiB):

```bash
cd backend
task refresh  # Get and load latest database dump
```

### Migrations

Migrations are created automatically by TypeORM:

```bash
# Generate migration after DB entity changes:
yarn migration:generate -n {NAME_OF_THE_MIGRATION}

# Create empty migration file for custom migrations:
yarn migration:create db/migrations/{NAME_OF_THE_MIGRATION}

# Delete migration files (!ONLY LOCAL ENV USAGE!):
# Delete files from .build/db/migrations
```

**Important: Clean Migration Generation Workflow**

If `yarn migration:generate` includes unrelated changes (index drops/creates, unrelated column changes), your local DB is out of sync. Follow these steps to get clean migrations:

```bash
# 1. Ensure you're on main branch with fresh DB
git checkout main
git pull origin main
cd backend
task refresh  # Downloads fresh prod DB dump (~3 mins)

# 2. Switch to feature branch
git checkout your-feature-branch

# 3. Build with feature branch entities
yarn build

# 4. Generate migration (should now be clean)
yarn migration:generate -n YourMigrationName
```

**Why this works:**

- `task refresh` gives you a clean DB matching production schema
- Building on feature branch compiles your new entity changes
- TypeORM now only detects the actual differences you made

---

## Frontend Setup Steps

1. **Install dependencies:**

   ```bash
   cd frontend
   yarn install
   ```

2. **Initialize eslint-plugin:**

   ```bash
   cd ../eslint-plugin
   yarn
   ```

3. **Start dev server:**

   ```bash
   cd ../frontend
   yarn start:dashboard  # Or :ondemand, :checkout, :plugins
   ```

4. **Verify:** Visit http://localhost:3000/dashboard/745 (testing host dashboard)

**Important:** Never run `generate-api` script when webpack is running. If broken, clear `/node_modules/.cache` folder.

### VSCode TypeScript Setup

Add to `frontend/.vscode/settings.json`:

```json
"typescript.tsdk": "node_modules/typescript/lib"
```

---

## Static Server Setup

Static server enables seamless transition between frontends (host-dashboard, checkout-pages, etc.)

1. **Install dependencies:**

   ```bash
   cd static-server
   npm install  # Uses npm, not yarn
   ```

2. **Configure environment:**

   ```bash
   cp .env.template .env
   ```

3. **Start static server:**

   ```bash
   npm run start
   ```

4. **Start checkout pages:**

   ```bash
   cd ../frontend
   yarn start:checkout
   ```

5. **Test:** Navigate to Classes → open a class → click "Class signup link"
   - Should point to http://localhost:4000/... deeplink
   - Checkout page should open in new window

---

## Feature Flags

**Generate new:**

```bash
yarn generate:feature-flag -n myFeatureFlag
# Options: -r (readonly), -b (backend-only), -d "description"
```

**After generating:**

1. Run `yarn generate:migration -s` (schema-only migration)
2. Wait for recompile
3. Run `yarn db:migrate`
4. Frontend: `cd frontend && yarn generate-api`

**Removing:** No script yet — manually search and remove all references. Must delete DB references before merging.

---

## Permissions

For the full checklist (both BE and FE steps with file paths), see the "Adding New Permissions" section in `/backend-patterns`.

---

## Useful Backend Commands

```bash
yarn watch              # Build in watch mode
yarn dev                # Auto-reload (needs separate build)
yarn dev:watch          # Runs AND builds
yarn db:local           # Switch to local DB creds
yarn db:remote          # Switch to remote DB creds
yarn pending-jobs       # Simulate scheduler locally
yarn job <jobId>        # Run specific job locally
yarn runnable <script>  # Run runnable script
yarn scheduler:mock     # Mock scheduler (for email testing)
```

## GitHub Actions Reusable Scripts

```bash
reusable/createIndex "CREATE INDEX my_idx ON my_table (col)"  # Async index creation
reusable/decodeId --id <arg>                                   # Decode/encode obfuscated IDs
reusable/killLongRunningQueries [kill]                         # Kill slow queries
reusable/killAllConnections                                     # LAST RESORT
```

---

## Database Access

| Environment | Connection                                        | Notes                                 |
| ----------- | ------------------------------------------------- | ------------------------------------- |
| Local       | `localhost:5433`, user/pass `postgres/postgres`   | Or `yarn db:local`                    |
| Remote dev  | `task get-remote-db-params` then `yarn db:remote` | Requires AWS VPN                      |
| Production  | Read-only replica                                 | Requires VPN + onboarding credentials |

---

## Secrets & Configuration

| Type                 | Where to Configure                                                                                        |
| -------------------- | --------------------------------------------------------------------------------------------------------- |
| General (non-secret) | Set default in `config.ts`                                                                                |
| Secret               | Add to `ops/charts/app/values_prod.yaml` `envSecretMap` + store in AWS Secrets Manager with `api/` prefix |
| Quickly adjustable   | Add to `ops/charts/app/values.yaml` — merged changes auto-deploy                                          |

---

## Email Testing Locally

Mailpit runs automatically in Docker:

- SMTP: port 1025
- Inbox UI: `http://localhost:8025`
- For scheduled email jobs: run `yarn scheduler:mock` first
- Transactional templates must be enabled per-host in Settings → Email templates

---

## SQL Query Approval (Production)

All SQL queries run via admin panel require engineer approval (posted to `#sql-query-requests` Slack channel).

**Best practices:**

- Keep scripts short (<100 lines), provide description/context
- Be aware of dangerous ops: missing WHERE, INSERT FROM SELECT
- Consider alternatives: CSV import, admin scripts, UI changes
- **Side effect traps:** `appointment_attendees.price` must sync with `appointment_reservations`, `bought_memberships` requires full `payment_transactions` + `sales` ecosystem

---

## Timezone Utilities

Use these instead of raw `dayjs.tz()` for DST-safe operations:

- `createTimezonedDayStart` — replacement for `dayjs.tz(date, timeZone)`, handles DST correctly
- `addDaysInTimeZone` — shifts by days while preserving time across DST boundaries
- Available in both `backend/utils/timeZones.ts` and `frontend/libs/utils/src/timeZones.ts`
