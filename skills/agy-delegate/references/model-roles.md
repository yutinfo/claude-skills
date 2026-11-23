# agy models by software-dev role

Condensed from the user's notes `model_roles_for_software_dev.md` (Antigravity, Nov 2026). The slugs depend on the account, so **preflight wins over this file**. Commands below are the corrected **headless** form: `-p "<prompt>"` goes last. The source note's `agy -p --model X "…"` is wrong and errors in 1.5.13. In practice use `scripts/agy-run.sh run --model … --mode …`.

Don't hire a Principal Architect to fix CSS typos, and don't send a junior to design a distributed DB without a spec. Matching model to role means better code and less quota.

## 1. Role map

| Slug | Role | Effort | Quota |
|---|---|---|---|
| `gemini-4-argon-*` | Principal System / Security Architect | medium, high | foundation/deep work only |
| `claude-opus-5-5-*` | Distinguished Engineer, hard-bug escalation | medium, high | only when stuck or critical; **ask the user first** |
| `gemini-pro-orchestrator-g1-pro` | Principal Lead + execution squad (Argon plans) | auto | much cheaper than pure Argon |
| `gemini-pro-orchestrator-neon` ⭐ | Tech Lead + full-stack squad (Neon plans → Hydrogen codes) | auto | **best value for features** |
| `gemini-4-neon-*` ⭐ | Senior full-stack / backend engineer | medium (main), high/xhigh (hard) | **daily sweet spot** |
| `claude-sonnet-5-5-*` | Senior frontend/product engineer, code reviewer, spec/ADR/README writer | medium, high | good value vs Opus |
| `gemini-4-hydrogen-*` | Mid-level implementer, QA/test engineer, swarm worker | low, medium | **cheapest and fastest** |
| `gemini-3.8-flash-*` | DevOps / CI-CD / scripting bot | low, medium | very cheap; for automation |
| `gpt-oss-120b-medium` | Independent peer reviewer (different vendor, open weights) | medium | cross-vendor second opinion |

Role details:
- **Architect** (`argon-high`, `--mode plan`): system/microservice/event design, DB schema, big migrations (framework swap, splitting a monolith), security audit, threat modelling, race conditions.
- **Orchestrator**: end-to-end features (DB → API → frontend → tests), refactors of 10–30 files on one plan, "fire once and let it finish". Use `g1-pro` for greenfield or architectural migration.
- **Neon**: business logic, REST/GraphQL, auth, payment flows, multi-file refactors, breaking dependency upgrades, multi-layer bugs.
- **Sonnet**: complex UI (React/Next/Vue, design system, state), PR review (smells, maintainability, a11y, naming), behaviour-preserving cleanup, tech specs/ADR/README.
- **Opus / Neon-xhigh**: escalation after Neon/Hydrogen loop 2–3 rounds, critical paths (payments, crypto, core algorithms), hard trade-offs. **Consult only.** Once the root cause or plan is known, switch back to Hydrogen/Neon-medium to write the fix.
- **Hydrogen**: code from an existing plan (CRUD, DTO, schema validation, form UI), unit/E2E tests, mocks, fixtures, repetitive multi-file edits (types, JS→TS, import paths), parallel `/swarm` workers.
- **Flash / Hydrogen-low**: headless CI jobs, commit messages, PR descriptions, changelogs from `git log`, shell, basic Dockerfiles, GitHub Actions YAML, regex, short SQL.
  - `git diff --staged | agy --model gemini-3.8-flash-low --print-timeout 120s -p "Write a one-line Conventional Commits message"`
- **gpt-oss**: second opinion after a Gemini/Claude plan or code, out-of-the-box alternatives (`--mode plan`).

## 2. SDLC stage → model

| Stage | Main | Fallback |
|---|---|---|
| 1. Discovery / explore codebase | `gemini-4-hydrogen-medium` | `gemini-3.8-flash-medium` |
| 2. Architecture & planning (`--mode plan`) | `gemini-4-argon-high` or `gemini-4-neon-high` | `claude-opus-5-5-medium` |
| 3. Feature implementation, multi-file | `gemini-pro-orchestrator-neon` | `gemini-4-neon-medium` / `claude-sonnet-5-5-medium` |
| 4. Boilerplate & small UI | `gemini-4-hydrogen-medium` | `gemini-4-hydrogen-low` |
| 5. Normal debugging (stack trace, failing test) | `gemini-4-neon-medium` | `gemini-4-hydrogen-high` |
| 6. Hard debugging (race, leak, stuck) | `gemini-4-neon-xhigh` or `claude-opus-5-5-high` | `gemini-4-argon-high` |
| 7. Code review & refactor, security check | `claude-sonnet-5-5-high` | `gemini-4-neon-high` / `gpt-oss-120b-medium` |
| 8. Testing & QA | `gemini-4-hydrogen-medium` | `gemini-4-neon-low` |
| 9. Docs, git, CI-CD | `gemini-4-hydrogen-low` | `gemini-3.8-flash-low` |

## 3. Team recipes

- **A. Budget (default for this user, whose quotas are tight):**
  - 80% implement + test on `hydrogen-medium`
  - 15% plan + hard bugs on `neon-medium/high`
  - 5% scripts and commits on `flash-low`
- **B. Balanced (production work):**
  - features on `orchestrator-neon`
  - daily coding on `neon-medium`
  - frontend and review on `sonnet-5-5-medium`
  - tests and boilerplate on `hydrogen-medium`
- **C. Heavy (finance, large or high-risk refactor), only with the user's OK:**
  - architecture on `argon-high` / `orchestrator-g1-pro`
  - critical review on `opus-5-5-high`
  - core refactor on `neon-high` + `sonnet-5-5-high`
  - verification on `hydrogen-high`

## 4. Anti-patterns (waste quota, worse output)

1. **Opus / Argon / xhigh on everything.** It is slow and drains quota with no quality gain on easy work.
2. **Hydrogen-low planning a big system with no spec.** It misses edge cases and causes fix loops. A good plan from Neon-high up front costs less.
3. **Never switching models.** Plan on argon-high in one run, then code on hydrogen-medium in the next. Interactively, use `/model` and `/effort`.
4. **Re-using the same model while stuck.** After 2–3 failed rounds on one bug, stop. `/compact` and switch vendor or tier (Neon → Sonnet/Opus 5.5 or Argon); a fresh view often solves it in one round. In headless mode, send a new run with the symptoms, the hypotheses already ruled out and the commands tried.

## 5. Team routing reminder

- All raster images go to **Codex** (codex-delegate). agy can *read* screenshots placed in the workspace, which is useful for visual fix sheets.
- Measured small-task cost: agy has ~10–13k tokens of overhead per call, so batch related work into one run.
- agy's strengths in this team:
  - `search_web` research
  - docs
  - cheap tests and boilerplate
  - Claude-Sonnet-style review
  - a cross-vendor second opinion via gpt-oss
  - Orchestrator for end-to-end features
