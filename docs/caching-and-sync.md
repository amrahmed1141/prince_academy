# Caching & sync

Prince Academy optimizes perceived performance with **cache-first / stale-while-revalidate**.

---

## Layers

| Mechanism | Role |
|-----------|------|
| Hive (`LocalCacheStore`) | JSON snapshots on disk |
| In-memory TTL | Short-lived hot cache |
| `StreamRepository<T>` | Broadcast stream + TTL + dedupe + auto-refresh |
| `SharedPreferences` | Admin session-form drafts only |
| `MemberDataSync` / prefetch services | Invalidation and member data warm-up |

Path for stream base: `lib/core/base/stream_repository.dart`.

Repos known to use `StreamRepository`: `AdminRepository`, `CoachRepository`, `FinanceRepository`. Others may reimplement similar caching — prefer the shared base for new stream lists.

---

## BLoC pattern

1. Subscribe to repository stream
2. Emit cached / last-known data quickly
3. Refresh from network / realtime
4. Map failures to `String` error fields on state

---

## After mutations

- Invalidate or refresh through **existing** member sync helpers (`MemberDataSync` / prefetch) when home, booking, or sessions data changes
- Prefer `unawaited(...)` for non-blocking cache writes (existing style)
- Do not invent a second global event bus for cache

---

## Schema compatibility fallbacks

Some repositories retry queries with fewer columns when the remote schema lags. Extend this pattern only with a clear comment and matching SQL script updates.

---

## Rules of thumb

- Do not strip caching when “simplifying” list/dashboard repos unless asked
- Auth may show Hive-cached profile before network profile load — preserve that UX
- Sign-out must clear user Hive cache (see [auth-and-roles.md](auth-and-roles.md))
