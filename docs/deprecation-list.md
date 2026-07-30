# Deprecation list

Items identified in the architecture analysis as legacy, unused, or inconsistent.  
**Do not delete or “clean up” these unless explicitly requested.** Prefer additive consistency for new code.

---

## Safe to ignore for new work

| Item | Notes |
|------|-------|
| `lib/view/` | Empty / legacy remnant — do not add files |
| `provider` package in `pubspec.yaml` | No imports in `lib/` — do not start using it |
| `navigation_bloc.dart` | Unused legacy navigation approach |
| Duplicate/legacy screens | Older home/booking/session screens beside newer `*_page.dart` variants |
| `lib/shared/` expansion | Prefer `lib/core/widgets` |

---

## Known inconsistencies (do not mass-rename unless asked)

- Typos: `catgeory_model.dart`, `splach_theme.dart`
- Odd casing: `Login_header.dart`
- Mixed `fromJson` vs `fromMap`
- Mixed `Repo` vs `Repository` (auth uses `AuthRepo`)
- `FinanceCubit` living in a file named `finance_bloc.dart`
- Coach concepts modeled in both `admin` and `home`

---

## Structural debt (track, don’t surprise-fix)

- Incomplete Clean Architecture (domain mainly on auth)
- Presentation → Supabase leaks in some admin scan/tracking/QR flows
- God repositories (`CoachRepository`) and large admin screens
- No formal Supabase migration pipeline
- Imperative navigation limits deep-linking consistency
- Sparse tests
- Fragile transitive deps (`path` / `path_provider` used without direct pubspec declaration — fix only when touching those areas or asked)

---

## When removal is requested

1. Confirm no runtime references
2. Remove in a focused PR (no drive-by renames)
3. Update this list and `AGENTS.md` if contracts change
