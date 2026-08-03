# Notifications

Status: filled

## Domain overview

FCM token lifecycle, in-app notification feed, and realtime delivery. Delivery mechanics live here; other domains own business trigger events.

**Load when:** FCM token save/clear, notifications UI/bell, `notifications` table / `profiles.fcm_token`, shell or sign-out wiring.

## Important classes

- `AppNotification` — `lib/features/notifications/data/models/app_notification.dart`
- `FirebaseMessagingService` — `lib/core/services/firebase_messaging_service.dart`
- UI: `notifications_page.dart`, `notification_bell_button.dart`
- Wiring: `AuthenticatedShell` in `lib/app/app.dart`; `lib/firebase_options.dart`
- Android channel: `prince_academy_high` created in `MainActivity`; manifest `default_notification_channel_id`

## Important repositories

- `NotificationRepository` — `lib/features/notifications/data/repositories/notification_repository.dart`
- Token persistence touches `profiles.fcm_token` (via messaging service / repo patterns)

## Important Cubits / BLoCs

- `NotificationBloc` — `lib/features/notifications/presentation/bloc/notification_bloc.dart`
- Started/wired from `AuthenticatedShell` (e.g. `NotificationsStarted`)

## Business rules

- Authenticated UI must enter via `AuthenticatedShell` so bloc + FCM stay active.
- Store token on `profiles.fcm_token`; refresh on login path; **clear on sign-out**.
- Dispose notification realtime on sign-out.
- All notification I/O in the repository — not widgets.
- Prefer `AppNotification`; no parallel notification models.
- Terminated notification taps are buffered until `onNotificationOpened` is bound (cold-start race).
- Tap routing uses `message.data['type']` / `['route']`: `booking` → booking history; `payment` → pending payments (admin) / booking history (member); `session`/`attendance` → today sessions (admin) / sessions (member); else notifications feed.

## Common mistakes

- Registering FCM outside the shell.
- Leaving stale token / leaked realtime after logout.
- Writing tokens from a widget.
- Putting notification business triggers’ content rules only here (origin domain owns the event).
- Handling `getInitialMessage` before the shell binds without buffering the pending open.

## Related documentation

- [`docs/auth-and-roles.md`](../../docs/auth-and-roles.md) (sign-out cleanup), [`docs/architecture-overview.md`](../../docs/architecture-overview.md)
- SQL: `supabase/notifications_fcm_token.sql`
- Companions: [`authentication.md`](authentication.md), [`architecture.md`](architecture.md)
- Rule: `.cursor/rules/product/fcm-notifications.mdc`
