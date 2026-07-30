# Security notes

---

## Client privileges

| Allowed in Flutter | Forbidden in Flutter |
|--------------------|----------------------|
| Supabase **anon / publishable** key | Supabase **`service_role`** key |
| `--dart-define` config | Private API secrets / server tokens |

Publishable defaults in source are acceptable only for anon keys; prefer env discipline for real deployments.

---

## Authorization model

- **RLS** with `auth.uid()` and `is_admin()` patterns in SQL
- Privileged multi-step work via **`SECURITY DEFINER` RPCs** (booking, payment verify/reject, attendance)
- Admin UI role gate (`role == 'admin'`) is UX — **not** the security boundary

### Metadata warning

Signup may pass role in user metadata. **Triggers and RLS must not trust user-editable metadata for authorization.**

---

## Storage

Buckets: `profile-avatars`, `coach-photos`, `payment-screenshots`.

Payment screenshots appear designed for **public URLs**. Treat as intentional but sensitive:

- Do not casually broaden public access
- Keep storage policies aligned with scripted SQL

---

## Session hygiene

On sign-out: clear FCM token, dispose notification realtime, Supabase sign-out, clear user Hive cache.

---

## Agent / PR checklist

- [ ] No `service_role` in app or committed env samples meant for clients
- [ ] New tables/RPCs include RLS thinking
- [ ] `SECURITY DEFINER` functions minimize trust surface
- [ ] No new direct Supabase calls from widgets
- [ ] SQL script added under `supabase/` for schema changes
