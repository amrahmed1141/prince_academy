# Payments

Status: filled

## Domain overview

Payment methods, proof upload, admin verify/reject, pending lists, and finance reads. No `lib/features/payments` — member under booking/profile; admin under admin repos.

**Load when:** Instapay/cash/screenshots, pending payments, verify/reject, finance revenue views, `payments` / storage SQL.

## Important classes

- `PendingPaymentModel`, payment verification models — `lib/features/admin/data/models/`
- `PaymentMethod` (`cash` / `instapay`) — booking models
- Helpers: `payment_screenshot_helper.dart`, `payment_reference_helper.dart` — `lib/core/helpers/`
- UI: payment sheets (booking), `payments_page` (profile), `pending_payments_page`, `payment_verification_page`, `finance_page`

## Important repositories

- `AdminRepository` — pending stream (`StreamRepository`), `verify_payment` / `reject_payment`
- `FinanceRepository` — finance_* views (live list)
- `AdminDashboardRepository` — pending preview on dashboard
- Member create path: `BookingRemoteDs` / `BookingRepository` (method + screenshot only)

## Important Cubits / BLoCs

- `AdminBloc` — `VerifyPayment`, `RejectPayment`
- `FinanceCubit` — lives in `finance_bloc.dart`
- Member list often via `BookingHistoryBloc` on profile payments page

## Business rules

- Verify/reject only via SECURITY DEFINER RPCs — never client-only `isAdmin`.
- Accept legacy `payment_status='pending'` as well as `pending_payment` / `awaiting_verification`.
- After verify/reject, invalidate admin pending stream **and** `CoachRepository` scan-profile / members caches so User Tracking pending cards disappear immediately.
- Unconfirmed **cash** bookings auto-delete after `payment_deadline` (create sets +3 days) via `auto_delete_expired_cash_bookings` (pg_cron daily + opportunistic dashboard refresh). Audit rows land in `cash_booking_expiry_log`.
- Payments owns monetary transaction state; Subscriptions owns entitlement/window.
- Keep pending/finance cache-first (`StreamRepository`).
- `payment-screenshots` public URLs are intentional but sensitive.
- Reuse existing payment/pending models — no parallel shapes.

## Common mistakes

- Gating verify/reject only on a client admin flag.
- Mixing renew/pricing logic into payment verification UI.
- Copying legacy `Supabase.instance` from admin payment/scan paths.
- Widening storage policies without a security review.

## Related documentation

- [`docs/supabase-schema-and-rpc.md`](../../docs/supabase-schema-and-rpc.md), [`docs/security-notes.md`](../../docs/security-notes.md)
- SQL: `booking_flow.sql`, `admin_scan_profile.sql`, `payment_screenshots_storage.sql`
- Companions: [`booking.md`](booking.md), [`subscriptions.md`](subscriptions.md), [`supabase.md`](supabase.md)
- Rule: `.cursor/rules/product/admin-operations.mdc`
