# Claude Code Skills for Momence

Shared [Claude Code](https://docs.anthropic.com/en/docs/claude-code) configuration — skills, review agents, hooks, and project instructions — used across the Momence monorepo.

## Repository Structure

```
.claude/
  agents/                     # Review agents (parallel subagents for deep analysis)
    review-reuse.md           # Searches codebase for existing utils/components
    review-backend.md         # Service org, manager, audit cols, NestJS, auth asserts
    review-frontend.md        # Box/Text vs styled, rems, forms, React patterns
    review-typeorm.md         # Deprecated methods, entity design, migration quality
    review-migrations.md      # Large table impact, locking, backwards compat
    review-robustness.md      # N+1, transactions, race conditions, edge cases
    review-security.md        # Auth asserts, multi-tenant scoping, data exposure
    review-ai-agent.md        # Tool messaging, policy toggles, argument validation
  hooks/                      # Automated guardrails (block, remind, lint)
  settings.json               # Hook registrations (symlinked into monorepo)
  skills/                     # On-demand skills invoked via /command
    <skill-name>/
      SKILL.md                # Skill definition with YAML frontmatter
CLAUDE.md                     # Shared project instructions (loaded into every conversation)
```

## Setup

This repo is designed to be symlinked into the Momence monorepo so Claude Code picks up everything automatically.

### 1. Clone this repo

Clone alongside your monorepo checkout (adjust paths to your setup):

```bash
git clone git@github.com:Ribbon-Experiences/momence-ai-hub.git /path/to/momence-ai-hub
```

### 2. Create symlinks

From your monorepo root, symlink the `.claude` subdirectories to the cloned repo:

```bash
cd /path/to/momence-monorepo

ln -s /path/to/momence-ai-hub/.claude/skills .claude/skills
ln -s /path/to/momence-ai-hub/.claude/hooks .claude/hooks
ln -s /path/to/momence-ai-hub/.claude/agents .claude/agents
ln -s /path/to/momence-ai-hub/.claude/settings.json .claude/settings.json
```

### 3. Verify

```bash
ls -la .claude/skills .claude/hooks .claude/agents .claude/settings.json
# All should be symlinks pointing to your momence-ai-hub clone
```

### Configuration Files

| File                  | Location         | Version Controlled | Purpose                                                                |
| --------------------- | ---------------- | ------------------ | ---------------------------------------------------------------------- |
| `settings.json`       | Symlink → shared | Yes (in this repo) | Hook registrations — shared across all checkouts                       |
| `settings.local.json` | Per-checkout     | No                 | Permissions (allow/deny), sensitive path blocks, ClickUp write denials |
| `mcp.json`            | Per-checkout     | No                 | MCP server config (database, integrations)                             |
| `CLAUDE.md`           | Repo root        | Yes (in monorepo)  | Project instructions loaded into every conversation                    |

**When adding hooks:** Edit `settings.json` in this repo only — it propagates via symlinks to all monorepo checkouts.

**When adding permissions:** Edit `settings.local.json` in each checkout — these are user-specific and not shared.

---

## Skills

Skills are invoked via slash commands (e.g., `/testing`) and provide on-demand context. They don't bloat the context window — loaded only when invoked.

### Development Skills

| Skill               | Description                                                                      |
| ------------------- | -------------------------------------------------------------------------------- |
| `/coding-standards` | TypeScript style, naming conventions, utility registry, domain terminology       |
| `/backend-patterns` | Endpoint responsibilities, service patterns, guards, error handling, caching     |
| `/nestjs`           | NestJS modules, controllers, DTOs, `@ApiField`, quirks, Public API V2            |
| `/frontend-ui`      | React components, Box/Text, forms, component registry, Zod schemas, translations |
| `/typeorm`          | Entity design, migrations, 20+ TypeORM quirks, query patterns, utility reference |
| `/ai-agent`         | AI agent architecture, `promptx` templates, prompt engineering, tool patterns    |
| `/scheduled-jobs`   | Scheduled/async job patterns, superstruct schemas, self-scheduling               |
| `/testing`          | Testing best practices, mocking, AAA pattern, E2E in PRs                         |
| `/planning`         | Spec guidelines, feature toggles, backwards compatibility, deployment order      |
| `/setup`            | Dev environment, feature flags, secrets, DB access, email testing                |

### Quality & Review Skills

| Skill                 | Description                                                                  |
| --------------------- | ---------------------------------------------------------------------------- |
| `/code-review`        | PR review — orchestrates parallel review agents for deep analysis            |
| `/validate`           | Post-implementation validation — orchestrates agents to self-check before PR |
| `/quick-wins`         | Scan touched files for trivial pre-existing issues to fix                    |
| `/improve`            | Find unprocessed merged PRs and learn from them to enrich skills             |
| `/learn-from-pr`      | Extract lessons from PR review comments into skills/CLAUDE.md                |
| `/learn-from-changes` | Extract lessons from code diffs (bug fixes, new patterns)                    |

---

## Review Agents

Specialized subagents that run **in parallel** during `/code-review` and `/validate`. Each gets its own context window and deeply searches the codebase for issues.

| Agent               | Model    | Preloaded Skills                                 | Checks                                                         |
| ------------------- | -------- | ------------------------------------------------ | -------------------------------------------------------------- |
| `review-reuse`      | sonnet   | `coding-standards`                               | Existing utils/components that could replace new code          |
| `review-backend`    | sonnet   | `backend-patterns`, `nestjs`, `coding-standards` | Service org, manager/audit cols, NestJS, auth asserts          |
| `review-frontend`   | sonnet   | `frontend-ui`, `coding-standards`                | Box/Text vs styled, rems, form patterns, React                 |
| `review-typeorm`    | sonnet   | `typeorm`                                        | Deprecated methods, entity design, migration quality           |
| `review-migrations` | **opus** | _(none)_                                         | Large table impact, locking, backwards compat, deployment risk |
| `review-robustness` | **opus** | `testing`, `scheduled-jobs`, `typeorm`           | N+1, transactions, race conditions, edge cases                 |
| `review-security`   | **opus** | `backend-patterns`, `nestjs`                     | Auth asserts, multi-tenant scoping, data exposure              |
| `review-ai-agent`   | **opus** | `ai-agent`                                       | Tool messaging, policy toggles, argument validation            |

**Why the model split:** Sonnet handles pattern matching (grep + checklist verification) well. Opus is used for agents that require deep reasoning — finding race conditions, evaluating messaging quality, and analyzing security flows.

**Skill-to-agent fit:** Each agent only loads skills directly relevant to its mandate. `coding-standards` is included in agents where naming/style violations overlap with their domain. The `review-reuse` agent has its own inline 76-item reuse catalogue in addition to `coding-standards`.

**Usage:** `/code-review` and `/validate` instruct Claude to spawn relevant agents based on which file types changed. `review-reuse` always runs (addresses the #1 PR feedback category).

### Supplementary Analysis Files

| File                               | Purpose                                                                                             |
| ---------------------------------- | --------------------------------------------------------------------------------------------------- |
| `skills/improve/PR_ANALYSIS.md`    | Top bug classes and review comment patterns from 365 PRs (Sep 2025 — Mar 2026)                      |
| `skills/improve/NICHE_PATTERNS.md` | Domain-specific knowledge too niche for main skills (entity quirks, payment patterns, i18n gotchas) |

---

## Hooks

Automated guardrails configured in `settings.json`. Scripts live in `.claude/hooks/`.

### Pre-edit Guards (block before changes)

| Hook                          | Trigger    | Purpose                                                                |
| ----------------------------- | ---------- | ---------------------------------------------------------------------- |
| `protect-files.sh`            | Edit/Write | Blocks edits to generated types, lock files, `.env`, compiled output   |
| `guard-migrations.sh`         | Edit/Write | Prevents hand-editing existing migration files                         |
| `block-dangerous-commands.sh` | Bash       | Blocks `rm -rf` on broad paths, `git push --force`, `git reset --hard` |

### Post-edit Feedback (run after changes)

| Hook                  | Trigger    | Purpose                                                     |
| --------------------- | ---------- | ----------------------------------------------------------- |
| `lint-on-edit.sh`     | Edit/Write | Runs ESLint on the edited file                              |
| `remind-migration.sh` | Edit/Write | Reminds to `yarn generate:migration` when entities change   |
| `remind-api-regen.sh` | Edit/Write | Reminds to `yarn generate-api` when DTOs/controllers change |

### Session Lifecycle

| Hook                         | Trigger        | Purpose                                                            |
| ---------------------------- | -------------- | ------------------------------------------------------------------ |
| `session-start.sh`           | Startup/Resume | Shows branch, PR status, uncommitted changes                       |
| `check-validate-reminder.sh` | Stop           | Reminds to `/validate` after 5+ file edits without validation      |
| `remind-typecheck.sh`        | Stop           | Reminds to run `tsc --noEmit` if frontend files were edited        |
| `preserve-context.sh`        | Pre-compaction | Snapshots modified files, commits, TODOs before context compaction |

---

## Adding or Editing

### Skills

Each skill is a `SKILL.md` file in its own folder under `.claude/skills/`:

```markdown
---
name: my-skill
description: When to trigger this skill. Be specific so Claude knows when to load it.
---

# Skill Content

Your instructions, patterns, and examples here.
```

### Agents

Each agent is a `.md` file in `.claude/agents/`:

```markdown
---
name: review-something
description: What this agent reviews
tools: Read, Grep, Glob, Bash
model: sonnet
skills:
  - relevant-skill
maxTurns: 30
effort: high
---

You are a **domain reviewer** for the Momence monorepo.
Your instructions, checklists, and output format here.
```

### Hooks

1. Create script in `.claude/hooks/`
2. `chmod +x` the script
3. Register in `.claude/settings.json` under the appropriate event

Changes are immediately available in new Claude Code sessions.
