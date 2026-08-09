# Notification chat log

Auto-saved conversation about Android / FCM notifications for Prince Academy.
Hooks append new turns to this file and to `notification.jsonl` whenever the chat grows.

---

## 2026-08-03 — Audit + implement Android notifications

### User
Audit the complete Android notification stack (Flutter + native + Supabase FCM token storage), then implement only missing next steps:

1. FCM token registration & refresh on Android  
2. Token saved to Supabase (and on refresh)  
3. Foreground / background / terminated handling  
4. Notification channels (Android 8+)  
5. High-priority / data messages if required  
6. Click-through navigation  
7. POST_NOTIFICATIONS (Android 13+)  
8. ProGuard / manifest / gradle gaps  

Authority: AGENTS.md, agents/, cursor rules (incl. fcm-notifications), ai/context/notifications.md, existing FCM code, Supabase MCP.

### Assistant — Audit (already working)
- Firebase init + background handler in `main.dart`
- `google-services` + `google-services.json` (package match)
- `POST_NOTIFICATIONS` + `applicationName` fix for background FlutterEngine
- Token get/refresh → `profiles.fcm_token` via `NotificationRepository`
- Clear token + dispose realtime on sign-out
- `AuthenticatedShell` FCM + `NotificationBloc` wiring
- Foreground SnackBar on Android
- Live Supabase: `profiles.fcm_token`, `notifications` table + RLS + realtime (1/18 profiles already had a token)
- **No SQL/RPC changes needed** (no separate `fcm_tokens` table by design)

### Assistant — Gaps fixed
1. **Android channel** `prince_academy_high` (IMPORTANCE_HIGH) in `MainActivity` + manifest `default_notification_channel_id`
2. **Tray icon/color** — `ic_stat_notification` + brand color meta-data
3. **Terminated tap race** — buffer `getInitialMessage` until shell binds `onNotificationOpened`
4. **Click-through** — route by `data.type` / `data.route` (`booking`, `payment`, `session`/`attendance`, `admin`, else feed)
5. **VIBRATE** + ProGuard keep rules wired for future minify

### Key files touched
- `lib/core/services/firebase_messaging_service.dart`
- `lib/app/app.dart`
- `android/app/src/main/kotlin/.../MainActivity.kt`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/drawable/ic_stat_notification.xml`
- `android/app/proguard-rules.pro`
- `android/app/build.gradle`
- `ai/context/notifications.md`
- `ai/memory/known-pitfalls.md`

### Manual device checks
1. Sign in → confirm `profiles.fcm_token` updates  
2. Send FCM with notification payload + `data.type` in foreground / background / killed  
3. Tap → correct screen; killed-state tap should navigate after login  

---

## Live turns (auto-appended)

### 2026-08-04 — user

there is no notification banner or even snackbar

---

### 2026-08-04 — assistant

Bug: local notifications init used mipmap `launcher_icon` (must be drawable), which crashed FCM setup so foreground listeners never attached. Fixed: drawable small icon + `notification_logo` large icon, fail-safe init, SnackBar fallback, restored FCM default icon to `ic_stat_notification`.

---

### 2026-08-03 — user

save this chat in files called notification and every time chat increase save it automatic

---

### 2026-08-03 — assistant

Saved this chat under `ai/chats/notification.md` + `notification.jsonl`, and wired Cursor hooks so every new user prompt / agent reply auto-appends.

---
### 2026-08-04 — user

Freeze request: in-app notification appears for admin (bell badge) but no system notification banner.

### 2026-08-04 — assistant

Root cause: all admin profiles had empty `fcm_token`, so DB insert + realtime worked but FCM send was skipped. Also, while the app is open Android will not show a remote FCM tray banner without a local notification.

Fix: show Android local heads-up banner when realtime delivers a new `notifications` row (AuthenticatedShell listener + `FirebaseMessagingService.showLocalBanner`). Retry FCM token sync after login. Freeze tap routes to `AllFreezePage`. Background/killed banners still need `FIREBASE_SERVICE_ACCOUNT_JSON` on the `send-push` Edge Function + a saved admin `fcm_token`.

