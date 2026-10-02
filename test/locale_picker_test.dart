import 'package:bifrost/src/speech/locale_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact match keeps the device spelling', () {
    expect(LocalePicker.pick('fr_CA', ['en_US', 'fr_CA']), 'fr_CA');
    expect(LocalePicker.pick('fr-CA', ['fr_CA']), 'fr_CA');
  });

  test('missing fr-CA falls back to fr-FR before other regions', () {
    expect(LocalePicker.pick('fr-CA', ['fr-CH', 'en-US', 'fr-FR']), 'fr-FR');
  });

  test('any region of the language beats nothing', () {
    expect(LocalePicker.pick('fr-CA', ['en-US', 'fr-LU']), 'fr-LU');
  });

  test('a bare language code is accepted', () {
    expect(LocalePicker.pick('fr-CA', ['en', 'fr']), 'fr');
  });

  test('returns null when the language is absent', () {
    expect(LocalePicker.pick('fr-CA', ['en-US', 'es-ES']), isNull);
  });

  test('English prefers en-CA, then en-US', () {
    expect(LocalePicker.pick('en-CA', ['en-GB', 'en-US']), 'en-US');
  });
}
