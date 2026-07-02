import 'package:flutter/material.dart';

/// Shared [NetworkImage] providers so the same URL reuses one in-memory cache entry.
abstract final class AppImageCache {
  static final Map<String, ImageProvider> _providers = {};

  static ImageProvider provider(String url) {
    final trimmed = url.trim();
    final existing = _providers[trimmed];
    if (existing != null) return existing;

    final imageProvider = NetworkImage(trimmed);
    _providers[trimmed] = imageProvider;
    return imageProvider;
  }

  static void clear() {
    _providers.clear();
  }
}
