# Cubit

Approved presentation-state shape for simple load/refresh flows.

## Why

Encodes: constructor-injected repository, Equatable state, error as `String?` on state, GetIt **factory** registration. Use Cubit for simple UI state; prefer BLoC when the flow is event-driven (auth, booking wizard, sessions).

## Sources (truth)

| Role | Path |
|------|------|
| Cubit + state | [`lib/features/admin/presentation/bloc/admin_dashboard_cubit.dart`](../../lib/features/admin/presentation/bloc/admin_dashboard_cubit.dart) |
| DI factory | [`lib/core/di/injection.dart`](../../lib/core/di/injection.dart) (`AdminDashboardCubit`) |
| Also valid | `MembersListCubit`, `FinanceCubit`, `SearchCubit` |

## Agents

Flutter Developer (implement) · Reviewer (shape) · Architect (cite)

## Excerpt

See [`excerpt.md`](excerpt.md).

## Anti-patterns

- Calling Supabase from the Cubit
- Registering a Cubit as a singleton
- Mutable state without `Equatable`
