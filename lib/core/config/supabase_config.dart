/// Supabase API settings (Dashboard → Project Settings → API).
///
/// Prefer `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// or replace the [defaultValue]s below for local development.
///
/// Ensure a `public.users` table exists with at least:
/// `id` (uuid, PK, matches `auth.users.id`), `full_name`, `phone`, `role`.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://sfeudxyhmivlinvshvpe.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_XfaN1uoEAcKrLC5aPs1UFg_PLiqAUNt',
  );
}
