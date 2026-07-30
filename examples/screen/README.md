# Screen

Approved page composition: GetIt factory BLoC/Cubit via `BlocProvider`, state branching in the view, no remote I/O.

## Why

Pages own providers and UI transitions only. Data loading happens in the BLoC/Cubit → repository chain.

## Sources (truth)

| Role | Path |
|------|------|
| Sessions list page | [`lib/features/sessions/presentation/pages/sessions_page.dart`](../../lib/features/sessions/presentation/pages/sessions_page.dart) |
| Booking wizard page | [`lib/features/booking/presentation/pages/booking_page.dart`](../../lib/features/booking/presentation/pages/booking_page.dart) |
| DI factories | [`lib/core/di/injection.dart`](../../lib/core/di/injection.dart) |

## Agents

Flutter Developer · Reviewer · Architect

## Excerpt

See [`excerpt.md`](excerpt.md).

## Anti-patterns

- `Supabase.instance` (or any remote call) inside the page
- Constructing repositories inline in `build`
- Skipping `AuthenticatedShell` for authenticated destinations (see [`navigation/`](../navigation/))
