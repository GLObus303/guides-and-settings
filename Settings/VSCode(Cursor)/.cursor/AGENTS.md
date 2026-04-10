# Momence Development Notes

Quick reference for working in the Momence monorepo.

**Skills available:** `/setup`, `/testing`, `/frontend-ui`, `/ai-agent`, `/planning`, `/scheduled-jobs`, `/typeorm`, `/nestjs`, `/validate`, `/learn-from-pr`, `/learn-from-changes`, `/code-review`, `/coding-standards`, `/backend-patterns`

---

## Repository Structure

```
momence-monorepo/
├── backend/          # Node 20.19.4, Taskfile.yaml
├── frontend/         # Node 20.19.4, Taskfile.yaml
├── static-server/    # Node 20.19.4
└── admin-panel/      # Node 14.17.0
```

---

## Task Commands

### Backend (`cd backend && task <command>`)

- `task init` - Setup local environment
- `task refresh` - Get and load new database dump
- `task yarn -- <command>` - Run yarn in API container
- `task up` / `task down` - Start/stop containers
- `task logs` - Follow container logs
- `task get-password-manager-secret -- <secret-id>` - Get AWS secrets

### Frontend (`cd frontend && task <command>`)

- `task init` - Setup frontend environment
- `task up` / `task down` - Start/stop containers
- `task yarn` - Run yarn in dashboard container
- `task logs` - Follow logs

### GitHub PR Commands

```bash
# Get PR review threads (comments) with resolution status
gh api graphql -f query='
{
  repository(owner: "Ribbon-Experiences", name: "momence-monorepo") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          comments(first: 10) {
            nodes {
              body
              path
              line
              author { login }
              createdAt
            }
          }
        }
      }
    }
  }
}'
```

---

## Environment Setup

- **Node versions:** Auto-switch via `.nvmrc` (nvm configured)
- **AWS CLI:** Installed (v2.32.13), profiles configured in `~/.aws/config`
- **AWS profiles available:**
  - `cloudops-prod` - Primary profile for Task commands
  - `momence-sandbox` - Sandbox environment
  - `momence-prod` - Production
  - `workloads-prod` - Workloads
- **AWS auth:** Login before Task commands: `aws sso login --profile cloudops-prod`
- **Docker:** All services run in containers via docker-compose
- **Environment variables:** Set in `.env` files (e.g., `AWS_CLOUDOPS_PROFILE=cloudops-prod`)

For detailed setup steps, use `/setup` skill.

---

## Path-Scoped Rules

The `.claude/rules/` directory contains path-scoped rules that load automatically when working on matching files. These are lighter than skills — no need to invoke them.

| Rule            | Glob                                           | Purpose                                       |
| --------------- | ---------------------------------------------- | --------------------------------------------- |
| `backend.md`    | `backend/**/*.ts`                              | Service patterns, utilities, error handling   |
| `frontend.md`   | `frontend/**/*.{ts,tsx}`                       | Box/Text, rems, hooks, Zod, translations      |
| `entities.md`   | `backend/db/entities/**/*.ts`                  | AuditColumns, relations, decorators, ordering |
| `migrations.md` | `backend/db/migrations/**/*.ts`                | Safety, backwards compat, large table ops     |
| `ai-agents.md`  | `backend/services/hostDashboardAgents/**/*.ts` | Tool responses, policy toggles, validation    |

---

## Hooks (Automated Guardrails)

The `.claude/settings.json` configures hooks that run automatically. Scripts live in `.claude/hooks/` (symlinked from `momence-shared`).

**Settings.json sync:** The shared repo (`momence-shared/.claude/settings.json`) is the source of truth for hook configuration. All monorepo checkouts symlink to it — hook changes propagate automatically.

- `settings.json` — **symlinked** to shared (hooks config only, no permissions)
- `settings.local.json` — **per-checkout** (not version controlled). Contains `permissions.deny` for sensitive paths and ClickUp write ops
- When adding new hooks, update only `momence-shared/.claude/settings.json`

**Pre-edit guards (block before changes happen):**

- **File protection** — Blocks edits to generated API types, lock files, `.env`, and compiled output
- **Migration guard** — Prevents hand-editing existing migration files (generate new ones instead)
- **Dangerous command blocker** — Blocks `rm -rf` on broad paths, `git push --force`, `git reset --hard`, `git clean -f`, `DROP DATABASE`

**Post-edit feedback (run after each edit):**

- **Auto-lint** — Runs eslint on the specific edited file for fast feedback
- **Migration reminder** — When entity schema decorators change, reminds to run `yarn generate:migration`
- **API regen reminder** — When DTOs or controllers with `@ApiField`/route decorators change, reminds to rebuild and `yarn generate-api`

**Session lifecycle:**

- **Session start context** — On startup/resume, shows current branch, open PR status, uncommitted changes, and commits ahead of main
- **Context preservation** — Before compaction, snapshots modified files, staged changes, branch commits, and in-progress markers so context survives long sessions
- **Validate reminder** — On stop, reminds to run `/validate` if 5+ file edits were made without validation

---

## Review Agents (Parallel Deep Analysis)

Specialized subagents in `.claude/agents/` that run in parallel during `/code-review` and `/validate`. Each gets its own context window, preloaded domain skills, and deeply searches the codebase.

| Agent               | Domain                                            | Preloaded Skills                                 |
| ------------------- | ------------------------------------------------- | ------------------------------------------------ |
| `review-reuse`      | Existing utils/components reuse                   | `coding-standards`                               |
| `review-backend`    | Service org, manager, NestJS, auth asserts        | `backend-patterns`, `nestjs`, `coding-standards` |
| `review-frontend`   | Box/Text, rems, forms, React                      | `frontend-ui`, `coding-standards`                |
| `review-typeorm`    | Deprecated methods, entities, migrations          | `typeorm`                                        |
| `review-migrations` | Large table impact, locking, backwards compat     | `typeorm`                                        |
| `review-robustness` | N+1, transactions, race conditions                | `testing`, `scheduled-jobs`, `typeorm`           |
| `review-security`   | Auth asserts, multi-tenant scoping, data exposure | `backend-patterns`, `nestjs`                     |
| `review-ai-agent`   | Tool messaging, policy toggles                    | `ai-agent`                                       |

**Usage:** `/code-review` and `/validate` skills instruct Claude to spawn relevant agents in parallel based on which file types changed. Always spawn `review-reuse` — it catches the #1 PR feedback category.

---

## Verification & Debugging Discipline

**Verification gate:** Before claiming any task is complete, you MUST:

1. Run the relevant verification command (`yarn test`, `yarn lint`, `tsc --noEmit`, etc.)
2. Read the actual output — do not assume success
3. Only claim completion with evidence from fresh output

Never use "should work", "probably fine", or "seems correct" — show the passing output.

**Debugging protocol (when something fails):**

1. **Investigate** — Read the error, trace the data flow, understand the root cause
2. **Find precedent** — Search for similar working code in the codebase
3. **Hypothesize** — State one specific hypothesis before changing code
4. **Fix minimally** — Make the smallest change that addresses the root cause
5. **Verify** — Run the failing test/command again to confirm the fix

Do NOT apply random fixes or change multiple things at once. After 3 failed attempts at the same issue, stop and reassess the approach.

---

## Mandatory Skill Usage

Skills exist to prevent repeated mistakes. **Loading them is not optional** — skipping them leads to avoidable PR comments.

**Before implementing:**

- Building backend services/endpoints → load `/backend-patterns` and `/coding-standards`
- Building frontend components/forms → load `/frontend-ui` and `/coding-standards`
- Working with entities/migrations → load `/typeorm`
- Working with NestJS controllers/DTOs → load `/nestjs`
- Working with AI agent tools → load `/ai-agent`

**After implementing:**

- Always run `/validate` before considering any significant implementation done
- If `/validate` finds issues, fix them before moving on

**When reviewing code (own or others'):**

- Always run `/code-review` — it loads the checklist and spawns parallel review agents
- Never review without loading the skill first — single-pass reviews miss issues that are already documented in skills

**When asked to review PR comments:**

- Always run `/learn-from-pr` to extract lessons and update skills

---

## Coding Standards

**When changing implementation behavior (return values, messages, logic), always update the corresponding tests to match.** Don't change implementation without checking for existing tests that assert the old behavior.

Path-scoped rules in `.claude/rules/` enforce domain-specific patterns automatically. For full reference: `/coding-standards`, `/backend-patterns`, `/nestjs`.

---

## Backend → Frontend Type Generation

**Workflow (NestJS endpoints):**

1. **Backend:** Add/update DTOs with `@ApiField` decorators
2. **Backend:** Register controller in the module's `.module.ts` file
3. **Backend:** Build backend: `cd backend && yarn build`
4. **Frontend:** Run `yarn generate-api` (requires backend running on port 1337)
5. **Frontend:** Import types from `@momence/api-<module>` (e.g., `@momence/api-host`)

For detailed NestJS patterns (controllers, DTOs, `@ApiField`, modules, pagination), use the `/nestjs` skill.

**Express routes (manual types):**
Some Express routes (e.g., Gympass) have manually defined types in `frontend/libs/api/src/`:

- Response types: `frontend/libs/api/src/responseTypes/integrations/`
- Endpoint params: `frontend/libs/api/src/endpoints/integrations/`
  These need manual updates when backend changes.

**Enum Conventions:**

- Backend: TypeScript enum in `backend/db/entities/enums/`
- Frontend: Generated as const object (NOT TypeScript enum)

---

## Database & Migrations

For database migrations (generating, reviewing, enum migrations, FK constraints, history log tables) and entity design principles, use the `/typeorm` skill.

Key reminders:

- Generate: `cd backend && yarn generate:migration -n DescriptiveName`
- Always review generated migrations for unrelated changes
- New columns on existing tables must be nullable or have defaults

---

---

## Deployment Overview

**Backwards Compatibility (Critical):**
See `/planning` skill for full guidance. Key rules:

- Old frontend WILL run against new backend during deployment
- Backend validations must accept requests from old frontend versions
- New columns/fields must be nullable or have defaults
- No breaking changes to existing API endpoints
- Use `@IsTemporaryOptional` in NestJS DTOs for fields added during transitions (see `/nestjs` skill)

**Deployment Flow:**

1. DB migrations → 2. Scheduler & async workers → 3. Backend → 4. Frontend

---

## Engineering Documentation

Additional domain docs in `momence-docs/docs/`:

- `technical/backend/security.md` - Endpoint guards, multi-tenant data scoping
- `technical/frontend/code-organization.md` - Monorepo structure, apps/libs, naming
- `technical/scheduler/architecture.md` - Scheduler dispatcher/worker architecture
- `business/` - Domain knowledge (bookings, memberships, payment plans)

When in doubt about patterns, best practices, or architecture decisions, check these docs.
