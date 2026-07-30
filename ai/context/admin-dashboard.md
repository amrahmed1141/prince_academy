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
- God repos (incremental only): `AdminRepository`, `CoachRepository`, `FinanceRepository`
- Rule: `.cursor/rules/product/admin-operations.mdc`

See [`INDEX.md`](INDEX.md).
