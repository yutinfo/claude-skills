# Codex models by team role

Condensed from the user's notes `codex-model-roles-th.md` (21 Nov 2026, Codex CLI 0.171.0). The model list depends on the account, so **preflight wins over this file**.

**Default: GPT-6.2 Sol is the main developer.** Add other models only when Sol hits a clear bottleneck:
- **Astra** when a decision crosses systems.
- **Terra** when the evidence is a screenshot or image.
- **Luna** for repeat work with examples and a clear pass rule.

## 1. Roles → model → evidence Claude must see before accepting

| Role | Start with | Hand it | Evidence before accepting |
|---|---|---|---|
| Tech Lead / Architect | `gpt-6.2-astra` · medium · `-s read-only` | impact across services, migration design, rollout choice | options, trade-offs, assumptions, rollback |
| Backend / Full-stack dev | `gpt-6.2-sol` · medium | features, API/data-flow changes to an agreed contract, tests | diff in scope, pass criteria met, real test output |
| Frontend dev | `gpt-6.2-sol` · medium | component + state/API/validation wiring | loading / empty / error states and the specified interactions checked |
| UI QA / Frontend triage | `gpt-6.1-terra` · low–medium · `-i shot.png` | compare a screenshot to the design, find misaligned layout or overflowing text | element, position in the image, viewport |
| QA / Test engineer | Sol medium (design cases) · `gpt-6-luna` **high** (fill cases from a table) | edge cases, fixtures, assertions | test fails before the fix and passes after, or the given table is fully covered |
| Code reviewer | Sol medium (normal PR) · Astra medium (complex or many callers) | regressions, inconsistent data, caller impact | file/line, trigger condition, checkable impact |
| DevOps / SRE | Sol medium (CI, config) · Astra medium (cross-service incident) | read logs with secrets removed, point to the failure, propose checks | hypothesis cites logs, plus verify command and rollback |
| Maintainer / repeat work | `gpt-6-luna` · high | reword from examples, add fixtures, sort test results | changed files checked, verify command runs |
| **Image maker (team rule)** | `gpt-6.2-sol` · medium (`image_generation`) | every raster image: photos, illustrations, raster icons/logos, AI resize/edit | Claude opens every image (contact sheet); size/bytes match the brief |

Effort:
- Medium is the starting point for multi-step work.
- Low suits short tasks with a clear scope.
- **Luna starts at High** (OpenAI's guidance; Luna-low is a false economy).
- Raise Astra to High only when weighing many options or tracing many evidence layers.
- Reasoning effort and Standard/Fast speed are set separately. Keep Standard to save quota.

## 2. Each model in the menu

| `-m` | Fits | Why choose it |
|---|---|---|
| `gpt-6.2-astra` | Architect, Tech Lead, Incident analyst | cause and effect across modules, compatibility, data-change plans |
| `gpt-6.2-sol` | Main dev, QA automation, Reviewer, Image maker | read, edit, test and check the diff in one round |
| `gpt-6.1-terra` | UI QA, Frontend triage, Technical writer | evidence is mainly visual; turns test notes into reproducible bug reports |
| `gpt-6-luna` | Fixture writer, Triage, Maintainer | small scope, before/after examples, a verify command |
| `gpt-6.1-sol`, `gpt-6-sol`, `gpt-6-astra`, `gpt-5.6-*` | only when a workflow is pinned to that version or you are comparing to its baseline | — |

Credit rates at Standard speed:
- Astra 6.2 costs **4×** Sol 6.2 per token.
- Terra 6.1 costs **0.5×** Sol 6.2 for both input and output, which makes it the cheapest choice for screenshot review.

Use Sol for normal work. Move up only if the bigger model really cuts time-to-green or fix rounds.

## 3. Splitting one ticket (example: pagination on order history)

1. **Astra plans** (only when the API has many callers): `-s read-only`. Trace endpoint → query → callers. Propose paging that keeps order on equal timestamps and keeps old clients working. Return assumptions, options, test criteria and rollback, with file refs, before any code.
2. **Sol implements** the agreed plan with `-s workspace-write`, effort medium. Test the last page, an invalid cursor and equal timestamps. Run targeted tests first, then the related suite, and report the diff and real results.
3. **Terra checks the screen** with `-s read-only -i orders-mobile.png`. Where is the next button, what overflows or overlaps, what is hard to read? Give the position and viewport. Real clicks still need browser/E2E evidence.
4. **Luna fills cases** (high) from an input→expected table. Follow the existing pattern and touch only the named test file. If reality contradicts the table, report the difference; don't "fix" it.
5. **Review in a fresh run** (`codex review` or a new exec). Sol for a normal PR, Astra when there are many legacy clients. Ask for findings only (file/line, condition, impact, confirming test), no edits.

A small single-repo ticket can be all Sol in one run. Add steps only for the ticket's risk.

## 4. Handoff without re-exploring

Send **goal + agreed decisions + files/commit + commands and test results + what's still open**, plus the checkout path if using a worktree.
- **Sol → Astra:** the cause still spans services after logs and basic tests. Send the hypotheses already ruled out, with evidence.
- **Terra → Sol:** you know which part of the screen is wrong. Send the image, viewport, repro steps and expected behaviour.
- **Luna → Sol:** the repeat work hit an exception. Send the failing case and the related contract, and let Sol decide whether the fixture or the implementation is wrong.

Run the first ticket mostly on Sol. Note whether the bottleneck was design, reading screens or repetition, and use that to choose the supporting roles next time.

## 5. Codex vs agy in this team

| Work | Send to |
|---|---|
| Any raster image, screenshot-based UI QA | **Codex** (image_generation; Terra for screenshots) |
| Main coding where reliability per token matters | **Codex Sol** (measured: small 2-file bugfix ≈12k tokens vs agy ≈29k) |
| Web research, docs, cheap boilerplate/tests, a Claude-Sonnet-style review, cross-vendor second opinion | **agy** (see agy-delegate `references/model-roles.md`) |
| Two independent parts of one feature | Run both in parallel with disjoint file ownership and a shared SPEC.md contract |
