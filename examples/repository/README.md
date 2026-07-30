# Repository (domain boundary)

Approved auth-style boundary: interface in `domain/` → impl in `data/` → remote datasource.

## Why

Keeps `supabase.auth` and profile I/O out of UI. Gold standard for layering when a feature needs a stable contract (auth). Most other features use a concrete `*Repository` without a domain interface — that is also approved; do not invent interfaces unless matching auth.

## Sources (truth)

| Role | Path |
|------|------|
| Interface | [`lib/features/auth/domain/repositories/auth_repo.dart`](../../lib/features/auth/domain/repositories/auth_repo.dart) |
| Impl | [`lib/features/auth/data/repositories/auth_repo_impl.dart`](../../lib/features/auth/data/repositories/auth_repo_impl.dart) |
| Remote DS | [`lib/features/auth/data/datasources/auth_remote_ds.dart`](../../lib/features/auth/data/datasources/auth_remote_ds.dart) |
| DI | [`lib/core/di/injection.dart`](../../lib/core/di/injection.dart) |

## Agents

Flutter Developer · Reviewer · Security (auth boundary) · Architect

## Excerpt

See [`excerpt.md`](excerpt.md).

## Anti-patterns

- `Supabase.instance.auth` in a page/widget
- Skipping the repository and calling the datasource from a Cubit/BLoC
