# Authentication

Status: filled

## Domain overview

Session lifecycle, roles, profile identity, and authenticated navigation entry.

**Load when:** login/signup/sign-out, role checks, profile load/cache, `AuthenticatedShell`, sign-out cleanup (FCM/Hive).

## Important classes

- `UserModel` — `lib/features/auth/data/models/app_user.dart`
- `AuthenticatedShell` — `lib/app/app.dart`
- `AuthPage` — `lib/features/auth/presentation/pages/authentication/auth_page.dart`
- SQL helpers: `is_admin()`, `handle_new_user()` — `supabase/profiles_rls_fix.sql`, `fix_signup_trigger.sql`, `oauth_handle_new_user.sql`

## Important repositories

- `AuthRepo` — `lib/features/auth/domain/repositories/auth_repo.dart`
- `AuthRepoImpl` — `lib/features/auth/data/repositories/auth_repo_impl.dart`
- `AuthRemoteDs` — `lib/features/auth/data/datasources/auth_remote_ds.dart`

## Important Cubits / BLoCs

- `AuthBloc` — `lib/features/auth/presentation/bloc/auth_bloc.dart`
- Key events: `AuthStarted`, `AuthUserSignIn`, `AuthAdminSignIn`, `AuthGoogleSignIn`, `AuthFacebookSignIn`, `AuthSignOut`, `AuthRefreshProfile`
- Key states: `AuthAuthed`, `AuthNoSession`

## Business rules

- All auth remote I/O through `AuthRepo` → impl → DS.
- Native Google/Facebook sign-in is member-only (Sign In + Sign Up). Admin stays email/password.
- Missing `profiles` row → sign out → `AuthNoSession`.
- Admin requires `role == 'admin'`; UI role ≠ RLS.
- Do not treat signup metadata as authorization.
- Post-auth UI only via `AuthenticatedShell` (wires notifications/FCM).
- Sign-out: clear FCM token → dispose notification realtime → Supabase signOut → clear user Hive cache.
- Hive-cached profile may show early `AuthAuthed` — keep that UX.

## Common mistakes

- Navigating to `NavigationBottom` / `AdminHomeScreen` without the shell.
- Auth logic in widgets or legacy `presentation/pages/auth/` trees bypassing `AuthRepo`.
- Leaving FCM token / realtime / Hive profile after logout.

## Related documentation

- [`docs/auth-and-roles.md`](../../docs/auth-and-roles.md), [`docs/security-notes.md`](../../docs/security-notes.md)
- Gold standard: `lib/features/auth`
- Companions: [`notifications.md`](notifications.md) (token cleanup), [`supabase.md`](supabase.md) (profiles RLS)
- Rules: `.cursor/rules/data/auth-boundary.mdc`, `flutter/navigation-shell.mdc`
