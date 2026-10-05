// Section 16 scripted acceptance test, run on recorded fixtures (Phase 2).
// Steps 3 (watch mode), 10 (glare) and 11 (vibration guidance) need the
// Phase 3 camera stream and are not covered here.

import 'dart:convert';
import 'dart:io';

import 'package:bifrost/src/conversation/conversation_engine.dart';
import 'package:bifrost/src/guards/banned_phrases.dart';
import 'package:bifrost/src/guards/guards.dart';
import 'package:bifrost/src/intent/intent_classifier.dart';
import 'package:bifrost/src/model/prompt_builder.dart';
import 'package:bifrost/src/model/vlm_response.dart';
import 'package:bifrost/src/settings/app_settings.dart';
import 'package:bifrost/src/turn/turn_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _spices = ['cumin', 'paprika', 'oregano', 'chili', 'turmeric'];

/// Drives the engine one utterance at a time with scripted model replies
/// and OCR results.
class _Script {
  _Script(this.lang, {this.noun = 'jar'})
    : settings = testSettings.copyWith(language: lang),
      classifier = classifierFor(lang.code);

  final AppLanguage lang;
  final String noun;
  final AppSettings settings;
  final IntentClassifier classifier;
  final List<Object> _replies = [];
  late final client = FakeModelClient(_replies);
  late final engine = ConversationEngine(
    TurnPipeline(
      client: client,
      prompts: PromptBuilder(FilePromptAssets()),
      busyRetryDelay: Duration.zero,
      guards: Guards(
        banned: BannedPhrases.fromJson(
          jsonDecode(
                File('assets/guards/banned_phrases.json').readAsStringSync(),
              )
              as Map<String, dynamic>,
        ),
      ),
    ),
  );

  /// Says [utterance]. [fixture] is the model reply (null for local
  /// intents); [ocr] is what on-device OCR reads in the still.
  Future<EngineReply> say(
    String utterance, {
    String? fixture,
    String? retryFixture,
    List<String> ocr = const [],
  }) {
    for (final f in [?fixture, ?retryFixture]) {
      _replies.add(scriptFixture(f).replaceAll('jar', noun));
    }
    return engine.handle(
      transcript: utterance,
      settings: settings,
      classifier: classifier,
      capture: () async => CapturedFrame('AAAA', ocrOf(ocr)),
    );
  }

  /// The user text of the most recent model request.
  String get lastRequestText {
    final content = client.requests.last[1]['content'] as List;
    return content.first['text'] as String;
  }
}

void main() {
  group('English script', () {
    late _Script s;
    setUp(() => s = _Script(AppLanguage.en));

    Future<void> setupSorting() async {
      await s.say('Help me sort these spices.', fixture: 's01_start_task.json');
    }

    test('1. start task registers 5 jars labelled 1-5 left to right', () async {
      final r = await s.say(
        'Help me sort these spices.',
        fixture: 's01_start_task.json',
      );
      expect(r.intent.type, IntentType.startTask);
      expect(r.intent.task, 'sort');
      final labels = [for (final o in s.engine.state.registry.objects) o.label];
      expect(labels, ['jar 1', 'jar 2', 'jar 3', 'jar 4', 'jar 5']);
      expect(r.text, startsWith('5 items, numbered from left to right.'));
      expect(s.lastRequestText, contains('INTENT: START_TASK'));
    });

    test(
      '2. label away: referent + CANT_SEE + turn instruction, no spice',
      () async {
        await setupSorting();
        final r = await s.say("What's this?", fixture: 's02_label_away.json');
        expect(r.confidence, Confidence.cantSee);
        expect(r.text, startsWith('Jar 2, in your right hand.'));
        expect(r.text, contains("I can't see"));
        expect(r.text, contains('Turn it a quarter turn.'));
        for (final spice in _spices) {
          expect(r.text.toLowerCase(), isNot(contains(spice)));
        }
      },
    );

    test('4. challenge: keeps CUMIN and states the evidence', () async {
      await setupSorting();
      await s.say(
        "What's this?",
        fixture: 's03_read_cumin.json',
        ocr: ['CUMIN'],
      );
      final r = await s.say(
        "Are you sure it's not paprika?",
        fixture: 's04_challenge_hold.json',
        ocr: ['CUMIN'],
      );
      expect(r.intent.type, IntentType.challenge);
      expect(r.outcome!.challenge, ChallengeOutcome.held);
      expect(r.outcome!.response!.answerChanged, isFalse);
      expect(
        r.text,
        'Jar 2, in your right hand. I still read Cumin on this one.',
      );
      expect(s.lastRequestText, contains('PREVIOUS_ANSWER'));
    });

    test('4b. challenge: unconfirmed flip to PAPRIKA is rejected', () async {
      await setupSorting();
      await s.say(
        "What's this?",
        fixture: 's03_read_cumin.json',
        ocr: ['CUMIN'],
      );
      final r = await s.say(
        "I think it's paprika.",
        fixture: 's04b_challenge_flip_unconfirmed.json',
        ocr: ['CUMIN'],
      );
      expect(r.outcome!.challenge, ChallengeOutcome.rejected);
      expect(r.text, contains('I still read Cumin'));
      expect(r.text.toLowerCase(), isNot(contains('paprika')));
      expect(s.engine.state.registry.byNumber(2)!.identifiedAs, 'CUMIN');
    });

    test('4c. challenge: OCR-confirmed change is accepted plainly', () async {
      await setupSorting();
      await s.say(
        "What's this?",
        fixture: 's03_read_cumin.json',
        ocr: ['CUMIN'],
      );
      final r = await s.say(
        'Are you sure?',
        fixture: 's04c_challenge_flip_confirmed.json',
        ocr: ['PAPRIKA'],
      );
      expect(r.outcome!.challenge, ChallengeOutcome.accepted);
      expect(r.text, contains('Now I read Paprika. I was wrong before.'));
      expect(s.engine.state.registry.byNumber(2)!.identifiedAs, 'PAPRIKA');
    });

    test(
      '5. model claims CHILI, OCR reads nothing: downgraded to THINK',
      () async {
        await setupSorting();
        final r = await s.say(
          "What's this?",
          fixture: 's05_chili_invented.json',
        );
        expect(r.confidence, Confidence.think);
        expect(r.text, contains('because the label is hard to read'));
        expect(
          r.outcome!.guardEvents.map((e) => e.guard),
          contains('ocr_cross_check'),
        );
      },
    );

    test('6. thumb over the label: THINK + reason + move your thumb', () async {
      await setupSorting();
      final r = await s.say(
        "What's this?",
        fixture: 's06_thumb.json',
        ocr: ['TUR'],
      );
      expect(r.confidence, Confidence.think);
      expect(r.text, contains('because your thumb covers part of the label'));
      expect(r.text, contains('Move your thumb'));
    });

    test(
      '7-8. either/or question, then "the closer one" answers directly',
      () async {
        await setupSorting();
        final q = await s.say('Is this oregano?', fixture: 's07_clarify.json');
        expect(q.isClarification, isTrue);
        expect(q.text, 'the jar closer to you or the jar further away?');

        final a = await s.say(
          'The closer one.',
          fixture: 's08_repair_closer.json',
          ocr: ['OREGANO'],
        );
        expect(a.intent.type, IntentType.repair);
        expect(a.isClarification, isFalse);
        expect(a.text, startsWith('Jar 4, closer to you, on the right.'));
        expect(a.text, contains('I read this directly.'));
        expect(
          s.lastRequestText,
          contains('"description":"the jar closer to you"'),
        );
        expect(s.lastRequestText, contains('INTENT: REPAIR'));
      },
    );

    test('guard 5: three options are retried once, then cut to two', () async {
      await setupSorting();
      final calls = s.client.requests.length;
      final q = await s.say(
        'Is this oregano?',
        fixture: 's07b_clarify_three.json',
        retryFixture: 's07b_clarify_three.json',
      );
      expect(s.client.requests.length, calls + 2, reason: 'one retry');
      expect(
        s.client.requests.last.last['content'],
        contains('exactly two options'),
      );
      expect(q.isClarification, isTrue);
      expect(q.text, 'jar 1 or jar 4?');
    });

    test(
      '9. status is answered locally with correct done and left lists',
      () async {
        await setupSorting();
        await s.say(
          "What's this?",
          fixture: 's03_read_cumin.json',
          ocr: ['CUMIN'],
        );
        await s.say('Is this oregano?', fixture: 's07_clarify.json');
        await s.say(
          'The closer one.',
          fixture: 's08_repair_closer.json',
          ocr: ['OREGANO'],
        );
        await s.say("What's this?", fixture: 's05_chili_invented.json');
        final calls = s.client.requests.length;

        final r = await s.say('What have I done so far?');
        expect(r.intent.type, IntentType.status);
        expect(r.usedModel, isFalse);
        expect(s.client.requests.length, calls, reason: 'no model call');
        expect(
          r.text,
          'Done: jar 2 is Cumin and jar 4 is Oregano. Left: jar 1; jar 3 and jar 5.',
        );
      },
    );

    test('repair by number sends the chosen object', () async {
      await setupSorting();
      await s.say('item 3', fixture: 's05_chili_invented.json');
      expect(s.lastRequestText, contains('CHOSEN_REFERENT: {"id":"jar_3"'));
    });

    test('unknown object id gets the next sequential label', () async {
      await setupSorting();
      final r = await s.say("What's behind it?", fixture: 's_unknown_id.json');
      expect(r.text, startsWith('Bottle 6, behind jar 3.'));
      expect(s.engine.state.registry.byNumber(6)!.label, 'bottle 6');
    });

    test('banned phrases never reach speech', () async {
      await setupSorting();
      final r = await s.say("What's this?", fixture: 's_banned.json');
      expect(r.text.toLowerCase(), isNot(contains('as you can see')));
      expect(r.text.toLowerCase(), isNot(contains('check the label')));
    });

    test('REPEAT and MORE are local', () async {
      await setupSorting();
      final a = await s.say(
        "What's this?",
        fixture: 's03_read_cumin.json',
        ocr: ['CUMIN'],
      );
      final calls = s.client.requests.length;
      expect((await s.say('Say that again')).text, a.text);
      expect((await s.say('Tell me more')).text, 'Ground cumin, 45 grams.');
      expect(s.client.requests.length, calls);
    });

    test('STOP is local and short', () async {
      final r = await s.say('Stop');
      expect(r.intent.type, IntentType.stop);
      expect(r.text, 'Stopped.');
      expect(s.client.requests, isEmpty);
    });

    test('status right after starting a task with nothing labelled', () async {
      await s.say('Help me sort these.', fixture: 's07_clarify.json');
      expect(
        (await s.say("What's left?")).text,
        startsWith('No items labelled yet.'),
      );
    });

    test('status before any task', () async {
      expect((await s.say("What's left?")).text, startsWith('No task yet.'));
    });
  });

  group('French script', () {
    late _Script s;
    setUp(() => s = _Script(AppLanguage.fr, noun: 'pot'));

    test('the same conversation passes in French', () async {
      final start = await s.say(
        'Aide-moi à trier ces épices.',
        fixture: 's01_start_task.json',
      );
      expect(start.text, startsWith('5 objets, numérotés de gauche à droite.'));

      final away = await s.say(
        "C'est quoi ça ?",
        fixture: 's02_label_away.json',
      );
      expect(away.text, contains('Je ne vois pas assez bien pour le dire.'));

      await s.say(
        "C'est quoi ça ?",
        fixture: 's03_read_cumin.json',
        ocr: ['CUMIN'],
      );
      final hold = await s.say(
        "Es-tu sûr que ce n'est pas du paprika ?",
        fixture: 's04b_challenge_flip_unconfirmed.json',
        ocr: ['CUMIN'],
      );
      expect(hold.intent.type, IntentType.challenge);
      expect(hold.text, contains('Je lis toujours Cumin sur celui-ci.'));

      final chili = await s.say(
        "C'est quoi ça ?",
        fixture: 's05_chili_invented.json',
      );
      expect(
        chili.text,
        contains("parce que l'étiquette est difficile à lire"),
      );

      await s.say("Est-ce que c'est l'origan ?", fixture: 's07_clarify.json');
      final repair = await s.say(
        'Le plus proche.',
        fixture: 's08_repair_closer.json',
        ocr: ['OREGANO'],
      );
      expect(repair.intent.type, IntentType.repair);
      expect(repair.isClarification, isFalse);

      final status = await s.say("Qu'est-ce que j'ai fait ?");
      expect(status.usedModel, isFalse);
      expect(
        status.text,
        'Fait : pot 2 : Cumin et pot 4 : Oregano. Reste : pot 1; pot 3 et pot 5.',
      );
    });
  });
}

/// Reads a scripted-test model reply.
String scriptFixture(String name) => jsonFixtureText('script/$name');
