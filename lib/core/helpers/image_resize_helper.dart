import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resizes photos before upload to reduce storage and load time.
abstract final class ImageResizeHelper {
  static const int maxDimension = 800;
  static const int paymentMaxDimension = 1280;
  static const int jpegQuality = 85;

  /// Returns a temp JPEG with longest side ≤ [maxSide].
  /// Returns original file if resize fails.
  static Future<File> resizeCoachPhoto(
    File source, {
    int maxSide = maxDimension,
    int quality = jpegQuality,
  }) async {
    try {
      final bytes = await source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return source;

      final img.Image resized;
      if (decoded.width <= maxSide && decoded.height <= maxSide) {
        resized = decoded;
      } else if (decoded.width >= decoded.height) {
        resized = img.copyResize(
          decoded,
          width: maxSide,
          interpolation: img.Interpolation.linear,
        );
      } else {
        resized = img.copyResize(
          decoded,
          height: maxSide,
          interpolation: img.Interpolation.linear,
        );
      }

      final encoded = img.encodeJpg(resized, quality: quality);
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

  /// Payment screenshots: slightly higher max than avatars for readability.
  static Future<File> resizePaymentScreenshot(File source) {
    return resizeCoachPhoto(
      source,
      maxSide: paymentMaxDimension,
      quality: jpegQuality,
    );
  }
}
