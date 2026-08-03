# Known Pitfalls

Status: filled

Append dated entries. Do not invent.

<!-- YYYY-MM-DD — note -->

## 2026-08-03 — FCM terminated tap lost before AuthenticatedShell binds

`FirebaseMessagingService.initialize()` runs in `main()` and consumes `getInitialMessage()` before auth mounts the shell. If `onNotificationOpened` is still null, the tap is dropped and the user lands on home instead of the target screen.

**Fix:** buffer the message as `_pendingOpenedMessage` and drain it when `onNotificationOpened` is assigned from `AuthenticatedShell`.

## 2026-07-29 — verify_payment silently no-op on legacy `payment_status='pending'`

Cash bookings created under an older path can have `payment_status='pending'` + `status='pending_payment'`, while newer create uses `payment_status='pending_payment'` + `status='pending'`.

If `verify_payment` only matches `('pending_payment','awaiting_verification')`, the RPC returns success without updating the row. Tracking UI still shows the pending card after "Confirm".

**Fix:** accept `'pending'` too and `RAISE` when `ROW_COUNT = 0`. Keep `pending_payments` view in sync. After verify, invalidate `CoachRepository` scan-profile + members caches (not only `AdminRepository` pending stream).

## 2026-07-29 — Admin dashboard realtime needs publication + pending refresh

Client subscriptions on `bookings` / `payments` / `coach_sessions` / `attendance` do nothing unless those tables are in `supabase_realtime`. Also `StreamRepository.refresh()` must queue a follow-up when a realtime tick arrives mid-fetch, otherwise updates are dropped until pull-to-refresh.
