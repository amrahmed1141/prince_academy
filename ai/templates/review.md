# Pack: Review

Extends [`_base.md`](_base.md).

**Status:** active  
**Prompt:** [`../prompts/code-review.md`](../prompts/code-review.md)  
**Lenses:** [`../prompts/architecture-review.md`](../prompts/architecture-review.md), [`../prompts/performance-review.md`](../prompts/performance-review.md)  
**Workflow:** embedded as a stage inside Feature / Bug Fix / SQL Change (no separate long workflow required)

## Intent

Produce a severity-tagged verdict on a diff against the project contract and the originating pack’s goals — not a rewrite of the solution.

## When to use / when not

**Use when** a diff exists and a merge or release decision needs an independent check.

**Do not use when** there is no concrete change set, or when the requester wants greenfield design (use Feature design stage / Architect instead).

### Lenses (same output schema)

| Lens | Focus |
|------|--------|
| Default (code) | Contract, layering, change discipline, obvious correctness |
| Architecture | Boundaries, module placement, dependency direction, lasting decisions |
| Performance | Caching, query cost, rebuild hotspots, unnecessary work |
| Security | Auth boundaries, secrets, privileged SQL, data exposure |

## Primary roles

| Role | Responsibility |
|------|----------------|
| Reviewer | Default lens; merge recommendation |
| Architect / Performance / Security | Optional lens owners |

## Required inputs

- Diff or change description with file list
- Originating pack (Feature / Bug Fix / SQL Change) and its report if available
- Risk flags (auth, payments, privileged SQL, cache) — optional but preferred

## Required context

- Project contract
- Originating pack output
- Domain context for touched areas
- Standards relevant to the lens

## Stages

1. **Frame** — goal of the change; originating pack DoD  
2. **Contract scan** — stack and boundary rules  
3. **Lens pass** — default and any requested specialty lenses  
4. **Findings** — severity-tagged list; no drive-by redesign  
5. **Verdict** — approve / request changes  

## Output schema

```text
## Review report
- Scope reviewed:
- Lens(es):
- Verdict: approve | request changes
- Findings:
  - Blocker: ...
  - Should-fix: ...
  - Nit: ...
- Follow-ups:
```

### Severity

| Level | Meaning |
|-------|---------|
| **Blocker** | Must fix before merge/release |
| **Should-fix** | Should fix in this change unless explicitly deferred |
| **Nit** | Optional; must not block Release alone |

## Constraints

- Review the diff that exists; do not expand scope into a redesign.
- Cite concrete locations (path + symbol or SQL object).
- Prefer project rules and sources over personal style preference.
- Security and data-exposure issues are Blockers by default.

## Gates

| Gate | Fail if |
|------|---------|
| Scope known | No diff or unclear change set |
| Verdict issued | Findings without approve / request-changes |
| Release binding | Any Blocker remains open |

## Stop / escalate

- Escalate to Security for suspected secret leakage or privilege flaws.
- Escalate to Architect when the diff implies an unapproved pattern.
- Stop and ask for a clearer diff if the change set cannot be determined.

## Definition of done

- [ ] Verdict recorded
- [ ] Every Blocker has an owner or is fixed
- [ ] Nits explicitly marked non-blocking

## Index updates

None for the review itself. File follow-ups in the originating pack’s tracker or docs if deferred work is durable.
