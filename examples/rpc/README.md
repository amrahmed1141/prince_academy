# RPC

Approved multi-step write pattern: Postgres `SECURITY DEFINER` function + thin Flutter `.rpc` call with `PostgrestException` → user-safe mapping.

## Why

Client must not own multi-table transactions. Booking create/cancel and payment verify run in SQL; Flutter only passes params and maps the result.

## Sources (truth)

| Role | Path |
|------|------|
| SQL create | [`supabase/booking_flow.sql`](../../supabase/booking_flow.sql) (`create_booking_with_schedule`) |
| SQL cancel | [`supabase/user_booking_actions.sql`](../../supabase/user_booking_actions.sql) (`cancel_booking`) |
| Dart caller | [`lib/features/booking/data/datasources/booking_remote_ds.dart`](../../lib/features/booking/data/datasources/booking_remote_ds.dart) |
| Admin verify | [`lib/features/admin/data/repositories/admin_repository.dart`](../../lib/features/admin/data/repositories/admin_repository.dart) (`verify_payment`) |

## Agents

Database (SQL) · Flutter Developer (client) · Security (RLS / definer) · Reviewer

## Excerpt

See [`excerpt.md`](excerpt.md).

## Anti-patterns

- Two sequential client writes that should be one RPC
- Putting `service_role` in the Flutter client
- Calling `.rpc` from a widget/page
