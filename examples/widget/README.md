# Widget

Approved presentational widgets: data and callbacks in; no repositories, no Supabase.

## Why

Keeps UI leaves dumb and reusable. Parent page/BLoC owns state and side effects.

## Sources (truth)

| Role | Path |
|------|------|
| Static presentational | [`lib/features/booking/presentation/widgets/already_booked_button.dart`](../../lib/features/booking/presentation/widgets/already_booked_button.dart) |
| Callback-driven list | [`lib/features/sessions/presentation/widgets/coach_chip_list.dart`](../../lib/features/sessions/presentation/widgets/coach_chip_list.dart) |

## Agents

Flutter Developer · Reviewer · Architect

## Excerpt

See [`excerpt.md`](excerpt.md).

## Anti-patterns

- Injecting or resolving a repository inside a widget
- Calling `.rpc` / `.from` from `build`
- Business rules that belong in BLoC/repository (pricing, booking eligibility)
