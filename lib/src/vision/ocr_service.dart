import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import 'ocr_result.dart';

/// On-device text recognition with Google ML Kit (Latin script, which
/// covers French). Runs on the same resized still that is sent to the
/// model, so OCR and model see exactly the same pixels.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Reads text in [jpeg] (already orientation-corrected) of size
  /// [width] x [height]. Returns [OcrResult.empty] on any failure, which the
  /// cross-check treats as "no text confirmed".
  Future<OcrResult> readJpeg(Uint8List jpeg, int width, int height) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/bifrost_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    try {
      await file.writeAsBytes(jpeg, flush: true);
      final text = await _recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      return OcrResult([
        for (final block in text.blocks)
          for (final line in block.lines)
            OcrLine(
              line.text,
              left: (line.boundingBox.left / width).clamp(0.0, 1.0),
              top: (line.boundingBox.top / height).clamp(0.0, 1.0),
              width: (line.boundingBox.width / width).clamp(0.0, 1.0),
              height: (line.boundingBox.height / height).clamp(0.0, 1.0),
            ),
      ]);
    } catch (e) {
      debugPrint('[ocr] failed: $e');
      return OcrResult.empty;
    } finally {
      // No image is kept on the device.
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> close() => _recognizer.close();
}
