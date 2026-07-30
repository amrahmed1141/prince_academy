# Emergency Hot Fix

Status: filled

## Goal

Restore production (or block ongoing user harm) with the smallest safe patch under time pressure. Ceremony compresses; safety on auth, RLS, payments, and secrets does not.

## Preconditions

- Confirmed or strongly evidenced production incident (outage, data-incorrect at scale, auth/payment failure, security exposure).
- Orchestrator triage Brief exists: impact, workaround (if any), suspected owner file/layer, risk tier, and **scope freeze** (fix only).
- On-call or human owner available to approve ship shortcuts and follow-ups.
- Prefer this playbook over [Bug Fix](bug-fix.md) only while urgency is active; convert leftovers to bug-fix/refactor after mitigation.
- If the change is schema-heavy and non-urgent, do not use this playbook — use [Database Change](database-change.md).

## Steps

1. **Triage (Orchestrator)**  
   Pipeline `hot-fix`. Capture impact, blast radius, and rollback idea. Name the owning agent (Flutter and/or Database). Log Architect skip when the failing file is already known. **Reject** feature work, renames, and cleanups in the same change.

2. **Patch (Flutter Developer and/or Database)**  
   - App: minimal diff in the owning feature; keep DI/boundaries intact; do not “simplify” cache.  
   - SQL: smallest script fix under `supabase/`; note RLS / `SECURITY DEFINER` if touched.  
   Prefer forward fix over risky revert unless revert is clearly safer and already understood.

3. **Fast security (Security)**  
   **Mandatory** when auth, roles, RLS, payments, admin privilege, or secrets are involved. Otherwise log an explicit skip. Any privilege widening → hard stop.

4. **Smoke (QA)**  
   Repro the incident path; confirm mitigated. Run one adjacent critical path (e.g. auth shell still opens; booking list still loads if that subsystem was touched). Full regression can wait for aftermath.

5. **Ship (Release)**  
   Issue **Hotfix Go** with residual risk and mandatory follow-ups. Coordinate with human release owner for build/tag/store emergency channel.

6. **Aftermath (Documentation + Orchestrator) — within agreed window (default: same business day or next)**  
   - Append pitfall/lesson to [`ai/memory/known-pitfalls.md`](../memory/known-pitfalls.md) or project-history.  
   - Open a proper [Bug Fix](bug-fix.md) or [Refactoring](refactoring.md) if the patch is brittle.  
   - Update context packs if documented behavior was wrong.  
   - Close the incident Brief with timeline and owners.

## Validation

- [ ] Incident symptom mitigated on the failing production path (or staged proof equivalent when prod probe is unsafe).
- [ ] Diff contains only the hot fix (no refactors/features).
- [ ] Security sign-off or logged skip consistent with risk rules above.
- [ ] Smoke evidence attached (repro + one adjacent path).
- [ ] If SQL touched: `supabase/*.sql` updated; privilege impact stated.
- [ ] No secrets / `service_role` introduced in the client.
- [ ] Follow-ups filed with owners and dates before the incident is closed.

## Exit Criteria

- Production impact stopped or acceptably mitigated.
- Hotfix Go recorded with residual risk.
- Aftermath tasks created (memory entry + optional follow-up playbook).
- Scope freeze held for the entire emergency change.

## Related Agents

| Role | Agent |
|------|--------|
| Triage / scope freeze | [`agents/orchestrator.md`](../../agents/orchestrator.md) |
| App patch | [`agents/flutter-developer.md`](../../agents/flutter-developer.md) |
| SQL patch | [`agents/database.md`](../../agents/database.md) |
| Fast threat check | [`agents/security.md`](../../agents/security.md) |
| Smoke | [`agents/qa.md`](../../agents/qa.md) |
| Hotfix Go | [`agents/release.md`](../../agents/release.md) |
| Aftermath truth | [`agents/documentation.md`](../../agents/documentation.md) |
| Optional locate | [`agents/architect.md`](../../agents/architect.md) (skip OK if logged) |
| Optional contract pass | [`agents/reviewer.md`](../../agents/reviewer.md) (prefer before ship when time allows) |

## Related Documentation

- [`AGENTS.md`](../../AGENTS.md)
- Sibling playbooks: [`bug-fix.md`](bug-fix.md), [`database-change.md`](database-change.md), [`release.md`](release.md)
- [`ai/prompts/bug-fix.md`](../prompts/bug-fix.md)
- [`ai/memory/known-pitfalls.md`](../memory/known-pitfalls.md), [`ai/memory/lessons-learned.md`](../memory/lessons-learned.md)
- [`docs/security-notes.md`](../../docs/security-notes.md)
- [`docs/environment-setup.md`](../../docs/environment-setup.md)
- [`docs/operations/`](../../docs/operations/)
- Domain pack via [`ai/context/INDEX.md`](../context/INDEX.md) — load minimum needed for the failing domain
- [`.cursor/rules/core/01-change-discipline.mdc`](../../.cursor/rules/core/01-change-discipline.mdc)
- [`.cursor/rules/core/02-definition-of-done.mdc`](../../.cursor/rules/core/02-definition-of-done.mdc) — apply fully in aftermath if compressed at ship time
