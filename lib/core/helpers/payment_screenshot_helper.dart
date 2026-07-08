import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves stored payment screenshot URLs for display (public or signed).
class PaymentScreenshotHelper {
  static const _bucket = 'payment-screenshots';

  /// Extracts the storage object path from a Supabase public/signed URL.
  static String? storagePathFromUrl(String url) {
    const markers = [
      '/storage/v1/object/public/$_bucket/',
      '/storage/v1/object/sign/$_bucket/',
      '/storage/v1/object/authenticated/$_bucket/',
      '/$_bucket/',
    ];

    for (final marker in markers) {
      final idx = url.indexOf(marker);
      if (idx == -1) continue;
      final raw = url.substring(idx + marker.length).split('?').first;
      if (raw.isEmpty) return null;
      return Uri.decodeComponent(raw);
    }

    return null;
  }

  /// Returns a URL the admin UI can load. Uses a signed URL when possible.
  static Future<String> resolveViewUrl(
    SupabaseClient client,
    String storedUrl,
  ) async {
    final trimmed = storedUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    final path = storagePathFromUrl(trimmed);
    if (path == null || path.isEmpty) return trimmed;

    try {
      return await client.storage.from(_bucket).createSignedUrl(path, 3600);
    } catch (_) {
      return trimmed;
    }
  }
}
