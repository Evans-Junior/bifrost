import 'package:bifrost/src/model/response_parser.dart';
import 'package:bifrost/src/model/vlm_response.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const parser = ResponseParser();

  test('parses a full schema response', () {
    final r = parser.parse(modelFixture('labelled_jar_read.json'));
    expect(r.referent!.label, 'jar 1');
    expect(r.referent!.bbox, [0.4, 0.3, 0.2, 0.4]);
    expect(r.evidence, Evidence.read);
    expect(r.confidence, Confidence.read);
    expect(r.registryUpdates.single.identifiedAs, 'CUMIN');
  });

  test('accepts a Markdown code fence around the JSON', () {
    final raw = '```json\n${modelFixture('label_away_clean.json')}\n```';
    expect(parser.parse(raw).confidence, Confidence.cantSee);
  });

  test('integer bbox values are accepted', () {
    final r = parser.parse(
      '{"needs_clarification": false, '
      '"referent": {"id": "a", "label": "item 1", "bbox": [0, 0, 1, 1]}, '
      '"evidence": "SEEN", "confidence": "THINK"}',
    );
    expect(r.referent!.bbox, [0.0, 0.0, 1.0, 1.0]);
    expect(r.observation, isEmpty);
  });

  test('null referent is allowed for clarification', () {
    final r = parser.parse(modelFixture('two_jars_clarify.json'));
    expect(r.needsClarification, isTrue);
    expect(r.referent, isNull);
  });

  test('truncated JSON is rejected', () {
    expect(
      () => parser.parse(modelFixture('invalid_truncated.txt')),
      throwsA(isA<SchemaException>()),
    );
  });

  test('missing confidence is rejected', () {
    expect(
      () => parser.parse('{"needs_clarification": false, "evidence": "READ"}'),
      throwsA(isA<SchemaException>()),
    );
  });

  test('unknown confidence value is rejected', () {
    expect(
      () => parser.parse(
        '{"needs_clarification": false, '
        '"evidence": "READ", "confidence": "SURE"}',
      ),
      throwsA(isA<SchemaException>()),
    );
  });

  test('wrong field type is rejected', () {
    expect(
      () => parser.parse(
        '{"needs_clarification": "no", '
        '"evidence": "READ", "confidence": "READ"}',
      ),
      throwsA(isA<SchemaException>()),
    );
  });

  test('plain text is rejected', () {
    expect(() => parser.parse('It is cumin.'), throwsA(isA<SchemaException>()));
  });
}
