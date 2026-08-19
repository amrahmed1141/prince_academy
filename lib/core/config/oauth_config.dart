/// Native Google / Facebook IDs used by [AuthRemoteDs].
///
/// Prefer `--dart-define=GOOGLE_WEB_CLIENT_ID=...` (and optional
/// `GOOGLE_IOS_CLIENT_ID`) over expanding checked-in defaults.
///
/// Google **Web** client ID is required for `signInWithIdToken`.
/// The Client Secret stays in the Supabase dashboard only.
///
/// Facebook App ID + Client Token are native (`strings.xml` / `Info.plist`).
abstract final class OAuthConfig {
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '124408585431-rp583tm33lkpgr5jj5q8v1mp4gfcvtd.apps.googleusercontent.com',
  );

  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '124408585431-ftjc7ern9qibnt6f3ganfab7hfa7fc9e.apps.googleusercontent.com',
  );

  static bool get isGoogleConfigured => googleWebClientId.isNotEmpty;
}
