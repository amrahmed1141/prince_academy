# Decisions (ADRs)

Append-only Architecture Decision Records. One file per consequential choice. ADRs sit above ordinary docs in the precedence chain because they record **commitments**, not descriptions.

**Not here:** how the system currently looks ([`../architecture/`](../architecture/)); agent memory lessons ([`ai/memory/`](../../ai/memory/)) — link those to ADRs when a lesson hardens into a decision.

## Consumers

Anyone about to relitigate a settled constraint, reviewers rejecting a PR that violates a recorded decision (cite the ADR), and maintainers reconstructing intent months later.

## Rules

1. **One decision per file**, numbered and dated: `NNNN-short-title.md` (four digits, kebab-case).
2. **Immutable once Accepted.** To change course, write a new ADR that supersedes the old one; mark the old status `Superseded by NNNN`.
3. **Never delete** an ADR. Status may be `Proposed`, `Accepted`, `Deprecated`, or `Superseded`.
4. **Record only consequential choices** — ones that constrain future PRs or reject a credible alternative. Do not ADR trivial renames.
5. Use [`../_templates/adr.md`](../_templates/adr.md) for every new record.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| — | None filed yet | — |

When the first ADR lands, replace the empty row and keep this table sorted by number.

## Candidate backfill (from enforced contracts)

These are already non-negotiable in [`AGENTS.md`](../../AGENTS.md) but lack recorded reasoning. Prefer filing ADRs before inventing new constraints:

| Topic | Current enforcement |
|-------|---------------------|
| BLoC/Cubit over Provider / Riverpod / GetX | Stack + pubspec discipline |
| GetIt over injectable codegen | Manual registration in `injection.dart` |
| Hand-written models over Freezed | Model convention |
| Supabase RPCs for multi-step writes | Platform contract |
| Cache-first / stale-while-revalidate | Booking / sessions gold path |
| `AuthenticatedShell` as sole authenticated entry | Auth flow |
| No new router package | Imperative `Navigator` |
| No `service_role` in the Flutter client | Security notes |

## Related

- Coding decisions memory: [`ai/memory/coding-decisions.md`](../../ai/memory/coding-decisions.md)
- Change discipline: [`.cursor/rules/core/01-change-discipline.mdc`](../../.cursor/rules/core/01-change-discipline.mdc)

## When to add an ADR

- Choosing or rejecting a library / pattern that future PRs must obey
- Changing auth, RLS, or DEFINER posture in a lasting way
- Accepting a deliberate deviation from gold standards with long-term cost
