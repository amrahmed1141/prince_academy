# Architecture

Status: filled

## Domain overview

Feature boundaries, DI, authenticated shells, BLoC/Cubit, and cache-first patterns.

**Load when:** new/moved features, GetIt/bootstrap, shells/navigation, list caching/realtime, multi-feature ownership.

## Important classes

- `AuthenticatedShell`, `PrinceAcademyApp` — `lib/app/app.dart`
- `setupDI` / `sl` — `lib/core/di/injection.dart`
- `StreamRepository<T>` — `lib/core/base/stream_repository.dart`
- `LocalCacheStore`, `TtlCache` — `lib/core/cache/`
- `MemberDataSync`, `MemberDataPrefetch` — `lib/core/services/`
- `NavigationBottom` — `lib/app/bottom_navigation/navigation_bottom.dart`
- `AdminHomeScreen` — `lib/features/admin/presentation/pages/admin_home.dart`

## Important repositories

- Gold boundaries: `lib/features/auth` (`AuthRepo` + DS)
- Gold cache/realtime: `BookingRepository`, `SessionsRepository`
- Live admin lists via `StreamRepository`: `AdminRepository`, `CoachRepository`, `FinanceRepository`

## Important Cubits / BLoCs

- Root: `AuthBloc` drives Splash | `AuthPage` | `AuthenticatedShell`
- Feature BLoCs/Cubits registered as **factories** in GetIt; repos as **lazy singletons**
- Prefer existing feature blocs; do not invent a global store

## Business rules

- Stack fixed: BLoC/Cubit + GetIt + Supabase + Hive + FCM — no Provider/Riverpod/GetX/Freezed/Dio/new router.
- Remote I/O only in repositories/datasources.
- Multi-step DB work uses Supabase RPCs.
- Authenticated UI enters only through `AuthenticatedShell`.
- Preserve cache-first / stale-while-revalidate for lists and dashboards.
- Hand-written models; never put `service_role` in the client.

## Common mistakes

- Calling `Supabase.instance` from widgets or skipping the shell.
- Constructing repos inline instead of GetIt.
- Stripping Hive/stream caching when “simplifying” lists.
- Growing `lib/view/` or large speculative admin-repo extractions.

## Related documentation

- [`docs/architecture-overview.md`](../../docs/architecture-overview.md), [`docs/feature-playbook.md`](../../docs/feature-playbook.md), [`docs/caching-and-sync.md`](../../docs/caching-and-sync.md)
- [`examples/`](../../examples/), [`AGENTS.md`](../../AGENTS.md)
- Companion: [`supabase.md`](supabase.md) when SQL/RPC involved
- Rules: `.cursor/rules/core/00-platform-contract.mdc`, `flutter/dependency-injection.mdc`, `flutter/navigation-shell.mdc`, `data/caching-sync.mdc`
