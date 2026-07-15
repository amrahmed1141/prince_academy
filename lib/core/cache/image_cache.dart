import 'package:flutter/material.dart';

/// Shared [NetworkImage] providers so the same URL reuses one in-memory cache entry.
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

    final imageProvider = NetworkImage(trimmed);
    _providers[trimmed] = imageProvider;
    return imageProvider;
  }

  /// Warm images into Flutter's ImageCache without blocking the UI.
  static Future<void> precacheUrls(
    BuildContext context,
    Iterable<String?> urls,
  ) async {
    ensureBudget();
    for (final url in urls) {
      if (url == null || url.trim().isEmpty) continue;
      if (!url.startsWith('http')) continue;
      try {
        await precacheImage(provider(url), context);
      } catch (_) {}
    }
  }

  static void clear() {
    _providers.clear();
    PaintingBinding.instance.imageCache.clear();
  }
}
