import '../text/text_normalize.dart';

/// One line of text found by on-device OCR, with its box normalized to
/// 0–1 from the top-left corner of the image.
class OcrLine {
  const OcrLine(
    this.text, {
    this.left = 0,
    this.top = 0,
    this.width = 0,
    this.height = 0,
  });

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;

  /// A rough position word pair for the prompt, e.g. "top left".
  String get roughPosition {
    final cx = left + width / 2;
    final cy = top + height / 2;
    final h = cx < 0.33 ? 'left' : (cx > 0.66 ? 'right' : 'center');
    final v = cy < 0.33 ? 'top' : (cy > 0.66 ? 'bottom' : 'middle');
    return '$v $h';
  }

  factory OcrLine.fromJson(Map<String, dynamic> j) => OcrLine(
    j['text'] as String,
    left: (j['left'] as num?)?.toDouble() ?? 0,
    top: (j['top'] as num?)?.toDouble() ?? 0,
    width: (j['width'] as num?)?.toDouble() ?? 0,
    height: (j['height'] as num?)?.toDouble() ?? 0,
  );
}

/// Text that on-device OCR found in one image. Never leaves the phone
/// except as the `OCR_TEXT` block of the model request.
class OcrResult {
  const OcrResult(this.lines);

  static const empty = OcrResult([]);

  final List<OcrLine> lines;

  bool get isEmpty => lines.isEmpty;

  /// Normalized word tokens (Section 5): uppercase, no accents.
  Set<String> get tokens => {
    for (final l in lines) ...TextNormalize.labelWords(l.text),
  };

  /// Normalized full lines, for whole-phrase matching.
  List<String> get normalizedLines => [
    for (final l in lines)
      if (TextNormalize.label(l.text).isNotEmpty) TextNormalize.label(l.text),
  ];

  /// The `OCR_TEXT` block sent to the model.
  List<Map<String, dynamic>> toPrompt() => [
    for (final l in lines) {'text': l.text, 'position': l.roughPosition},
  ];

  factory OcrResult.fromJson(List<dynamic> j) => OcrResult([
    for (final e in j) OcrLine.fromJson(e as Map<String, dynamic>),
  ]);
}
