# Auth & roles

---

## Flow

1. `AuthStarted` checks session via `AuthRepo`
2. Optional Hive-cached profile → immediate `AuthAuthed`
3. Load `profiles` row; missing profile → sign out → `AuthNoSession`
4. UI mapping:
   - `AuthInitial` → Splash
   - `AuthAuthed` → `AuthenticatedShell(isAdmin: role == 'admin')`
   - else → `AuthPage`

---

## Signup

- `signUp` with metadata (name, phone, role)
- DB trigger and/or client upsert fallback creates `profiles`
- **Do not** treat user-editable metadata as authorization — RLS / triggers / `is_admin()` enforce role

---

## Login

- `signInWithPassword` (email) on Sign In / Admin
- Native Google / Facebook ID-token sign-in on Sign In and Sign Up only (`signInWithIdToken`)
- Admin path additionally enforces `role == 'admin'`; otherwise sign out
- Dismissing a Google / Facebook sheet is not an error (stays on `AuthPage`)
- Google Web Client ID via `--dart-define=GOOGLE_WEB_CLIENT_ID=...`; secrets stay in the Supabase dashboard

---

## Session

- Persisted by Supabase
- `AuthBloc` listens for signed-out
- Profile refresh event exists — use it rather than ad-hoc client session hacks

---

## Sign-out (required cleanup)

1. Clear FCM token on profile
2. Dispose notification realtime
3. Supabase sign-out
4. Clear user Hive cache

---

## AuthenticatedShell contract

Post-auth UI **always** goes through `AuthenticatedShell` so:

- `NotificationBloc` is wired
- FCM callbacks remain active

Do not navigate to member bottom nav or `AdminHomeScreen` in a way that skips this shell.

---

## Domain boundary

| Piece | Location / name |
|-------|-----------------|
| Contract | `AuthRepo` |
| Implementation | `AuthRepoImpl` |
| Remote | `AuthRemoteDs` |
| Model | `UserModel` (`auth/data/models/app_user.dart`) |

New auth behavior must go through this contract.

---

## Roles

| Role signal | UX effect |
|-------------|-----------|
| `role == 'admin'` | Admin shell / `AdminHomeScreen` |
| otherwise | Member `NavigationBottom` |

UI role checks are **not** a substitute for RLS.
