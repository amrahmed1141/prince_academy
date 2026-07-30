# Subscriptions

Status: filled

## Domain overview

Subscription window on bookings, client pricing helpers, and admin renew. No `lib/features/subscriptions` — helpers in `lib/core/helpers/`, fields on booking models.

**Load when:** pricing formulas, subscription start/end display, renew flow, `renew_booking_subscription` / monthly pricing SQL.

## Important classes

- `SubscriptionPricing` — `lib/core/helpers/subscription_pricing.dart`
- `SubscriptionFormatters` — `lib/core/helpers/subscription_formatters.dart`
- `SessionScheduleHelper` (`subscriptionEndDate`) — `lib/core/helpers/session_schedule_helper.dart`
- Booking models: `subscriptionStart` / `subscriptionEnd` fields

## Important repositories

- Create/price path: `BookingRepository` / `BookingRemoteDs` (uses pricing helpers)
- Renew: `CoachRepository.renewSubscription` → RPC `renew_booking_subscription`

## Important Cubits / BLoCs

- `BookingBloc` — applies pricing at create
- Admin renew surfaces go through coach/admin blocs calling `CoachRepository` (no dedicated SubscriptionCubit)

## Business rules

- Subscriptions owns entitlement/window; Payments owns money movement.
- Price only via `SubscriptionPricing` (+ related helpers) — no widget-local formulas.
- Renew is privileged RPC; not a client-only date patch.
- After renew/booking window changes, refresh via `MemberDataSync` / existing streams.
- Keep field names aligned with Postgres subscription columns.

## Common mistakes

- Duplicating monthly price math in UI.
- Merging verify-payment logic into renew without the Payments pack/RPC.
- Inventing a subscriptions feature folder that forks booking models.
- Forgetting cache invalidation after renew.

## Related documentation

- [`docs/supabase-schema-and-rpc.md`](../../docs/supabase-schema-and-rpc.md)
- SQL: `supabase/booking_monthly_pricing.sql` (`monthly_subscription_price`, `renew_booking_subscription`, `booking_progress`)
- Companions: [`booking.md`](booking.md), [`payments.md`](payments.md), [`supabase.md`](supabase.md)
- Rule: `.cursor/rules/product/academy-domain.mdc`
