# Architecture

How the Flutter application is put together: layers, feature layout, DI, state management, caching, navigation, and the gold-standard features to copy.

**Not here:** why BLoC was chosen over Riverpod (that is an [ADR](../decisions/)); step-by-step “how to add a feature” for agents ([`ai/workflows/feature-development.md`](../../ai/workflows/feature-development.md)); product behaviour ([`../product/`](../product/)).

## Consumers

Flutter developers onboarding or placing new code, reviewers checking layer boundaries, and agents that need structural context beyond [`AGENTS.md`](../../AGENTS.md).

## Index

| Document | Question it answers | Status |
|----------|---------------------|--------|
| [Overview (root)](../architecture-overview.md) | What is the runtime shape, layer map, and feature map? | Current — migrate to `overview.md` |
| [Caching & sync (root)](../caching-and-sync.md) | How do Hive, TTL, and stale-while-revalidate work? | Current — migrate to `caching-and-sync.md` |
| [Feature playbook (root)](../feature-playbook.md) | How should a new feature be laid out? | Current — migrate or fold into AI workflow |
| [UI theme (root)](../ui-theme-guide.md) | Where do theme and shared UI live? | Current — migrate to `ui-theme.md` |

## Invariants (must stay true)

- Stack: Flutter · BLoC/Cubit · GetIt · Supabase · Hive · Firebase Messaging.
- Remote I/O only in repositories / datasources — never widgets or pages.
- Repositories / datasources: lazy singletons; BLoCs / Cubits: factories — registered in `lib/core/di/injection.dart`.
- Authenticated member/admin UI enters only through `AuthenticatedShell`.
- Hand-written models (`fromJson` / `fromMap`); no Freezed, Dio, Provider, Riverpod, GetX, injectable, or a new router.
- Gold standards: `lib/features/auth` (boundaries), `lib/features/booking` + `lib/features/sessions` (cache + realtime).

## Typical feature layout

```
lib/features/<name>/
  data/models | datasources | repositories
  domain/                     # optional — strong only on auth today
  presentation/bloc | pages | widgets
```

## Related

- Agent context: [`ai/context/architecture.md`](../../ai/context/architecture.md)
- Standards (when filled): [`ai/standards/`](../../ai/standards/)
- Examples: [`examples/`](../../examples/)
- Platform contract: [`.cursor/rules/core/00-platform-contract.mdc`](../../.cursor/rules/core/00-platform-contract.mdc)

## When to update this folder

- New cross-cutting layer or DI lifetime change
- New gold-standard feature designated
- Cache / realtime strategy change
- Navigation shell contract change
