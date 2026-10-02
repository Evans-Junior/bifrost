import 'dart:convert';

import 'package:bifrost/src/conversation/conversation_engine.dart';
import 'package:bifrost/src/intent/intent_classifier.dart';
import 'package:bifrost/src/logging/turn_logger.dart';
import 'package:bifrost/src/model/prompt_builder.dart';
import 'package:bifrost/src/turn/turn_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('log entry has the Section 13 fields and no image', () async {
    final engine = ConversationEngine(
      TurnPipeline(
        client: FakeModelClient([modelFixture('labelled_jar_read.json')]),
        prompts: PromptBuilder(FilePromptAssets()),
      ),
    );
    final reply = await engine.handle(
      transcript: "What's this?",
      settings: testSettings,
      classifier: classifierFor('en'),
      capture: () async =>
          CapturedFrame('SECRET_IMAGE_BYTES', ocrOf(['CUMIN'])),
    );
    final release = DateTime.utc(2026, 10, 2, 12);
    final times = TurnTimes(release)
      ..firstAudio = release.add(const Duration(milliseconds: 1500))
      ..fullAnswer = release.add(const Duration(milliseconds: 3200))
      ..speechEnd = release.add(const Duration(seconds: 5));

    final logger = TurnLogger(sessionId: 's1');
    final e = logger.entry(
      transcript: "What's this?",
      reply: reply,
      state: engine.state,
      settings: testSettings,
      times: times,
    );

    expect(e['session_id'], 's1');
    expect(e['intent'], IntentType.ask.wire);
    expect(e['confidence'], 'READ');
    expect(e['latency_ms'], {'first_audio': 1500, 'full_answer': 3200});
    expect(e['ocr_tokens'], ['CUMIN']);
    expect(e['spoken_text'], startsWith('Jar 1'));
    expect((e['raw_model'] as List).single, contains('"CUMIN"'));
    expect((e['registry'] as List).single['identified_as'], 'CUMIN');
    expect(e['turn_index'], 0);
    expect(
      logger.entry(
        transcript: 'x',
        reply: reply,
        state: engine.state,
        settings: testSettings,
        times: times,
      )['turn_index'],
      1,
    );

    final text = jsonEncode(e);
    expect(
      text,
      isNot(contains('SECRET_IMAGE_BYTES')),
      reason: 'no images in logs',
    );
  });

  test('local turns are logged without model data', () async {
    final engine = ConversationEngine(
      TurnPipeline(
        client: FakeModelClient([]),
        prompts: PromptBuilder(FilePromptAssets()),
      ),
    );
    final reply = await engine.handle(
      transcript: 'stop',
      settings: testSettings,
      classifier: classifierFor('en'),
      capture: () async => null,
    );
    final e = TurnLogger(sessionId: 's').entry(
      transcript: 'stop',
      reply: reply,
      state: engine.state,
      settings: testSettings,
      times: TurnTimes(DateTime.now()),
    );
    expect(e['used_model'], isFalse);
    expect(e['intent'], 'STOP');
    expect(e['raw_model'], isEmpty);
    jsonEncode(e); // serializable
  });
}
