import 'dart:math' as math;

/// A box in normalized, upright image coordinates: 0–1 from the top-left
/// corner of the frame as the user holds the phone (portrait). With the rear
/// camera facing away from the user, image left is the user's left.
class NormBox {
  const NormBox(this.left, this.top, this.width, this.height);

  /// From the schema's `[x, y, width, height]`.
  factory NormBox.fromList(List<double> v) => NormBox(v[0], v[1], v[2], v[3]);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;
  double get area => width * height;

  /// Intersection over union with [o].
  double iou(NormBox o) {
    final w = math.min(right, o.right) - math.max(left, o.left);
    final h = math.min(bottom, o.bottom) - math.max(top, o.top);
    if (w <= 0 || h <= 0) return 0;
    final inter = w * h;
    return inter / (area + o.area - inter);
  }

  /// True if the whole box is inside the frame with [margin] on every side.
  bool insideWithMargin(double margin) =>
      left >= margin &&
      top >= margin &&
      right <= 1 - margin &&
      bottom <= 1 - margin;

  List<double> toList() => [left, top, width, height];

  @override
  String toString() =>
      'NormBox(${left.toStringAsFixed(2)}, ${top.toStringAsFixed(2)}, '
      '${width.toStringAsFixed(2)}, ${height.toStringAsFixed(2)})';
}

/// Converts an ML Kit bounding box in image pixels to a [NormBox].
///
/// Follows the official google_ml_kit_flutter example
/// (`coordinates_translator.dart`) for a portrait screen and the rear camera:
/// with a 90° or 270° rotation, Android boxes are scaled by the swapped
/// image size while iOS boxes use the frame's own size; 270° is mirrored.
NormBox normalizeDetection({
  required double left,
  required double top,
  required double width,
  required double height,
  required double imageWidth,
  required double imageHeight,
  required int rotationDegrees,
  required bool isIOS,
}) {
  double nx(double x) {
    switch (rotationDegrees) {
      case 90:
        return x / (isIOS ? imageWidth : imageHeight);
      case 270:
        return 1 - x / (isIOS ? imageWidth : imageHeight);
      default:
        return x / imageWidth;
    }
  }

  double ny(double y) {
    switch (rotationDegrees) {
      case 90:
      case 270:
        return y / (isIOS ? imageHeight : imageWidth);
      default:
        return y / imageHeight;
    }
  }

  final x1 = nx(left);
  final x2 = nx(left + width);
  final y1 = ny(top);
  final y2 = ny(top + height);
  final l = math.min(x1, x2).clamp(0.0, 1.0);
  final r = math.max(x1, x2).clamp(0.0, 1.0);
  final t = math.min(y1, y2).clamp(0.0, 1.0);
  final b = math.max(y1, y2).clamp(0.0, 1.0);
  return NormBox(l, t, r - l, b - t);
}
