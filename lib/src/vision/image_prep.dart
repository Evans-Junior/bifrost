import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Resizes a captured still for the model (Section 4): long side about
/// 1024 px, JPEG quality 80, returned as base64. Runs in a separate isolate
/// so the UI never blocks.
class ImagePrep {
  static const longSide = 1024;
  static const jpegQuality = 80;

  /// Resizes and encodes [bytes] off the UI isolate.
  static Future<String> toModelJpegBase64(Uint8List bytes) =>
      Isolate.run(() => resizeSync(bytes));

  /// Synchronous version, used inside the isolate and in tests.
  static String resizeSync(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('unreadable image');
    final oriented = img.bakeOrientation(decoded);
    final resized = _fit(oriented);
    return base64Encode(img.encodeJpg(resized, quality: jpegQuality));
  }

  static img.Image _fit(img.Image image) {
    final long = image.width > image.height ? image.width : image.height;
    if (long <= longSide) return image;
    return image.width >= image.height
        ? img.copyResize(image, width: longSide)
        : img.copyResize(image, height: longSide);
  }
}
