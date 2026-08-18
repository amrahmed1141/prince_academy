# Booking

Status: filled

## Domain overview

Reservation lifecycle: create, cancel, reschedule, history, and booking cache/realtime (gold standard with sessions).

**Load when:** booking mutations, history/detail streams, payment method at booking time, `MemberDataSync`, booking RPCs.

## Important classes

- `BookingModel`, `BookingHistoryModel`, `PaymentMethod` — `lib/features/booking/data/models/`
- `BookingRemoteDs` — `lib/features/booking/data/datasources/booking_remote_ds.dart`
- `MemberDataSync` — `lib/core/services/member_data_sync.dart`
- UI: `booking_page` / `booking_screen`, `booking_detail_page`, `booking_history_page`

## Important repositories

- `BookingRepository` — `lib/features/booking/data/repositories/booking_repository.dart`
- Pair for cache/realtime: `SessionsRepository` — `lib/features/sessions/data/repositories/sessions_repository.dart`

## Important Cubits / BLoCs

- `BookingBloc` — create flow
- `BookingDetailBloc` — detail / member actions
- `BookingHistoryBloc` — history stream (Hive + realtime)
- `BookingRenewCubit` — expired/finished renew prompt + 2-step renew flow

## Business rules

- Remote I/O only in DS/repo — not pages.
- Multi-step create/mutations via RPCs: `create_booking_with_schedule`, `cancel_booking`, `update_booking_days`, `reschedule_booking`, `get_renewable_bookings`, `dismiss_booking_renew_prompt`, `renew_expired_booking`.
- Member renew: expired (`subscription_end < today`) or finished (attended ≥ monthly total). Same days/time/price; new start date + payment method. Prompt shows on member shell open (`BookingRenewCubit.load`). Cancel is **session-only** (no permanent `renew_prompt_dismissed_at`); next cold start shows the card again until a live booking exists. SQL: `supabase/booking_renew.sql`.
- After cancel of renew prompt, member may book the same coach manually (home / coach / Book Now) or tap **Renew** on an Expired history card. Duplicate checks must treat date-expired rows as inactive even if `status` is still `active`.
- Booking history: Expired cards show **Renew** beside Details → same `BookingRenewCubit` / `BookingRenewPage` flow (`BookingRenewNavigation.openForBooking`).
- Session freeze RPCs: `request_booking_freeze`, `apply_booking_freeze`, `review_booking_freeze` (+N days to `subscription_end`). SQL: `supabase/session_freeze.sql`.
- Preserve cache-first history (`bookings_$userId` Hive + stream).
- After mutations call `MemberDataSync` (bookings + sessions).
- Reuse booking models — no parallel shapes.
- Payment verify/reject is Payments domain; booking only collects method/proof.
- Unconfirmed cash bookings older than `payment_deadline` (+3 days at create) are hard-deleted by `auto_delete_expired_cash_bookings` so the member can book again with no residual pending state.

## Common mistakes

- Business rules in widgets instead of repo/RPC.
- Forgetting `MemberDataSync` → stale sessions/home.
- Stripping booking Hive/realtime caching.
- Treating admin verify as part of member booking bloc.

## Related documentation

- [`docs/caching-and-sync.md`](../../docs/caching-and-sync.md), [`docs/supabase-schema-and-rpc.md`](../../docs/supabase-schema-and-rpc.md), [`docs/feature-playbook.md`](../../docs/feature-playbook.md)
- SQL: `supabase/booking_flow.sql`, `user_booking_actions.sql`, `booking_renew.sql`
- Companions: [`payments.md`](payments.md), [`subscriptions.md`](subscriptions.md), [`attendance.md`](attendance.md)
- Rule: `.cursor/rules/product/academy-domain.mdc`
