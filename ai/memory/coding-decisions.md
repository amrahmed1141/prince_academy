# Coding Decisions

Status: filled

Append dated entries. Do not invent.

<!-- YYYY-MM-DD — note -->

2026-08-21 — App language: `LocaleCubit` (SharedPreferences `app_locale`) + `AppStrings` EN/AR maps under `lib/core/l10n/`. `MaterialApp` sets `locale` + `flutter_localizations` for RTL. Admin Profile has Language picker; admin chrome (nav, headers, dashboard, search destinations) uses `context.s`. Expand `_en`/`_ar` maps for remaining admin/member screens.

2026-08-20 — Coach photos default to public object URLs (`CoachPhotoHelper.transformsEnabled = false`) because Storage Image Transformations are not enabled on this tenant (`FeatureNotEnabled` on `/render/image/`). When Pro transforms are turned on in Dashboard Storage settings, set `transformsEnabled = true` (avatar 256px / hero 800px render + original fallback). Disk cache + prefetch unchanged.

2026-08-18 — Member Google/Facebook login uses native ID tokens (`google_sign_in` 6.x + `flutter_facebook_auth` 6.x → `signInWithIdToken`) through `AuthRepo`. Buttons live on Sign In and Sign Up only. Google Web Client ID is `--dart-define=GOOGLE_WEB_CLIENT_ID`. Facebook App ID/Client Token are native placeholders until filled. `handle_new_user` also reads OAuth `name`.

2026-08-18 — Admin Create (formerly Add Info) is a hub of Coach/Session cards. Lists moved to All Coaches / All Schedules. Create-coach is a compact photo+name+specialty-chips form; create-session uses day chips, shared class type, time+duration on one row, hides branch when there is only one, and a sticky single CTA. Bottom nav and dashboard chip label is Create.

2026-08-18 — Dashboard Quick Actions Tracking and Add Info push `TrackingPage(showBackButton: true)` and `AdminAddInfoPage(showAsStandalone: true)` (back arrow, same pages as the tabs). Scan still opens `QrScannerPage`. Bottom-nav tabs are unchanged.

2026-08-18 — Admin dashboard Quick Actions sit under the KPI pager (Scan → `QrScannerPage`, Tracking → `AdminTabController.goTracking()`, Add Info → `goAddInfo()`), matching the shell FAB and bottom-nav tabs. The previous bottom-of-scroll Scan/Verify/Manage/Session row was replaced by this row.

2026-08-18 — Coach photos: list avatars use Supabase Storage image transforms (`/render/image/public/...`, 256px) with fallback to the original object URL; profile hero uses an 800px render. `AppImageCache` stores files on disk (`DiskImageCache`, 40MB). Home/Coaches paint Hive-cached coaches before class-type/member-count extras; `MemberDataPrefetch` warms thumbnail files after coach JSON.

2026-08-17 — `AppSearchBar` capsule chrome is shared on every search field. Global search opens only from Home (`HomeSearchBar` read-only tap). Booking, Sessions, coaches, and admin lists stay local filters via `onChanged`.

2026-08-16 — Admin All Coaches + All Schedules use cache-first + realtime (same shape as dashboard/finance): first open fetches into `CoachRepository` in-memory TTL; later opens skip network while TTL is valid; Postgres realtime on `bookings`/`coaches`/`coach_sessions` refreshes in the background. Pull-to-refresh still forces a network reload.

2026-08-13 — Admin live lists use `StreamRepository.refreshInBackground()` for timers/realtime so socket failures never hit the zone; user-facing copy via `lib/core/helpers/remote_error.dart`. Admin `IndexedStack` mounts a tab only after first visit to avoid a request stampede.

2026-08-13 — Member booking renew: Home prompt via `BookingRenewCubit` + RPCs `get_renewable_bookings` / `dismiss_booking_renew_prompt` / `renew_expired_booking` (`supabase/booking_renew.sql`). New booking keeps original days/time/price; calendar + payment reuse existing widgets. Cancel was originally permanent (`renew_prompt_dismissed_at`); **2026-08-15** changed Cancel to session-only so the card returns on next app open; history Renew + manual Book Now still work after Cancel.
2026-08-13 — Member weekly attendance UI reuses `SemiCircularGauge` (`lib/core/widgets/semi_circular_gauge.dart`) with `WeeklyProgressCalculator.calculate` (attended / scheduled this week, including upcoming days). No new SQL/RPC.
2026-08-10 — Member Home calendar day circles reuse `AppGradients.sessionProgress` and color from existing `allSessions` attendance (no new SQL/RPC).
