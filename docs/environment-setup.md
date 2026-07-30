# Environment setup

---

## Prerequisites

- Flutter SDK compatible with `pubspec.yaml` (`>=3.2.3 <4.0.0`)
- Platform toolchains as needed (Android / iOS / web / desktop)
- Access to the project’s Supabase project and (for push) Firebase project

---

## Flutter

```bash
flutter pub get
flutter run
```

Pass Supabase config via `--dart-define` (see `lib/core/config/supabase_config.dart`).  
Checked-in defaults may exist for publishable URL/anon key — prefer explicit defines for non-local environments.

Example shape:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

(Use the exact define names implemented in `supabase_config.dart`.)

---

## Firebase

- `firebase_options.dart` / platform config files present for Messaging
- Push registration is **mobile-oriented** (Android/iOS)
- FCM token stored on `profiles.fcm_token`

---

## Maps

Branch/maps feature may require platform/maps API keys per existing `maps` feature configuration — follow in-code config, do not invent a second key channel.

---

## Supabase SQL scripts

- Scripts live in `supabase/` as named setup/fix files
- There is **no** guaranteed CLI migration history (`supabase/migrations`)
- Apply scripts deliberately per environment; keep RLS and storage policies in sync with the app

---

## Analysis / lint

- `analysis_options.yaml` uses default `flutter_lints`
- No custom analyzer rule set beyond that — match existing style rather than imposing new lint packages unless asked

---

## Tests

```bash
flutter test
```

Coverage is sparse; see [testing-guide.md](testing-guide.md) for priorities when adding tests.
