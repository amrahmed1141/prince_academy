# Release

**Status:** active  
**Pack:** [`../templates/release.md`](../templates/release.md)  
**Prompt:** [`../prompts/release.md`](../prompts/release.md)

## When to use

A change set claims readiness to ship after implementation and review.  
Do not use mid-implementation or for design-only questions.

## Roles

Release (decision owner) ← QA evidence, Reviewer verdicts, Documentation sanity, Database confirmation when SQL is required

## Stages

1. **Assemble** — originating pack report(s), review report(s), evidence  
2. **Checklist** — execute originating DoD item by item  
3. **Dependencies** — SQL/config/flags required at runtime  
4. **Docs sanity** — critical published truth not contradicting the ship  
5. **Decide** — write `go` or `no-go` with date and rationale  
6. **Hand off** — name owners for residual risks and follow-ups  

## Context packs / prompts per stage

| Stage | Prompt / pack | Context |
|-------|---------------|---------|
| Assemble–Decide | `release` | originating reports, review findings |
| Docs sanity | `documentation` (read-only check) | affected docs |

## Required artifacts

- Release report with explicit decision
- Links to Feature / Bug Fix / SQL Change reports
- Links to Review reports

## Gates

- Evidence and review verdicts present
- No open Blockers
- Required dependencies applied
- Decision is explicit (`go` or `no-go`)

## Definition of done

See Release pack DoD. A verbal “looks good” is not sufficient.
