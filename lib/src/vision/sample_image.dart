import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A generated photo of a labelled jar, used only in debug builds when no
/// camera exists (the iOS simulator). It lets the full pipeline, including
/// OCR, run without a phone. Never used in release builds.
class SampleImage {
  /// JPEG of a jar with [label] printed on it.
  static Future<Uint8List> jar(String label) => Isolate.run(() => _draw(label));

  static Uint8List _draw(String label) {
    final image = img.Image(width: 900, height: 1200);
    img.fill(image, color: img.ColorRgb8(196, 170, 140)); // table
    img.fillRect(
      image,
      x1: 250,
      y1: 200,
      x2: 650,
      y2: 1000,
      color: img.ColorRgb8(120, 60, 30),
      radius: 40,
    ); // jar
    img.fillRect(
      image,
      x1: 240,
      y1: 140,
      x2: 660,
      y2: 230,
      color: img.ColorRgb8(200, 30, 30),
      radius: 12,
    ); // red lid
    img.fillRect(
      image,
      x1: 280,
      y1: 450,
      x2: 620,
      y2: 700,
      color: img.ColorRgb8(250, 250, 245),
    ); // label
    img.drawString(
      image,
      label,
      font: img.arial48,
      x: 330,
      y: 545,
      color: img.ColorRgb8(10, 10, 10),
    );
    return img.encodeJpg(image, quality: 90);
  }
}
