import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A still ready for the model and for OCR: orientation baked in, long side
/// about 1024 px, JPEG quality 80.
class PreparedImage {
  const PreparedImage(this.jpeg, this.width, this.height);

  final Uint8List jpeg;
  final int width;
  final int height;

  String get base64 => base64Encode(jpeg);
}

/// Resizes a captured still for the model (Section 4). Runs in a separate
/// isolate so the UI never blocks.
class ImagePrep {
  static const longSide = 1024;
  static const jpegQuality = 80;

  /// Resizes and encodes [bytes] off the UI isolate.
  static Future<PreparedImage> prepare(Uint8List bytes) =>
      Isolate.run(() => prepareSync(bytes));

  /// Synchronous version, used inside the isolate and in tests.
  static PreparedImage prepareSync(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('unreadable image');
    final resized = _fit(img.bakeOrientation(decoded));
    return PreparedImage(
      img.encodeJpg(resized, quality: jpegQuality),
      resized.width,
      resized.height,
    );
  }

  static img.Image _fit(img.Image image) {
    final long = image.width > image.height ? image.width : image.height;
    if (long <= longSide) return image;
    return image.width >= image.height
        ? img.copyResize(image, width: longSide)
        : img.copyResize(image, height: longSide);
  }
}
