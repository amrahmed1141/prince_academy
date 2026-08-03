# Supabase schema & RPC catalog

Source of truth for DB intent: ad-hoc scripts under `supabase/` (not a formal `supabase/migrations` history).  
Client access: Supabase Flutter SDK only (no Dio).

---

## Bootstrap order

Hive → `Supabase.initialize` → GetIt (`setupDI()`).

Config: `lib/core/config/supabase_config.dart` (`--dart-define`, publishable URL/anon key).

---

## Auth

- Email/password signup & login
- Session persistence + `onAuthStateChange`
- Profile row in `profiles` required after session (missing profile → sign out)

---

## Primary tables (observed)

| Table | Used for |
|-------|----------|
| `profiles` | User profile, role, FCM token |
| `coaches` | Coach directory / admin management |
| `coach_sessions` | Schedulable sessions |
| `branches` | Locations / maps |
| `bookings` | Member bookings |
| `payments` | Payment verification flows |
| `attendance` | Session attendance |
| `notifications` | In-app notification feed |

---

## Views (examples)

- `user_booking_history`
- `admin_scan_profile`
- `today_coach_sessions` — today's scheduled coach sessions for the admin dashboard (includes `booked_count` / `attended_count` from `bookings` + `attendance`)
- `today_attendance_members` — member-level companion to `today_coach_sessions` (one row per expected booking today with `is_attended`; counts match the KPI sums)
- Finance-related views (admin finance dashboards)
- Other admin/member reporting views as defined in SQL scripts

---

## RPCs (categories)

Prefer RPCs for transactional / multi-step work. Catalog by responsibility:

| Domain | RPC purposes (from analysis) |
|--------|------------------------------|
| Booking | Create, reschedule, cancel, conflict checks |
| Payments | Verify / reject |
| Attendance | Mark / unmark |
| Admin users | Paged active users, member counts |
| Other | Conflict checks and privileged aggregates via `SECURITY DEFINER` |

When adding RPCs: place SQL under `supabase/`, call only from repositories/datasources, and document RLS expectations.

---

## Storage buckets

| Bucket | Purpose |
|--------|---------|
| `profile-avatars` | Member/admin avatars |
| `coach-photos` | Coach imagery |
| `payment-screenshots` | Payment proof uploads (often public URL design) |

Common client pattern: image pick → resize/compress → Storage upload → public URL.

---

## Realtime

Channels / `onPostgresChanges` used purposefully for:

- Bookings
- Sessions / attendance
- Notifications
- Pending payments
- Finance
- Tracking / scan flows

Wire realtime inside repositories (or dedicated services), not pages.

---

## SQL script expectations

Scripts cover:

- RLS policies (`auth.uid()`, `is_admin()`)
- Storage policies
- Triggers (e.g. signup → profile creation)
- Indexes / performance fixes

**Gap:** no formal migration pipeline — coordinate script application across environments carefully.

---

## Who calls what (layering)

| Layer | May call Supabase? |
|-------|--------------------|
| `*_remote_ds.dart` / `*_repository.dart` | Yes |
| BLoC / Cubit | Via repository only |
| Pages / widgets | **No** (legacy exceptions in some admin scan/tracking/QR — do not add more) |

Admin `CoachRepository` is a large gateway (coaches, members, QR, attendance, subscriptions) — extend carefully.
