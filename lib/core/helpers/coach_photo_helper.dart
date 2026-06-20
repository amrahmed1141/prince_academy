import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves coach photo references from the database into displayable URLs/paths.
abstract final class CoachPhotoHelper {
  static const _bucket = 'coach-photos';

  /// Returns a URL/path suitable for [Image.network], [Image.file], or [Image.asset].
  static String? resolve(String? photoUrl) {
    if (photoUrl == null) return null;

    final trimmed = photoUrl.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }

    if (_looksLikeLocalFile(trimmed)) {
      return trimmed;
    }

    final storagePath = extractStoragePath(trimmed) ?? trimmed;
    return Supabase.instance.client.storage.from(_bucket).getPublicUrl(storagePath);
  }

  static bool isNetworkUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool isAssetPath(String value) => value.startsWith('assets/');

  static bool isLocalFile(String value) => _looksLikeLocalFile(value);

  /// Extracts `coaches/...` from a full Supabase public URL or returns the path as-is.
  static String? extractStoragePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    const marker = '/storage/v1/object/public/$_bucket/';
    final markerIndex = trimmed.indexOf(marker);
    if (markerIndex != -1) {
      return trimmed.substring(markerIndex + marker.length);
    }

    const signedMarker = '/storage/v1/object/sign/$_bucket/';
    final signedIndex = trimmed.indexOf(signedMarker);
    if (signedIndex != -1) {
      final pathWithQuery = trimmed.substring(signedIndex + signedMarker.length);
      final queryIndex = pathWithQuery.indexOf('?');
      return queryIndex == -1 ? pathWithQuery : pathWithQuery.substring(0, queryIndex);
    }

    if (!trimmed.startsWith('http')) {
      return trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    }

    return null;
  }

  static Future<String?> createSignedUrl(String? photoUrl) async {
    final path = extractStoragePath(photoUrl ?? '') ??
        (photoUrl != null && !isNetworkUrl(photoUrl) ? photoUrl.trim() : null);
    if (path == null || path.isEmpty) return null;

    try {
      return await Supabase.instance.client.storage
          .from(_bucket)
          .createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  static bool _looksLikeLocalFile(String value) {
    return value.startsWith('/') || value.contains(':\\');
  }
}
