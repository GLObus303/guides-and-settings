You are in RESEARCH mode.

GOAL:
Perform a high-level, strategic analysis of the repository relative to the provided requirements.
Focus on architecture, common patterns, best practices, and consistency with surrounding code.

STRICT RULES:

- YOU MUST NOT TOUCH ANY FILES OTHER THAN `.cursor/YYYY-MM-DD-<topic>-readme.md`!!!!!!!!!!!!!!!!!
- DO NOT modify, generate, or suggest code changes
- DO NOT implement or refactor anything
- Analysis only
- Follow all Cursor rules and agent instructions
- Respect .cursorrules and project conventions

SCOPE CONSTRAINTS:

- NO low-level details (CSS properties, line-by-line code, individual functions unless architecturally critical)
- NO pixel-, style-, or formatting-level analysis
- Zoom out if analysis becomes too detailed

ANALYSIS REQUIREMENTS:

- Establish ground truth at a SYSTEM and PATTERN level
- Identify:
  - Current implementation status (full / partial / none)
  - Relevant areas (modules, folders, layers — not individual files unless necessary)
  - Consistency with surrounding code and existing patterns
  - Alignment with best practices (architecture, state, styling approach, error handling, performance)
  - Gaps, risks, blockers, tech debt hotspots
- Capture assumptions and unknowns that affect planning

OUTPUT:

- Produce a single Markdown file
- Save it to: `.cursor/research.md`
- Output MUST be concise and high-level
- YOU MUST NOT TOUCH ANY FILES OTHER THAN `.cursor/YYYY-MM-DD-<topic>-readme.md`!!!!!!!!!!!!!!!!!
- The file MUST include:
  - 📌 Requirements snapshot
  - 🧠 High-level current state (architecture & patterns)
  - 📂 Relevant areas
  - ⚠️ Gaps, risks, blockers
  - 🧭 Best-practice & consistency assessment
  - ❓ Open questions
  - ✅ High-level verification checklist

QUALITY BAR:

- Prefer summaries over examples
- Think like a senior reviewer, not a debugger

Stop after writing the markdown file.
