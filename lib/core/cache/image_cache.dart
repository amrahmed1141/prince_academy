import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:prince_academy/core/cache/disk_image_cache.dart';
import 'package:prince_academy/core/helpers/coach_photo_helper.dart';

/// Shared image providers so the same URL reuses one in-memory cache entry
/// and a disk file across launches.
/// Also bumps Flutter's image cache budget for smoother coach/avatar scrolling.
abstract final class AppImageCache {
  static final Map<String, ImageProvider> _providers = {};
  static bool _budgetConfigured = false;

  static void ensureBudget() {
    if (_budgetConfigured) return;
    _budgetConfigured = true;
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = 200;
    cache.maximumSizeBytes = 40 << 20; // 40 MB
  }

  static ImageProvider provider(String url) {
    ensureBudget();
    final trimmed = url.trim();
    final existing = _providers[trimmed];
    if (existing != null) return existing;

    final ImageProvider imageProvider;
    if (kIsWeb) {
      imageProvider = NetworkImage(trimmed);
    } else {
      imageProvider = DiskCachedNetworkImage(trimmed);
    }
    _providers[trimmed] = imageProvider;
    return imageProvider;
  }

  /// Download files to disk without a [BuildContext] (member prefetch).
  static Future<void> warmUrls(Iterable<String?> urls) async {
    if (kIsWeb) return;
    final unique = <String>{};
    for (final url in urls) {
      if (url == null) continue;
      final trimmed = url.trim();
      if (trimmed.startsWith('http')) unique.add(trimmed);
    }
    await Future.wait(unique.map(_ensureWithTransformFallback));
  }

  /// Warm images into Flutter's ImageCache without blocking the UI.
  static Future<void> precacheUrls(
    BuildContext context,
    Iterable<String?> urls,
  ) async {
    ensureBudget();
    final tasks = <Future<void>>[];
    for (final url in urls) {
      if (url == null || url.trim().isEmpty) continue;
      if (!url.startsWith('http')) continue;
      tasks.add(() async {
        try {
          await precacheImage(provider(url), context);
        } on NetworkImageLoadException catch (e) {
          final original = _fallbackAfterTransformFailure(url, e.statusCode);
          if (original == null) return;
          try {
            await precacheImage(provider(original), context);
          } catch (_) {}
        } catch (_) {}
      }());
    }
    await Future.wait(tasks);
  }

  static Future<void> _ensureWithTransformFallback(String url) async {
    try {
      await DiskImageCache.ensure(url);
    } on NetworkImageLoadException catch (e) {
      final original = _fallbackAfterTransformFailure(url, e.statusCode);
      if (original == null) return;
      try {
        await DiskImageCache.ensure(original);
      } catch (_) {}
    } catch (_) {}
  }

  static String? _fallbackAfterTransformFailure(String url, int statusCode) {
    if (statusCode != 403 || !CoachPhotoHelper.isRenderUrl(url)) return null;
    CoachPhotoHelper.disableTransforms();
    return CoachPhotoHelper.objectUrlFromRender(url);
  }

  static void clear() {
    _providers.clear();
    PaintingBinding.instance.imageCache.clear();
    unawaited(DiskImageCache.clear());
  }
}
