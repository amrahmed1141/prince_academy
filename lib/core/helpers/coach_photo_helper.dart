import 'dart:io';

import 'package:prince_academy/core/config/supabase_config.dart';

/// Normalizes coach photo values from Supabase storage, public URLs, or local paths.
abstract final class CoachPhotoHelper {
  static const _bucket = 'coach-photos';
  static const _objectPublic = '/storage/v1/object/public/';
  static const _renderPublic = '/storage/v1/render/image/public/';

  static const avatarThumbWidth = 256;
  static const heroWidth = 800;

  static String? normalize(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('file://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return value;
    }

    final base = SupabaseConfig.url.replaceAll(RegExp(r'/+$'), '');
    final path = value.startsWith('$_bucket/')
        ? value.substring('$_bucket/'.length)
        : value;

    return '$base/storage/v1/object/public/$_bucket/$path';
  }

  /// Small render URL for list avatars. Falls back to [normalize] when the
  /// value is not a public Storage object URL.
  static String? thumbnailUrl(
    String? raw, {
    int width = avatarThumbWidth,
  }) {
    return _transformed(raw, width: width, height: width, quality: 70);
  }

  /// Medium render URL for the coach profile hero.
  static String? heroUrl(String? raw, {int width = heroWidth}) {
    return _transformed(raw, width: width, quality: 75);
  }

  static Iterable<String> thumbnailUrls(Iterable<String?> raw) {
    final urls = <String>{};
    for (final value in raw) {
      final url = thumbnailUrl(value);
      if (url != null && url.startsWith('http')) urls.add(url);
    }
    return urls;
  }

  static bool isLocalPath(String url) {
    return url.startsWith('/') || url.startsWith('file://');
  }

  static File? localFile(String url) {
    if (url.startsWith('file://')) {
      return File(Uri.parse(url).toFilePath());
    }
    if (url.startsWith('/')) {
      return File(url);
    }
    return null;
  }

  static String? _transformed(
    String? raw, {
    required int width,
    int? height,
    int quality = 70,
  }) {
    final url = normalize(raw);
    if (url == null || isLocalPath(url)) return url;
    return transformedPublicUrl(
          url,
          width: width,
          height: height,
          quality: quality,
        ) ??
        url;
  }

  /// Rewrites a public Storage object URL to the image transformation endpoint.
  /// Returns null when [url] is not a public object URL.
  static String? transformedPublicUrl(
    String url, {
    required int width,
    int? height,
    int quality = 70,
  }) {
    if (url.contains(_renderPublic)) return url;
    if (!url.contains(_objectPublic)) return null;

    final swapped = url.replaceFirst(_objectPublic, _renderPublic);
    final uri = Uri.parse(swapped);
    return uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        'width': '$width',
        if (height != null) 'height': '$height',
        'resize': 'cover',
        'quality': '$quality',
      },
    ).toString();
  }
}
