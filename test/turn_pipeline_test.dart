import 'package:bifrost/src/model/model_client.dart';
import 'package:bifrost/src/model/prompt_builder.dart';
import 'package:bifrost/src/model/vlm_response.dart';
import 'package:bifrost/src/settings/app_settings.dart';
import 'package:bifrost/src/turn/turn_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _spices = ['cumin', 'paprika', 'oregano', 'chili', 'cinnamon'];

TurnPipeline _pipeline(FakeModelClient client) =>
    TurnPipeline(client: client, prompts: PromptBuilder(FilePromptAssets()));

void main() {
  group('Phase 1 acceptance (fixtures)', () {
    test(
      'labelled jar: starts with a referent, includes confidence phrase',
      () async {
        final client = FakeModelClient([
          modelFixture('labelled_jar_read.json'),
        ]);
        final o = await _pipeline(
          client,
        ).run(testSettings, askInput(ocr: ocrOf(['CUMIN', 'Ground 45 g'])));
        expect(o.isSuccess, isTrue);
        expect(o.spokenText, startsWith('Jar 1, in your right hand.'));
        expect(o.spokenText, contains(l10nFor('en').confidenceRead));
      },
    );

    test('label turned away: CANT_SEE + action, never a spice name', () async {
      for (final fixture in [
        'label_away_clean.json',
        'label_away_leaky.json',
      ]) {
        final client = FakeModelClient([modelFixture(fixture)]);
        final o = await _pipeline(client).run(testSettings, askInput());
        expect(o.response!.confidence, Confidence.cantSee, reason: fixture);
        expect(o.spokenText, startsWith('Jar 1'), reason: fixture);
        expect(o.spokenText, contains("I can't see"), reason: fixture);
        expect(o.spokenText, contains('Turn it'), reason: fixture);
        for (final spice in _spices) {
          expect(
            o.spokenText.toLowerCase(),
            isNot(contains(spice)),
            reason: '$fixture spoke $spice',
          );
          expect(
            o.reply!.detail.toLowerCase(),
            isNot(contains(spice)),
            reason: '$fixture kept $spice in detail',
          );
        }
      }
    });
  });

  group('validation and retry', () {
    test('invalid JSON is retried once with the retry instruction', () async {
      final client = FakeModelClient([
        modelFixture('invalid_truncated.txt'),
        modelFixture('labelled_jar_read.json'),
      ]);
      final o = await _pipeline(client).run(testSettings, askInput());
      expect(o.isSuccess, isTrue);
      expect(client.requests, hasLength(2));
      expect(client.requests[1].last['content'], 'Return only valid JSON.');
      expect(o.rawModelText, hasLength(2));
    });

    test('invalid JSON twice says "lost track"', () async {
      final client = FakeModelClient(['nope', 'still nope']);
      final o = await _pipeline(client).run(testSettings, askInput());
      expect(o.failure, TurnFailure.lostTrack);
      expect(o.spokenText, 'Sorry, I lost track. Ask again.');
      expect(client.requests, hasLength(2));
    });
  });

  group('honest system status', () {
    test('timeout speaks the timeout line', () async {
      final client = FakeModelClient([
        modelFixture('labelled_jar_read.json'),
      ], delay: const Duration(seconds: 3));
      final o = await _pipeline(
        client,
      ).run(testSettings.copyWith(timeoutS: 1), askInput());
      expect(o.failure, TurnFailure.timeout);
      expect(o.spokenText, "I couldn't get an answer. Try again.");
    });

    test('connection error says it cannot connect', () async {
      final client = FakeModelClient([ModelConnectionException('refused')]);
      final o = await _pipeline(client).run(testSettings, askInput());
      expect(o.failure, TurnFailure.connection);
      expect(o.spokenText, l10nFor('en').cannotConnect);
    });

    test('French settings give French status lines', () async {
      final client = FakeModelClient(['x', 'y']);
      final o = await _pipeline(
        client,
      ).run(testSettings.copyWith(language: AppLanguage.fr), askInput());
      expect(o.spokenText, l10nFor('fr').lostTrack);
    });
  });

  group('prompt building', () {
    final builder = PromptBuilder(FilePromptAssets());

    for (final lang in AppLanguage.values) {
      test('system prompt fills placeholders (${lang.code})', () async {
        final s = await builder.systemPrompt(
          testSettings.copyWith(
            language: lang,
            positionStyle: PositionStyle.clock,
          ),
        );
        expect(s, isNot(contains('{LANGUAGE}')));
        expect(s, isNot(contains('{POSITION_STYLE_INSTRUCTION}')));
        expect(s, contains(lang == AppLanguage.en ? "o'clock" : 'heures'));
        expect(s, contains('"needs_clarification"'));
        expect(
          s,
          contains(
            lang == AppLanguage.en
                ? 'The user is blind'
                : 'La personne est aveugle',
          ),
        );
      });
    }

    test('user message carries the context blocks and the image', () async {
      final msgs = await builder.messages(testSettings, testContext);
      final content = msgs[1]['content'] as List;
      final text = content[0]['text'] as String;
      for (final key in [
        'OBJECT_REGISTRY',
        'TASK_STATE',
        'RECENT_TURNS',
        'INTENT: ASK',
        'OCR_TEXT',
      ]) {
        expect(text, contains(key));
      }
      expect(content[1]['image_url']['url'], 'data:image/jpeg;base64,AAAA');
    });

    test('only the last 6 turns are sent', () {
      final turns = [
        for (var i = 0; i < 9; i++) PastTurn(user: 'q$i', assistant: 'a$i'),
      ];
      final text = builder.userText(
        TurnContext(
          transcript: 't',
          intent: 'ASK',
          imageBase64Jpeg: '',
          recentTurns: turns,
        ),
      );
      expect(text, isNot(contains('q2')));
      expect(text, contains('q3'));
      expect(text, contains('q8'));
    });
  });
}
