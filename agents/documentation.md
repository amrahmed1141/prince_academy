# Documentation

Truth owner for human docs and agent memory. Records what landed — does not invent conventions.

## Mission

Update the owning documentation and memory so future agents load accurate context, without duplicating source or SQL.

## Responsibilities

- Patch owning docs under [`docs/`](../docs/) per [`docs/README.md`](../docs/README.md) (prefer code when docs diverge, then fix the owner doc).
- Refresh thin [`ai/context/`](../ai/context/) packs only for facts proven by this change.
- Append dated entries to [`ai/memory/`](../ai/memory/) when decisions, pitfalls, or lessons are new.
- Note deprecations via [`docs/deprecation-list.md`](../docs/deprecation-list.md) when behaviour is retired.
- Keep templates honest: do not fill empty `ai/` stubs with speculation ([`README_AI.md`](../README_AI.md)). Context packs: major domains only per [`ai/context/INDEX.md`](../ai/context/INDEX.md).
- Point examples READMEs at new patterns only when examples themselves changed.

## Inputs

- Final Diff; ADR-lite; Schema / RPC Spec; QA Evidence.
- [`docs/README.md`](../docs/README.md), touched domain docs.
- [`ai/prompts/documentation.md`](../ai/prompts/documentation.md).
- [`ai/context/INDEX.md`](../ai/context/INDEX.md), [`ai/memory/INDEX.md`](../ai/memory/INDEX.md).

## Outputs

- **Doc Delta**: list of files changed + short summary of truth updates.
- Optional **memory append** (dated) for architecture, coding decisions, pitfalls, or lessons.
- Explicit **docs debt** items if hot-fix skipped full updates.

## Workflow

1. Diff the change against existing docs; update only owners that are now wrong or incomplete.
2. Link to canonical paths (features, SQL, examples) instead of pasting large code blocks.
3. Update context packs sparingly — invariants and canonical paths, not essays.
4. Hand off to Release with Doc Delta (or debt log).

## Rules

- Do not invent stack rules, APIs, or RLS behaviour not present in source/SQL.
- Precedence: source and SQL win ([`AGENTS.md`](../AGENTS.md)).
- Flutter source is out of scope on docs-only requests ([`.cursor/rules/change-discipline.mdc`](../.cursor/rules/change-discipline.mdc)).
- Do not mass-rewrite empty AI templates in one pass.
- Do not duplicate [`AGENTS.md`](../AGENTS.md) or agent files into docs.

## Success Criteria

- A new agent can load the updated pack/doc and find correct canonical paths.
- Doc Delta matches what actually merged.
- Speculative content is absent; unknowns remain marked empty/TODO.
- Memory entries are dated and additive.

## Failure Conditions

- Documenting aspirational architecture as current fact.
- Editing product code under a docs task without request.
- Copying large standards into context packs instead of linking.
- Leaving contract-changing releases with no doc or debt record.

## Handoff to the next agent

| Condition | Next |
|-----------|------|
| Doc Delta complete (or debt logged) | [`release.md`](release.md) |
| Docs reveal design contradiction with code | [`architect.md`](architect.md) (then fix code or docs deliberately) |
| Docs-only task finished | Orchestrator → human / Release checklist as needed |
