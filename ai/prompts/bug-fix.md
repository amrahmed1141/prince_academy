# Bug Fix

**Status:** active  
**Pack:** [`../templates/bug-fix.md`](../templates/bug-fix.md)  
**Workflow:** [`../workflows/bug-fix.md`](../workflows/bug-fix.md)

## Intent

Identify root cause, apply the smallest safe fix, and prove the reproduction no longer fails.

## Required context packs

- Domain pack for the affected area
- Data platform pack if persistence, cache, or policies are implicated
- Known pitfalls / memory notes when available

## Required inputs

- Expected vs actual
- Reproduction steps or equivalent signal (log, screenshot, failing test)
- Environment notes when relevant
- Optional suspect layer (UI / domain / data / cache / SQL)

## Output schema

Produce a **Bug fix report**:

- Summary
- Repro
- Root cause (concrete location)
- Fix summary
- Regression evidence
- Deferred follow-ups
- Residual risk

## Constraints

- Minimal diff; owning layer only.
- Do not expand into features or cleanups.
- Call out any public contract change explicitly.
- See pack for gates and Hot Fix abbreviation rules.

## Stop / escalate

- Stop if unreproducible without a reliable signal.
- Escalate privileged SQL / auth boundary issues to Database or Security.
- Escalate pattern-level changes to Architect.
