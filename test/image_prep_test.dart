import 'dart:convert';

import 'package:bifrost/src/vision/image_prep.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('large stills are resized to a 1024 px long side', () {
    final src = img.Image(width: 3000, height: 2000);
    final out = ImagePrep.resizeSync(img.encodeJpg(src));
    final decoded = img.decodeJpg(base64Decode(out))!;
    expect(decoded.width, 1024);
    expect(decoded.height, closeTo(683, 1));
  });

  test('portrait stills keep orientation', () {
    final src = img.Image(width: 1500, height: 4000);
    final decoded =
        img.decodeJpg(base64Decode(ImagePrep.resizeSync(img.encodeJpg(src))))!;
    expect(decoded.height, 1024);
  });

  test('small stills are not upscaled', () {
    final src = img.Image(width: 640, height: 480);
    final decoded =
        img.decodeJpg(base64Decode(ImagePrep.resizeSync(img.encodeJpg(src))))!;
    expect(decoded.width, 640);
  });
}
