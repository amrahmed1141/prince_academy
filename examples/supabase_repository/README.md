# Supabase repository (cache-first)

Approved remote + cache patterns for lists and live admin data.

## Why

Encodes cache-first / stale-while-revalidate: in-memory TTL, Hive disk hydrate, realtime refresh, and (for admin lists) `StreamRepository<T>`. Gold standards: `booking`, `sessions`.

## Sources (truth)

| Role | Path |
|------|------|
| Member bookings (L1+L2 cache) | [`lib/features/booking/data/repositories/booking_repository.dart`](../../lib/features/booking/data/repositories/booking_repository.dart) |
| Stream + TTL base | [`lib/core/base/stream_repository.dart`](../../lib/core/base/stream_repository.dart) |
| Admin live list | [`lib/features/admin/data/repositories/admin_repository.dart`](../../lib/features/admin/data/repositories/admin_repository.dart) |
| Sessions (also gold) | [`lib/features/sessions/data/repositories/sessions_repository.dart`](../../lib/features/sessions/data/repositories/sessions_repository.dart) |

## Agents

Flutter Developer · Performance · Reviewer · Architect

## Excerpt

See [`excerpt.md`](excerpt.md).

## Anti-patterns

- Fetching lists from widgets/pages
- Removing TTL/stream caching while “simplifying”
- A second ad-hoc cache bus beside `MemberDataSync` / existing helpers
