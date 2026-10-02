import 'package:bifrost/src/vision/image_prep.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('large stills are resized to a 1024 px long side', () {
    final out = ImagePrep.prepareSync(
      img.encodeJpg(img.Image(width: 3000, height: 2000)),
    );
    expect(out.width, 1024);
    expect(out.height, closeTo(683, 1));
    expect(img.decodeJpg(out.jpeg)!.width, 1024);
    expect(out.base64, isNotEmpty);
  });

  test('portrait stills keep orientation', () {
    final out = ImagePrep.prepareSync(
      img.encodeJpg(img.Image(width: 1500, height: 4000)),
    );
    expect(out.height, 1024);
  });

  test('small stills are not upscaled', () {
    final out = ImagePrep.prepareSync(
      img.encodeJpg(img.Image(width: 640, height: 480)),
    );
    expect(out.width, 640);
  });
}
