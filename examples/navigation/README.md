# Navigation

Link-only: authenticated UI enters through `AuthenticatedShell`; imperative `Navigator` + `MaterialPageRoute` only.

## Why

No router package. Shell wires notifications/FCM for member and admin. See [`.cursor/rules/flutter/navigation-shell.mdc`](../../.cursor/rules/flutter/navigation-shell.mdc) and [`docs/auth-and-roles.md`](../../docs/auth-and-roles.md).

## Sources (truth)

| Role | Path |
|------|------|
| Shell / role gate | [`lib/app/app.dart`](../../lib/app/app.dart) (`AuthenticatedShell`) |
| Example push from sessions | `Navigator.push` → `UserSessionDetailPage` in sessions feature |
| Rule | [`.cursor/rules/flutter/navigation-shell.mdc`](../../.cursor/rules/flutter/navigation-shell.mdc) |

## Agents

Flutter Developer · Security · Reviewer · Architect

## Pattern (from project rules / existing usage)

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const BookingDetailsPage()),
);
```

Post-login destinations must remain under `AuthenticatedShell` (`role == 'admin'` → admin, else member).

## Anti-patterns

- go_router / auto_route / any new router package
- Routing to admin/member home while skipping the shell
- New post-login path that bypasses notification/FCM setup
