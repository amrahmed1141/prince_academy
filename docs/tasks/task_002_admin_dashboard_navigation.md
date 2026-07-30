# Task 002 — Admin Dashboard KPI Navigation

| Field | Value |
|-------|-------|
| Owner | Flutter |
| Last reviewed | 2026-07-26 |
| Status | `implemented` |
| Pipeline | Feature Development (Scope + Design) |
| Persistence | **no** (read-only existing views) |

## Summary

Wire the three Admin Dashboard KPI cards to real destinations: Active Members → existing All Members page; Today's Sessions → new standalone list page; Today's Revenue → Finance as a pushed page with AppBar back (no bottom nav). Preserve imperative Navigator + existing Cubit/repo patterns.

---

## Change Brief

| Item | Value |
|------|-------|
| Goal | Make Active Members, Today's Sessions, and Today's Revenue KPI cards navigate to useful admin destinations |
| Actors | Admin only (`role == 'admin'`, via `AuthenticatedShell` → `AdminHomeScreen`) |
| Risk tier | Low — client navigation + one read-only list page; no SQL/RPC/auth changes |
| Pipeline | Feature Development |
| Agents | Orchestrator → Architect (this doc) → Flutter (after approval) → Reviewer → QA |
| Context loaded | `ai/context/architecture.md`; admin-dashboard pack is **retired** (pointers only); navigation via `.cursor/rules/flutter/navigation-shell.mdc` + admin shell code |
| Non-goals | Refactor `CoachRepository` / `FinanceRepository`; change bottom-nav tab set; member `SessionsPage` / `SessionsRepository`; new router; schema/RPC |

---

## Current implementation (analysis)

### Shell & tabs

- `AdminHomeScreen` (`lib/features/admin/presentation/pages/admin_home.dart`) hosts an `IndexedStack` + floating `AdminGlassNavBar`.
- Tab order: `AdminDashboardPage` (0) · `AdminAddInfoPage` (1) · `TrackingPage` (2) · `FinancePage` (3).
- `AdminTabController` (`lib/core/services/admin_tab_controller.dart`) switches tabs in-place; it does **not** push routes.

### KPI taps today (`admin_dashboard_page.dart`)

| Card | Current handler | Effect |
|------|-----------------|--------|
| Pending | `_openPendingPayments` → `Navigator.push(PendingPaymentsPage)` | Standalone ✓ |
| Today's revenue | `sl<AdminTabController>().goFinance()` | Switches to tab 3 (bottom nav stays) |
| Active members | `sl<AdminTabController>().goTracking()` | Switches to tab 2 |
| Today's sessions | `sl<AdminTabController>().goTracking()` | Switches to tab 2 |

`DashboardTodayList` "View all" also calls `goTracking()` — same incomplete destination.

### Existing destinations to reuse

| Need | Existing surface | Notes |
|------|------------------|-------|
| All members | `AllMembersPage` + `MembersListCubit` + `CoachRepository.getMembers` | Already standalone: AppBar `BackButton`, `AppSearchBar`, `RefreshIndicator`, loading / error / empty. Opened today from Tracking "View all" via `Navigator.push`. Accepts optional `initialMembers` (default `[]`). |
| Finance | `FinancePage` + `FinanceCubit` | Built as a **tab**: own `Scaffold`/`AppBar` with **no** back button. No `showBackButton` flag. |
| Today's sessions (admin-wide) | **None** | Dashboard preview only (cap 5). |

### Session data — important boundary

- Member `Session` / `SessionsRepository` / `SessionsPage` are **current-user scoped**. Do **not** use them for an admin academy-wide "today" list.
- Admin already reads view `today_bookings` in `AdminDashboardRepository._fetchTodaySessions()` and maps to `DashboardTodaySession`.
- That private fetch already returns **all** rows; `loadDashboard()` only `.take(5)` for the preview. Count uses full list length.
- Related but per-user: `CoachRepository.getTodayBookings(userId)` → `TodayBooking` (not the right list source for this page).

### Gold navigation patterns to copy

1. **Push standalone list** — `PendingPaymentsPage`, `AllMembersPage` (`Navigator.push` + `MaterialPageRoute`).
2. **Tab content as pushed page with back** — `SessionsPage(showBackButton: true)` from Profile: optional flag adds AppBar leading; default `false` keeps tab behaviour.

---

## Scope / out of scope

### In scope

1. Active Members KPI → `Navigator.push` → `AllMembersPage()`.
2. New **Today's Sessions** admin page (search, pull-to-refresh, empty / loading / error) using existing admin session model + repository read of `today_bookings`.
3. Today's Sessions KPI → push that new page.
4. Today's Revenue KPI → push Finance as standalone (AppBar + Back); do **not** switch bottom-nav tab.
5. Minimal `FinancePage` API so tab embed still works without a back button.

### Out of scope

- SQL / RPC / RLS / new views.
- Extracting or splitting admin god-repositories.
- Changing `AdminTabController` indices or nav bar items.
- Member sessions feature.
- Pagination for today's sessions (view is day-scoped; full list is acceptable unless volume proves otherwise later).
- Drive-by refactors, renames, or legacy `lib/view/` cleanup.

### Recommended consistency (same PR if approved)

- `DashboardTodayList.onSeeAll` → open the new Today's Sessions page (same destination as the KPI). Optional; call out in implementation if skipped.

---

## Design decisions

### 1. Active Members → reuse `AllMembersPage`

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const AllMembersPage()),
);
```

- No new Cubit/repo.
- Do **not** call `goTracking()`.
- `initialMembers` left empty; cubit loads via existing RPC path.

### 2. Today's Sessions → new page under admin feature

**Placement**

```
lib/features/admin/
  data/repositories/admin_dashboard_repository.dart   # expose full today list
  presentation/bloc/…                                 # small Cubit (+ state)
  presentation/pages/…                                # TodaySessionsPage
```

**Data**

- Reuse model: `DashboardTodaySession`.
- Reuse repo: `AdminDashboardRepository` — promote `_fetchTodaySessions()` to a public method (e.g. `getTodaySessions()`) and keep `loadDashboard()` calling it. No second query path.
- No new SQL; view `today_bookings` already used.

**State**

- New Cubit (mirror `MembersListCubit` / `AdminDashboardCubit` style): `load`, `refresh`, client-side search filter on member/coach/time.
- Register Cubit as **factory** in `injection.dart` **or** construct inline with `sl<AdminDashboardRepository>()` like `MembersListCubit` in `AllMembersPage` — prefer matching `AllMembersPage` (inline) to avoid DI churn unless a factory is already the local norm for similar screens.
- Prefer existing search helper patterns (`AppSearchBar` + debounce if already used nearby).

**UI** (copy `AllMembersPage` / `PendingPaymentsPage` structure)

| Requirement | Approach |
|-------------|----------|
| Search bar | `AppSearchBar` |
| Pull-to-refresh | `RefreshIndicator` or `BrandedPullToRefresh` (match nearest admin list) |
| Loading | Existing shimmer / loading pattern from sibling admin pages |
| Empty | Simple empty illustration + copy ("No sessions today") |
| Error | Message + retry calling cubit `load`/`refresh` |
| AppBar | Title + `BackButton` / leading pop |
| Row UI | Reuse `DashboardTodayList` row styling or extract a small shared tile if duplication is tiny; otherwise duplicate minimally — do not invent a new card system |

**Row tap (default)**

- Same as dashboard preview: `UserTrackingDetailPage(userId:, initialName:)` — keeps behaviour consistent. Confirm only if product wants session-detail instead (none exists admin-wide today).

### 3. Today's Revenue → Finance standalone

- Add optional `showBackButton` (default `false`) to `FinancePage`, mirroring `SessionsPage`.
- When `true`: AppBar `leading` pops via `Navigator.maybePop`.
- When `false` (tab): unchanged — no back button.
- KPI handler:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const FinancePage(showBackButton: true),
  ),
);
```

- Do **not** call `goFinance()`. Bottom nav remains on Home; Finance is a route above the shell stack.
- `BlocProvider` + `sl<FinanceCubit>()..load()` stays as today (fresh cubit per push is correct for factory registration).

### Navigation invariants

- Imperative `Navigator` + `MaterialPageRoute` only.
- Still enter admin UI only through `AuthenticatedShell`.
- No named routes / go_router / auto_route.

---

## Data changes

**None.** No migrations, RPCs, or RLS edits. Client continues to `select` from `today_bookings`.

---

## Planned files / areas

| File | Change |
|------|--------|
| `lib/features/admin/presentation/pages/admin_dashboard_page.dart` | Rewire `onMembersTap`, `onTodayTap`, `onRevenueTap` (+ optionally today "View all") |
| `lib/features/admin/presentation/pages/finance_page.dart` | Add `showBackButton`; AppBar leading when true |
| `lib/features/admin/data/repositories/admin_dashboard_repository.dart` | Public `getTodaySessions()`; dashboard load reuses it |
| `lib/features/admin/presentation/pages/…/today_sessions_page.dart` | **New** standalone list page |
| `lib/features/admin/presentation/bloc/…` | **New** Cubit + state for today sessions list + search |
| `lib/core/di/injection.dart` | Only if Cubit is registered as factory (optional) |

**Untouched by design:** `AdminTabController`, `AdminHomeScreen` tab list, `SessionsRepository`, SQL, member bottom nav.

---

## Implementation steps (after approval)

1. Expose `AdminDashboardRepository.getTodaySessions()`.
2. Add Today Sessions Cubit/state + page (UI states complete before wiring KPI).
3. Add `FinancePage(showBackButton: …)`.
4. Update KPI handlers in `AdminDashboardPage` (and optional today "View all").
5. Manual QA checklist below.
6. Docs/context: only if behaviour notes are desired later — not required for this navigation-only task unless product docs mention the old tab-switch behaviour.

---

## Acceptance criteria

| # | Criterion | Evidence |
|---|-----------|----------|
| 1 | Tap **Active members** opens `AllMembersPage` with back affordance; bottom nav not required to leave | Manual: from Home KPI → list → Back → still on Dashboard |
| 2 | Tap **Today's sessions** opens new page listing all `today_bookings` sessions (not capped at 5) | Manual: count matches KPI when > 5 |
| 3 | Today page has search, pull-to-refresh, empty, loading, error+retry | Manual / UI walkthrough |
| 4 | Today page uses `DashboardTodaySession` + `AdminDashboardRepository` (no member `SessionsRepository`) | Code review |
| 5 | Tap **Today's revenue** pushes Finance with AppBar Back; glass bottom nav **not** visible on that route | Manual |
| 6 | Finance tab (nav bar index 3) still works with no back button | Manual |
| 7 | No new packages, routers, or SQL | Diff review |
| 8 | Diff stays minimal; no god-repo extraction | Diff review |

---

## Residual risks / open questions

| Item | Notes | Default if unanswered |
|------|-------|------------------------|
| Search fields | Member name, coach name, time? | Filter all three (case-insensitive contains) |
| Row tap on Today page | Tracking detail vs no-op | Same as dashboard: open `UserTrackingDetailPage` |
| Wire "View all" on `DashboardTodayList` | Same as KPI? | **Yes** — same destination |
| Empty `AllMembersPage` from dashboard (no seed list) | Slightly colder first paint vs Tracking "View all" | Acceptable; cubit `load()` handles it |
| Double Finance instance | Tab keeps a live `FinancePage` in `IndexedStack`; push creates another | Acceptable; same as other pushed pages with their own providers |

---

## Feature report (planning)

- **Summary:** Rewire three dashboard KPIs to push real admin destinations; add one Today Sessions list page on existing `today_bookings` read path; make Finance pushable with back.
- **Scope / out of scope:** See above.
- **Boundaries:** UI → Cubit → `AdminDashboardRepository` / existing `MembersListCubit`+`CoachRepository` / existing `FinanceCubit`; no widget→Supabase.
- **Data changes:** none.
- **Files / areas:** See planned files table.
- **DI / wiring:** Prefer existing patterns; factory only if registering new Cubit.
- **Acceptance evidence:** Manual checklist above.
- **Docs / context updated:** This task doc only until implementation ships.
- **Residual risks:** See table; no Blockers for design approval.

---

## Gate board

| Gate | Status |
|------|--------|
| Scope locked | Done |
| Design approved | Done (human requested implement) |
| Data ready | N/A (no SQL) |
| Implement | Done |
| Review / QA | Pending manual verification |

---

## Next action

Manual QA against acceptance criteria; optional Reviewer pass.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-07-26 | Analysis + implementation plan created (no code changes) |
| 2026-07-26 | Implemented KPI navigation, TodaySessions page, Finance showBackButton |
