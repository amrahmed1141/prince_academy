# Supabase

Status: filled

## Domain overview

Schema intent, RLS, RPCs, realtime, storage, and client security for Postgres/Supabase.

**Load when:** tables/views/indexes/triggers, RPC/`SECURITY DEFINER`, RLS, realtime, Storage, aligning `supabase/*.sql` with Dart calls.

## Important classes

- `SupabaseConfig` / client init — `lib/core/config/supabase_config.dart`
- Bootstrap: Hive → `Supabase.initialize` → `setupDI` — `lib/app/bootstrap.dart`
- SQL lives under `supabase/` (ad-hoc scripts, not formal CLI migrations)

## Important repositories

All remote access goes through feature repos/datasources (examples):

- Auth: `AuthRemoteDs` · Booking: `BookingRemoteDs` / `BookingRepository`
- Sessions: `SessionsRepository` · Notifications: `NotificationRepository`
- Admin: `AdminRepository`, `CoachRepository`, `FinanceRepository`

## Important Cubits / BLoCs

None own SQL directly. BLoCs/Cubits call repositories that call `.from` / `.rpc` / Storage / realtime.

## Business rules

- `supabase/*.sql` is checked-in schema intent; apply carefully per environment.
- Multi-step and privileged writes use RPCs; call `.rpc` only from repos/datasources.
- Authz = RLS + server helpers (`is_admin()`, triggers) — not client role alone.
- Client uses anon/publishable key only — never `service_role`.
- Realtime/Storage wiring stays in repositories/services.
- Flutter RPC missing from SQL = schema drift — fix both together.

## Common mistakes

- Trusting signup metadata for role; skipping `SECURITY DEFINER` for privileged writes.
- Assuming every environment has every ad-hoc script applied.
- Widening `payment-screenshots` policies casually (public URLs are sensitive).
- Putting PostgREST calls in pages.

## Related documentation

- [`docs/supabase-schema-and-rpc.md`](../../docs/supabase-schema-and-rpc.md), [`docs/security-notes.md`](../../docs/security-notes.md)
- [`examples/rpc/`](../../examples/rpc/), [`examples/supabase_repository/`](../../examples/supabase_repository/)
- Companion: domain pack for the owning feature; [`architecture.md`](architecture.md) for boundaries
- Rules: `.cursor/rules/data/supabase-sql.mdc`, `data/secrets-config.mdc`

### Quick RPC map

Booking create/cancel/reschedule/renew (`get_renewable_bookings`, `dismiss_booking_renew_prompt`, `renew_expired_booking`) · Payments `verify_payment`/`reject_payment` · Attendance `re_attend_session`/`unmark_session` · Subscriptions `renew_booking_subscription` · Auth `handle_new_user` / `is_admin`
