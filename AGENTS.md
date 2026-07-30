# AGENTS.md — Prince Academy

Short contract for AI agents. Details: [`ai/`](ai/), [`docs/`](docs/), [`README_AI.md`](README_AI.md).

## Project Mission

This repository is the **reference implementation** for all future Flutter SaaS gym products.

Priorities: maintainability, consistency, performance, reuse, offline-first behaviour, and AI-assisted development.

When in doubt, preserve architecture over short-term convenience.

## Stack

Flutter feature-first · BLoC/Cubit · GetIt · Supabase · Hive · Firebase Messaging

## Non-negotiables

1. Do not introduce Provider, Riverpod, GetX, injectable, Freezed, Dio, or a new router.
2. Remote I/O in repositories/datasources only — never widgets/pages.
3. Multi-step DB work uses Supabase RPCs.
4. Preserve cache-first / stale-while-revalidate for lists and dashboards.
5. Register repos as lazy singletons; BLoCs/Cubits as factories in `lib/core/di/injection.dart`.
6. Authenticated UI enters only through `AuthenticatedShell`.
7. Hand-written models (`fromJson` / `fromMap`).
8. `supabase/*.sql` is schema source of truth; note RLS / `SECURITY DEFINER`.
9. Never put `service_role` or secrets in the Flutter client.
10. No drive-by refactors or legacy deletions unless asked.

## Gold standards

- Boundaries: `lib/features/auth`
- Cache + realtime: `lib/features/booking`, `lib/features/sessions`

## Change Policy

How agents modify this project:

- Make the smallest possible change.
- Avoid touching unrelated files.
- Do not reformat unrelated code.
- Do not rename files unless required.
- Do not move code between architectural layers without approval.
- Preserve existing architecture and project patterns.

## How to work

1. Read this file.
2. Open [`README_AI.md`](README_AI.md) → pick agent role under [`agents/`](agents/), then workflow / context packs.
3. Prefer [`examples/`](examples/) and gold-standard features over new patterns.
4. Keep changes scoped.

## Precedence

Source > SQL > decisions/memory > docs/context packs > prompts/workflows > tool adapters (`.cursor/`) > indexes
