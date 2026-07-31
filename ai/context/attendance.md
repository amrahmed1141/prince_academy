# Attendance

Status: filled

## Domain overview

Mark / re-attend / unmark attendance, QR scan flows, and member weekly progress. No `lib/features/attendance` — split across **admin** + **sessions**.

**Load when:** session detail attendance, QR scan, weekly grids, member progress charts, `attendance` RPCs/realtime.

## Important classes

- Admin models: `DayAttendance`, attendance/session detail models — `lib/features/admin/data/models/`
- Member: `SessionModel` (`attendanceStatus`, `attendedSessions`) — `lib/features/sessions/data/models/`
- `WeeklyProgressCalculator` — `lib/features/sessions/domain/weekly_progress_calculator.dart`
- UI: `session_detail_page`, `qr_scanner_page`, `weekly_attendance_chart`

## Important repositories

- `CoachRepository` — `markAttendance`, `reAttendSession`, `unmarkSession`, `getWeeklyAttendance`, `get_booking_sessions`
- `SessionsRepository` — attendance realtime + Hive snapshots

## Important Cubits / BLoCs

- `SessionDetailBloc` — `ReAttendSession`, `UnmarkSession`
- `TrackingBloc` — `LoadWeeklyAttendance`
- Member sessions UI consumes `SessionsRepository` streams (feature blocs as wired today)

## Business rules

- Privileged mutations via SECURITY DEFINER RPCs — not client-only admin flags.
- Reuse existing attendance/session models — no second shape.
- Preserve sessions cache-first + `attendance` realtime.
- Schema drift (e.g. `get_user_weekly_attendance` vs checked-in SQL) → fix SQL and Dart together.
- Attendance owns state/corrections; Booking owns schedule creation.
- Admin dashboard upcoming/live session cards read `attended_count` / `booked_count` from `today_coach_sessions` (derived from `attendance` + active verified `bookings` for today). No separate attendance-progress table. Dashboard realtime listens on `attendance`, `bookings`, `payments`, and `coach_sessions` (must be in `supabase_realtime` publication).
- Admin Home KPI page 1 sums those per-session counts into **today total attendance** (`Σ attended / Σ booked`) for the arc progress widget — no new RPC.
- Member mark-attendance cards use elevation-only chrome — no green gradient border on "markable today" cards.
- Approved freezes (`booking_freeze_dates`) are excluded from Needs-attention expected days and from `is_scheduled_today` / Mark Attended. `get_booking_sessions` returns `status = frozen` for those dates.

## Common mistakes

- Copying legacy `Supabase.instance` from QR/tracking into new code.
- Ignoring `fix_re_attend_updated_at.sql` when re-attend fails on `updated_at`.
- Inventing `lib/features/attendance` instead of extending admin/sessions.
- Encoding correction policy in widgets.

## Related documentation

- [`docs/supabase-schema-and-rpc.md`](../../docs/supabase-schema-and-rpc.md) (Attendance RPCs)
- SQL: `supabase/attendance_session_management.sql`, `fix_re_attend_updated_at.sql`
- Companions: [`booking.md`](booking.md), [`supabase.md`](supabase.md), [`architecture.md`](architecture.md)
- Rules: `.cursor/rules/product/academy-domain.mdc`, `product/admin-operations.mdc`
