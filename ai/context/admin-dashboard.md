# Admin Dashboard (retired)

Status: retired

Not a major context pack — admin spans many domains and over-fetches if loaded alone.

## Load instead

| Task | Pack |
|------|------|
| Shell, DI, StreamRepository, god-repos | [`architecture.md`](architecture.md) |
| Privileged SQL / RLS / RPCs | [`supabase.md`](supabase.md) |
| Verify / reject / finance | [`payments.md`](payments.md) |
| QR / attendance corrections | [`attendance.md`](attendance.md) |
| Renew | [`subscriptions.md`](subscriptions.md) |
| Role / shell entry | [`authentication.md`](authentication.md) |

## Pointers only

- `AdminHomeScreen` — `lib/features/admin/presentation/pages/admin_home.dart`
- Dashboard: `AdminDashboardCubit`, `AdminDashboardRepository`
- Top KPI: `DashboardKpiPager` (swipeable Today Attendance + Overview); schedules list: `AllSchedulesPage`; freeze inbox: `AllFreezePage` (Overview Freeze card = pending request count)
- Today attendance ratio = Σ `attended_count` / Σ `booked_count` from `today_coach_sessions` (no extra RPC)
- God repos (incremental only): `AdminRepository`, `CoachRepository`, `FinanceRepository`
- Rule: `.cursor/rules/product/admin-operations.mdc`

See [`INDEX.md`](INDEX.md).
