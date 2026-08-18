# Known Pitfalls

Status: filled

Append dated entries. Do not invent.

<!-- YYYY-MM-DD — note -->

## 2026-08-18 — Google signInWithIdToken needs the **Web** client ID

`google_sign_in` on Android still requires `serverClientId` = the **Web application** OAuth client ID (not the Android client). Missing SHA-1 on the Android OAuth client, or putting the Android client ID in `serverClientId`, yields "Missing ID token" / audience errors. Facebook login needs a real App ID + Client Token in `strings.xml` / `Info.plist` and the provider enabled in Supabase Auth.

## 2026-08-18 — Coach photos felt last/heavy on Home

`ResizeImage` only shrinks **decoded** pixels. `NetworkImage` still downloaded the full Storage original, after JSON cards had already painted. List avatars now request a 256px Storage render URL; if transforms are off (Free plan / disabled), `CoachAvatar` falls back to the original URL. Disk cache makes return visits skip the network.

## 2026-08-15 — Renew prompt missing on cold start after Cancel

Two causes: (1) `load()` could finish before `RenewPromptHost` listened; (2) Cancel used to set `renew_prompt_dismissed_at`, so `get_renewable_bookings` never returned the row again.

**Fix:** load renewals after the host mounts; Cancel is session-only; `get_renewable_bookings` no longer requires `renew_prompt_dismissed_at IS NULL`. History **Renew** + manual Book Now remain available after Cancel.

## 2026-08-15 — Expired booking still blocked "already active" on Book Now

UI shows **Expired** from `subscription_end`, but `bookings.status` often stays `active`. `getUserActiveCoachIds` / `hasActiveBookingWithCoach` used to filter only by status, so after dismissing the renew prompt the member could not re-book the same coach from home.

**Fix:** treat a booking as live only when `subscription_end` is null or `>= today` (same rule as `renew_expired_booking`). Book Now always re-checks the server instead of trusting stale `BookingBloc.bookedCoachIds`.

## 2026-08-13 — Admin dashboard SocketException was unhandled

`finance_daily_revenue` itself is a cheap view. `ClientException` / `SocketException` (errno 104/113) was bubbling out of `StreamRepository.refresh()` because TTL auto-refresh and realtime used `unawaited(refresh())`, which **rethrows** after `addError`. IndexedStack also mounted Finance on admin home, so dashboard + finance hit Supabase in parallel and one TCP reset killed the refresh. Fix: `refreshInBackground()`, map transport errors, lazy-mount unused admin tabs, keep cache (OfflineBanner) instead of dumping the URI into a SnackBar.

## 2026-08-03 — FCM terminated tap lost before AuthenticatedShell binds

`FirebaseMessagingService.initialize()` runs in `main()` and consumes `getInitialMessage()` before auth mounts the shell. If `onNotificationOpened` is still null, the tap is dropped and the user lands on home instead of the target screen.

**Fix:** buffer the message as `_pendingOpenedMessage` and drain it when `onNotificationOpened` is assigned from `AuthenticatedShell`.

## 2026-07-29 — verify_payment silently no-op on legacy `payment_status='pending'`

Cash bookings created under an older path can have `payment_status='pending'` + `status='pending_payment'`, while newer create uses `payment_status='pending_payment'` + `status='pending'`.

If `verify_payment` only matches `('pending_payment','awaiting_verification')`, the RPC returns success without updating the row. Tracking UI still shows the pending card after "Confirm".

**Fix:** accept `'pending'` too and `RAISE` when `ROW_COUNT = 0`. Keep `pending_payments` view in sync. After verify, invalidate `CoachRepository` scan-profile + members caches (not only `AdminRepository` pending stream).

## 2026-07-29 — Admin dashboard realtime needs publication + pending refresh

Client subscriptions on `bookings` / `payments` / `coach_sessions` / `attendance` do nothing unless those tables are in `supabase_realtime`. Also `StreamRepository.refresh()` must queue a follow-up when a realtime tick arrives mid-fetch, otherwise updates are dropped until pull-to-refresh.
