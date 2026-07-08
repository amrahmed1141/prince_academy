import 'dart:io';

import 'package:prince_academy/core/config/supabase_config.dart';

/// Normalizes coach photo values from Supabase storage, public URLs, or local paths.
abstract final class CoachPhotoHelper {
  static const _bucket = 'coach-photos';

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
}
