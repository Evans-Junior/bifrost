import 'dart:typed_data';

import 'geometry.dart';

/// Pixel layout of a camera frame.
enum FrameFormat {
  /// Android: Y plane first (one byte per pixel).
  nv21,

  /// iOS: 4 bytes per pixel, blue-green-red-alpha.
  bgra8888,
}

/// A small upright brightness (luma) image used for the glare and blur
/// checks (Section 5). Built by sampling the camera frame, so the checks
/// cost a few thousand operations per frame.
class LumaGrid {
  LumaGrid(this.width, this.height, this.values)
    : assert(values.length == width * height);

  final int width;
  final int height;

  /// Row-major luma values, 0–255.
  final Uint8List values;

  int at(int x, int y) => values[y * width + x];

  /// Samples a camera plane into an upright grid whose long side is about
  /// [targetLong] pixels.
  ///
  /// [rotationDegrees] is how far the raw frame must turn clockwise to be
  /// upright (Android's rear camera is usually 90; iOS frames are already
  /// upright, so 0).
  factory LumaGrid.fromPlane({
    required Uint8List bytes,
    required int rawWidth,
    required int rawHeight,
    required int bytesPerRow,
    required FrameFormat format,
    required int rotationDegrees,
    int targetLong = 240,
  }) {
    final turned = rotationDegrees == 90 || rotationDegrees == 270;
    final upW = turned ? rawHeight : rawWidth;
    final upH = turned ? rawWidth : rawHeight;
    final long = upW > upH ? upW : upH;
    final step = (long / targetLong).ceil().clamp(1, 1 << 20);
    final gw = upW ~/ step;
    final gh = upH ~/ step;
    final out = Uint8List(gw * gh);

    int luma(int x, int y) {
      if (format == FrameFormat.nv21) return bytes[y * bytesPerRow + x];
      final i = y * bytesPerRow + x * 4;
      // BT.601 weights in integer form.
      return (29 * bytes[i] + 150 * bytes[i + 1] + 77 * bytes[i + 2]) >> 8;
    }

    for (var gy = 0; gy < gh; gy++) {
      for (var gx = 0; gx < gw; gx++) {
        final ux = gx * step;
        final uy = gy * step;
        int rx, ry;
        switch (rotationDegrees) {
          case 90: // upright (ux, uy) <- raw (uy, rawHeight-1-ux)
            rx = uy;
            ry = rawHeight - 1 - ux;
          case 180:
            rx = rawWidth - 1 - ux;
            ry = rawHeight - 1 - uy;
          case 270:
            rx = rawWidth - 1 - uy;
            ry = ux;
          default:
            rx = ux;
            ry = uy;
        }
        out[gy * gw + gx] = luma(rx, ry);
      }
    }
    return LumaGrid(gw, gh, out);
  }
}

/// Glare and blur measurements (Section 5). Pure functions, unit-tested.
class LumaMetrics {
  /// Fraction of pixels inside [box] (whole frame if null) with luma at or
  /// above [saturated].
  static double glareFraction(LumaGrid g, NormBox? box, {int saturated = 250}) {
    final x0 = ((box?.left ?? 0) * g.width).floor().clamp(0, g.width - 1);
    final y0 = ((box?.top ?? 0) * g.height).floor().clamp(0, g.height - 1);
    final x1 = ((box?.right ?? 1) * g.width).ceil().clamp(x0 + 1, g.width);
    final y1 = ((box?.bottom ?? 1) * g.height).ceil().clamp(y0 + 1, g.height);
    var bright = 0;
    var total = 0;
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        total++;
        if (g.at(x, y) >= saturated) bright++;
      }
    }
    return total == 0 ? 0 : bright / total;
  }

  /// Variance of the 4-neighbour Laplacian. Low values mean a blurry image.
  static double laplacianVariance(LumaGrid g) {
    if (g.width < 3 || g.height < 3) return 0;
    var sum = 0.0;
    var sumSq = 0.0;
    var n = 0;
    for (var y = 1; y < g.height - 1; y++) {
      for (var x = 1; x < g.width - 1; x++) {
        final lap =
            g.at(x - 1, y) +
            g.at(x + 1, y) +
            g.at(x, y - 1) +
            g.at(x, y + 1) -
            4 * g.at(x, y);
        sum += lap;
        sumSq += lap * lap;
        n++;
      }
    }
    final mean = sum / n;
    return sumSq / n - mean * mean;
  }
}
