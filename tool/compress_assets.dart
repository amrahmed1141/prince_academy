// One-off: dart run tool/compress_assets.dart
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() {
  final root = Directory.current.path;
  final assets = p.join(root, 'assets');

  // Sport photos → JPEG @ 1200px max, quality 82
  for (final name in ['bjj', 'box', 'kickbox', 'mma']) {
    final pngPath = p.join(assets, 'images', '$name.png');
    final jpgPath = p.join(assets, 'images', '$name.jpg');
    _toJpeg(pngPath, jpgPath, maxSide: 1200, quality: 82);
    final png = File(pngPath);
    if (png.existsSync()) png.deleteSync();
  }

  // Logos → PNG @ 512px max
  for (final name in ['logo.png', 'app_logo.png']) {
    final path = p.join(assets, 'icons', name);
    _resizePng(path, maxSide: 512);
  }

  // Coach JPEGs → 800px max, quality 82
  for (final name in ['fayo.jpeg', 'shently.jpeg', 'zombie.jpeg']) {
    final path = p.join(assets, 'coaches', name);
    _resizeJpegInPlace(path, maxSide: 800, quality: 82);
  }

  stdout.writeln('Done. Sizes:');
  for (final entity in Directory(assets).listSync(recursive: true)) {
    if (entity is! File) continue;
    final ext = p.extension(entity.path).toLowerCase();
    if (!const {'.png', '.jpg', '.jpeg'}.contains(ext)) continue;
    final kb = (entity.lengthSync() / 1024).toStringAsFixed(1);
    stdout.writeln('  ${p.relative(entity.path, from: root)}  ${kb} KB');
  }
}

void _toJpeg(String srcPath, String destPath, {required int maxSide, required int quality}) {
  final src = File(srcPath);
  if (!src.existsSync()) {
    stdout.writeln('Skip missing: $srcPath');
    return;
  }
  final decoded = img.decodeImage(src.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Failed to decode: $srcPath');
    return;
  }
  final resized = _fit(decoded, maxSide);
  File(destPath).writeAsBytesSync(img.encodeJpg(resized, quality: quality));
  stdout.writeln(
    'JPEG ${p.basename(destPath)}: ${decoded.width}x${decoded.height} → '
    '${resized.width}x${resized.height}',
  );
}

void _resizePng(String path, {required int maxSide}) {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('Skip missing: $path');
    return;
  }
  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Failed to decode: $path');
    return;
  }
  final resized = _fit(decoded, maxSide);
  file.writeAsBytesSync(img.encodePng(resized, level: 6));
  stdout.writeln(
    'PNG ${p.basename(path)}: ${decoded.width}x${decoded.height} → '
    '${resized.width}x${resized.height}',
  );
}

void _resizeJpegInPlace(String path, {required int maxSide, required int quality}) {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('Skip missing: $path');
    return;
  }
  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Failed to decode: $path');
    return;
  }
  final resized = _fit(decoded, maxSide);
  file.writeAsBytesSync(img.encodeJpg(resized, quality: quality));
  stdout.writeln(
    'JPEG ${p.basename(path)}: ${decoded.width}x${decoded.height} → '
    '${resized.width}x${resized.height}',
  );
}

img.Image _fit(img.Image src, int maxSide) {
  final longest = src.width >= src.height ? src.width : src.height;
  if (longest <= maxSide) return src;
  if (src.width >= src.height) {
    return img.copyResize(
      src,
      width: maxSide,
      interpolation: img.Interpolation.linear,
    );
  }
  return img.copyResize(
    src,
    height: maxSide,
    interpolation: img.Interpolation.linear,
  );
}
