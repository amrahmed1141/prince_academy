import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads remote images once and reuses the file across app launches.
abstract final class DiskImageCache {
  static const _maxBytes = 40 << 20; // 40 MB
  static final HttpClient _http = HttpClient()..autoUncompress = true;
  static final Map<String, Future<Uint8List>> _inflight = {};
  static Directory? _dir;

  static Future<void> ensure(String url) async {
    await bytesFor(url);
  }

  static Future<Uint8List> bytesFor(String url) {
    final pending = _inflight[url];
    if (pending != null) return pending;

    final future = _load(url);
    _inflight[url] = future;
    return future.whenComplete(() => _inflight.remove(url));
  }

  static Future<void> clear() async {
    _inflight.clear();
    try {
      final dir = _dir ?? await _cacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
    _dir = null;
  }

  static Future<Uint8List> _load(String url) async {
    final file = await _fileFor(url);
    if (await file.exists()) {
      final cached = await file.readAsBytes();
      if (cached.isNotEmpty) return cached;
    }

    final bytes = await _download(url);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    unawaited(_evictIfNeeded());
    return bytes;
  }

  static Future<Uint8List> _download(String url) async {
    final uri = Uri.parse(url);
    final request = await _http.getUrl(uri);
    request.followRedirects = true;
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw NetworkImageLoadException(
        statusCode: response.statusCode,
        uri: uri,
      );
    }
    final bytes = await consolidateHttpClientResponseBytes(response);
    if (bytes.isEmpty) {
      throw NetworkImageLoadException(
        statusCode: response.statusCode,
        uri: uri,
      );
    }
    return bytes;
  }

  static Future<File> _fileFor(String url) async {
    final dir = await _cacheDir();
    return File('${dir.path}/${_key(url)}.img');
  }

  static Future<Directory> _cacheDir() async {
    final cached = _dir;
    if (cached != null) return cached;
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}image_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  static String _key(String url) {
    final bytes = utf8.encode(url);
    var hash = 0xcbf29ce484222325;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  static Future<void> _evictIfNeeded() async {
    try {
      final dir = await _cacheDir();
      final files = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File) files.add(entity);
      }

      final modified = <File, DateTime>{};
      var total = 0;
      for (final file in files) {
        final stat = await file.stat();
        total += stat.size;
        modified[file] = stat.modified;
      }
      if (total <= _maxBytes) return;

      final oldest = modified.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (final entry in oldest) {
        if (total <= _maxBytes) break;
        final size = (await entry.key.stat()).size;
        await entry.key.delete();
        total -= size;
      }
    } catch (_) {}
  }
}

/// [ImageProvider] that reads [DiskImageCache] before hitting the network.
@immutable
class DiskCachedNetworkImage extends ImageProvider<DiskCachedNetworkImage> {
  const DiskCachedNetworkImage(this.url);

  final String url;

  @override
  Future<DiskCachedNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<DiskCachedNetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    DiskCachedNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: url,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('URL: $url'),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    DiskCachedNetworkImage key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await DiskImageCache.bytesFor(key.url);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is DiskCachedNetworkImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
