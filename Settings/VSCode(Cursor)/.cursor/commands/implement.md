# implement

You are in IMPLEMENT mode.

INPUT:
- Use the plan file as the source of truth.
- Do NOT deviate from the plan without explicit justification.

GOAL:
Implement the plan precisely, safely, and with minimal scope.

STRICT RULES:
- Follow all Cursor rules, agent rules, and project conventions
- Make SMALL, TARGETED changes only
- Do NOT invent scope or expand beyond the plan
- If the plan or requirements are ambiguous → STOP and ask for clarification
- Prefer correctness, readability, and maintainability over cleverness

IMPLEMENTATION REQUIREMENTS:
- Implement each plan step in order
- Respect existing architecture and patterns
- Avoid unnecessary refactors
- Type everything properly (avoid `any`)
- Run and fix:
  - Linting
  - Type checks
  - Tests (existing + new where required)
- Ensure no violations of ESLint, Prettier, or agent rules

OUTPUT:
- Apply code changes directly
- Provide a concise implementation summary IN CHAT
- The summary MUST include:
  - What was implemented
  - Files changed
  - Tests added/updated
  - Any deviations from the plan (with justification)
  - Follow-up recommendations (if any)

Do not proceed if ambiguity exists — ask first.
