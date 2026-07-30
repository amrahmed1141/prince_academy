# Refactoring

Status: filled

## Goal

Improve structure, clarity, or maintainability **without intentional product behavior change**. Align code with existing gold standards (auth boundaries; booking/sessions cache) while keeping external behavior identical.

## Preconditions

- Explicit human request to refactor (or an Orchestrator Brief that names refactoring as the goal). Opportunistic cleanup inside another pipeline is forbidden.
- **Behavior freeze** documented in the Change Brief: acceptance paths that must keep working unchanged.
- Target smell and non-goals listed (e.g. “extract datasource only”; “do not split AdminRepository”).
- Risk tier set; Architect has confirmed the work does not require a product feature or schema redesign (those use other playbooks).
- No plan to delete `lib/view/`, swap state-management stacks, add a router, or perform large god-repository extractions unless the Brief explicitly allows it.

## Steps

1. **Brief & freeze (Orchestrator)**  
   Pipeline `refactoring`. Record before/after intent, files in scope, and behavior freeze. Reject mixed “refactor + feature” Briefs; split them.

2. **Plan boundaries (Architect)**  
   Describe current vs target module placement, public APIs to preserve, and DI impact. Point at gold-standard features to copy. Emit ADR-lite only if the refactor settles a lasting structural rule.

3. **Execute in thin slices (Flutter Developer)**  
   Move or reshape code under `lib/features/<name>/` (or agreed `lib/core` shared pieces). Keep hand-written models and existing BLoC/Cubit patterns. Register anything relocated in `lib/core/di/injection.dart`. Preserve cache-first emit + revalidate and existing invalidation helpers.

4. **Database touch (Database) — rare**  
   Only if ownership of SQL/RPC calls moves with the refactor. No “cleanup” migrations unrelated to the structural goal.

5. **Performance check (Performance) — when touching lists, streams, Hive, or live admin queries**  
   Ensure the refactor did not drop caching, widen queries, or add rebuild churn.

6. **Contract review (Reviewer)**  
   Confirm behavior parity intent, platform contract, and that the diff stays inside the Brief’s file/scope budget.

7. **Parity verify (QA)**  
   Re-run frozen acceptance paths. Prefer characterizing tests before/after for risky extractions. Fail the pipeline on any intentional or accidental behavior drift unless the Brief was amended.

8. **Document (Documentation) — when public structure or documented architecture changed**  
   Update [`ai/context/architecture.md`](../context/architecture.md) and human architecture docs; do not invent new conventions.

9. **Ship gate (Release)**  
   Confirm the change is refactor-only and DoD items for boundaries/DI/tests hold.

## Validation

- [ ] Behavior freeze paths pass with no product-facing deltas.
- [ ] Diff matches Architect plan; no undeclared feature work.
- [ ] DI lifetimes still correct (repos/datasources lazy singleton; BLoCs/Cubits factory).
- [ ] Remote I/O still confined to data layer; shell entry unchanged.
- [ ] Cache/realtime semantics preserved on touched lists.
- [ ] Tests updated for moved types; no reliance on deleted public APIs without replacement.
- [ ] Docs/context updated only where structure truly changed.

## Exit Criteria

- Structural goal in the Brief is achieved.
- QA reports parity on frozen paths.
- Reviewer (and Performance when required) have no open blockers.
- Release labels the change as refactoring; any discovered product bug is filed separately (not silently fixed unless Brief amended).

## Related Agents

| Role | Agent |
|------|--------|
| Conductor | [`agents/orchestrator.md`](../../agents/orchestrator.md) |
| Structure plan | [`agents/architect.md`](../../agents/architect.md) |
| Execution | [`agents/flutter-developer.md`](../../agents/flutter-developer.md) |
| SQL ownership moves | [`agents/database.md`](../../agents/database.md) |
| Hot-path check | [`agents/performance.md`](../../agents/performance.md) |
| Contract / scope | [`agents/reviewer.md`](../../agents/reviewer.md) |
| Parity evidence | [`agents/qa.md`](../../agents/qa.md) |
| Architecture truth | [`agents/documentation.md`](../../agents/documentation.md) |
| Go / No-go | [`agents/release.md`](../../agents/release.md) |

## Related Documentation

- [`AGENTS.md`](../../AGENTS.md)
- [`docs/architecture-overview.md`](../../docs/architecture-overview.md)
- [`docs/feature-playbook.md`](../../docs/feature-playbook.md)
- [`docs/caching-and-sync.md`](../../docs/caching-and-sync.md)
- [`ai/context/architecture.md`](../context/architecture.md)
- [`ai/prompts/architecture-review.md`](../prompts/architecture-review.md), [`ai/prompts/performance-review.md`](../prompts/performance-review.md)
- [`examples/`](../../examples/)
- [`docs/deprecation-list.md`](../../docs/deprecation-list.md) — do not delete listed surfaces without an explicit ask
- [`.cursor/rules/core/01-change-discipline.mdc`](../../.cursor/rules/core/01-change-discipline.mdc)
- [`.cursor/rules/core/02-definition-of-done.mdc`](../../.cursor/rules/core/02-definition-of-done.mdc)
