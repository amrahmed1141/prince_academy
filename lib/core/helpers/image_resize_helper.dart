import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resizes coach photos before upload to reduce storage and load time.
abstract final class ImageResizeHelper {
  static const int maxDimension = 800;
  static const int jpegQuality = 85;

  /// Returns a temp file with resized image (max [maxDimension] px on longest side).
  /// Returns original file if resize fails or image is already small enough.
  static Future<File> resizeCoachPhoto(File source) async {
    try {
      final bytes = await source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return source;

      if (decoded.width <= maxDimension && decoded.height <= maxDimension) {
        return source;
      }

      final resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDimension : null,
        height: decoded.height > decoded.width ? maxDimension : null,
        interpolation: img.Interpolation.linear,
      );

      final encoded = img.encodeJpg(resized, quality: jpegQuality);
      final tempDir = await getTemporaryDirectory();
      final baseName = p.basenameWithoutExtension(source.path);
      final outPath = p.join(
        tempDir.path,
        '${baseName}_resized_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final outFile = File(outPath);
      await outFile.writeAsBytes(Uint8List.fromList(encoded));
      return outFile;
    } catch (_) {
      return source;
    }
  }
}
