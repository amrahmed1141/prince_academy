# Database Change

Status: filled

## Goal

Change Postgres schema, RPCs, RLS, storage policies, or transactional write paths safely so that `supabase/*.sql` remains source of truth, privileges stay explicit, and the Flutter client calls data only through repositories — never with `service_role`.

## Preconditions

- Orchestrator Change Brief states data intent, affected tables/RPCs, app callers (features/repos), and rollback or forward-fix approach.
- Architect agrees the change belongs in SQL (especially multi-step writes → RPC) rather than ad-hoc multi-call logic in Dart.
- Supabase context pack loaded ([`ai/context/supabase.md`](../context/supabase.md)); domain pack loaded when business rules apply.
- Risk treated as **H** whenever RLS, `SECURITY DEFINER`, payments, auth-linked rows, or admin privilege paths change.
- Local or staging verification path available before production apply (prefer CLI/local workflows over blind remote applies).

## Steps

1. **Brief (Orchestrator)**  
   Pipeline `database-change`. Name tables, RPCs, policies, and Flutter repositories that must move in lockstep. Require Security in the gate board.

2. **App contract (Architect)**  
   Define which repository methods will call `.from` vs `.rpc`. Forbid multi-step writes in the client when an RPC is appropriate. Note cache keys / sync helpers that must invalidate after the change.

3. **Spec + SQL (Database)**  
   Author or extend a clearly named script under `supabase/`. Include:
   - tables/columns/indexes/constraints as needed  
   - RPC bodies for transactional or multi-row work  
   - RLS policies and grants  
   - justification comments for `SECURITY DEFINER`  
   Emit a Schema/RPC Spec (inputs, outputs, caller role, error behavior).

4. **Threat review (Security) — mandatory before merge**  
   Review privilege escalation, anon vs authenticated vs admin paths, DEFINER search_path/grants, and any leakage of privileged operations to the client. Block until accepted.

5. **Client wiring (Flutter Developer) — after Spec approval**  
   Update hand-written models and repository/datasource calls to match the Spec. Register new types in GetIt. Do not call Supabase from widgets. Preserve cache-first behavior and invalidate via existing sync helpers.

6. **Contract review (Reviewer)**  
   Confirm SQL and Dart contracts match; no secrets in client; DI and feature layout respected.

7. **Verify (QA)**  
   Exercise allow paths for intended roles. Where feasible, prove deny paths under RLS (wrong role / wrong row). Cover repository tests for new RPC argument/result mapping.

8. **Catalog & context (Documentation)**  
   Update [`docs/supabase-schema-and-rpc.md`](../../docs/supabase-schema-and-rpc.md) (or `docs/database/` equivalents), [`ai/context/supabase.md`](../context/supabase.md), and the domain pack when business rules changed. File an ADR if the change settles a lasting data rule.

9. **Ship gate (Release)**  
   Confirm SQL, app, and docs align; Security and QA gates green.

## Validation

- [ ] `supabase/*.sql` is updated and is the source of truth for the change.
- [ ] Schema/RPC Spec reviewed; Flutter calls match names, args, and error semantics.
- [ ] RLS impact documented; `SECURITY DEFINER` justified and reviewed.
- [ ] No `service_role` or secret keys in the Flutter client.
- [ ] Multi-step writes use RPCs, not chained client calls.
- [ ] Cache invalidation paths updated when member/admin lists depend on the data.
- [ ] QA evidence includes intended allow path and, when practical, RLS deny.
- [ ] Schema/RPC catalog and context packs updated.

## Exit Criteria

- Security has signed off; Reviewer has no contract blockers.
- App and SQL are mergeable together (no “SQL merged, app later” without an explicit transitional plan in the Brief).
- Documentation/catalog reflects the new surface.
- Release Go for the database + client pair (or coordinated release plan recorded).

## Related Agents

| Role | Agent |
|------|--------|
| Conductor | [`agents/orchestrator.md`](../../agents/orchestrator.md) |
| Caller contract | [`agents/architect.md`](../../agents/architect.md) |
| SQL owner | [`agents/database.md`](../../agents/database.md) |
| Threats | [`agents/security.md`](../../agents/security.md) |
| Client wiring | [`agents/flutter-developer.md`](../../agents/flutter-developer.md) |
| Contract review | [`agents/reviewer.md`](../../agents/reviewer.md) |
| Evidence | [`agents/qa.md`](../../agents/qa.md) |
| Catalog / context | [`agents/documentation.md`](../../agents/documentation.md) |
| Go / No-go | [`agents/release.md`](../../agents/release.md) |

## Related Documentation

- [`AGENTS.md`](../../AGENTS.md)
- [`ai/context/supabase.md`](../context/supabase.md)
- [`ai/prompts/sql.md`](../prompts/sql.md)
- [`docs/supabase-schema-and-rpc.md`](../../docs/supabase-schema-and-rpc.md)
- [`docs/database/`](../../docs/database/)
- [`docs/security-notes.md`](../../docs/security-notes.md)
- [`docs/auth-and-roles.md`](../../docs/auth-and-roles.md)
- [`ai/standards/supabase.md`](../standards/supabase.md), [`ai/standards/repository.md`](../standards/repository.md)
- [`examples/rpc/`](../../examples/rpc/), [`examples/supabase_repository/`](../../examples/supabase_repository/)
- [`.cursor/rules/data/supabase-sql.mdc`](../../.cursor/rules/data/supabase-sql.mdc), [`.cursor/rules/data/repository-boundary.mdc`](../../.cursor/rules/data/repository-boundary.mdc), [`.cursor/rules/data/secrets-config.mdc`](../../.cursor/rules/data/secrets-config.mdc)
- [`.cursor/rules/core/02-definition-of-done.mdc`](../../.cursor/rules/core/02-definition-of-done.mdc)
