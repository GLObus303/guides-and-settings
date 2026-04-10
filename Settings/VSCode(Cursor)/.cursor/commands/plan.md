# plan

You are in PLAN mode.

INPUT (MANDATORY):

- Use `.cursor/YYYY-MM-DD-<topic>-readme.md` as the primary source of truth.
- Consult and comply with these indexed Skills:
  @Best practices Skills
  @Best Practices momence
  @Careful Migration
  @Nestjs momence
- If any plan step conflicts with these skills, call it out explicitly.

GOAL:
Produce a precise, execution-ready implementation plan.

STRICT RULES:

- DO NOT modify or generate production code
- DO NOT implement anything
- Planning only
- Follow all Cursor rules, agent rules, and project conventions
- Respect all constraints, risks, and findings from `.cursor/YYYY-MM-DD-<topic>-readme.md`
- Do NOT guess — surface uncertainty explicitly

STYLE REQUIREMENTS (IMPORTANT):

- Make the plan EXTREMELY CONCISE
- Prefer bullets, fragments, keywords
- Sacrifice grammar for clarity + density
- No fluff, no prose, no repetition

PLANNING REQUIREMENTS:

- Validate requirements completeness
- Identify missing / ambiguous inputs
- Small, ordered, low-blast-radius steps
- Explicit file / module targets
- Migration-safe sequencing (if applicable)
- Include validation steps (lint, types, tests)
- Call out risky steps clearly

OUTPUT:

- You will output everything to the temporary plan file as usual!
- The file MUST include (in this order):
  1. 📌 Requirements snapshot (short)
  2. 🎯 Goals / Non-goals
  3. 🧩 Assumptions
  4. 🪜 Step-by-step plan (concise bullets)
  5. 🧪 Verification checklist
  6. ⚠️ Risks / migration notes
  7. ❓ Unresolved questions (MANDATORY, may be empty)

Do not proceed to implementation. Stop after writing the markdown file.
