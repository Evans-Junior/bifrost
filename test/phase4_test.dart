// Phase 4 on fixtures: referent-first streaming, earcons, onboarding,
// vibration practice and feedback settings (Section 14).

import 'dart:io';

import 'package:bifrost/src/audio/earcons.dart';
import 'package:bifrost/src/conversation/object_registry.dart';
import 'package:bifrost/src/guidance/patterns.dart';
import 'package:bifrost/src/intent/intent_classifier.dart';
import 'package:bifrost/src/model/early_referent.dart';
import 'package:bifrost/src/model/prompt_builder.dart';
import 'package:bifrost/src/model/vlm_response.dart';
import 'package:bifrost/src/settings/app_settings.dart';
import 'package:bifrost/src/settings/settings_repository.dart';
import 'package:bifrost/src/turn/turn_pipeline.dart';
import 'package:bifrost/src/ui/learn_vibrations_screen.dart';
import 'package:bifrost/src/ui/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

TurnPipeline _pipeline(FakeModelClient c) => TurnPipeline(
  client: c,
  prompts: PromptBuilder(FilePromptAssets()),
  busyRetryDelay: Duration.zero,
);

TurnInput _input(
  IntentType intent,
  void Function(String) onEarly, {
  ObjectRegistry? registry,
  List<String> ocr = const ['CUMIN'],
}) => TurnInput(
  context: testContext,
  intent: intent,
  registry: registry ?? ObjectRegistry(),
  ocr: ocrOf(ocr),
  onEarlyReferent: onEarly,
);

void main() {
  group('partial JSON reader (Section 9)', () {
    final full = modelFixture('labelled_jar_read.json');

    test('finds the referent long before the reply is complete', () {
      final cut = full.indexOf('"evidence"');
      final early = EarlyReferentReader.parse(full.substring(0, cut));
      expect(early, isNotNull);
      expect(early!.needsClarification, isFalse);
      expect(early.referent!.label, 'jar 1');
    });

    test('waits while the referent object is incomplete', () {
      final cut = full.indexOf('"location"');
      expect(EarlyReferentReader.parse(full.substring(0, cut)), isNull);
    });

    test('braces inside strings do not confuse it', () {
      const s =
          '{"needs_clarification": false, "referent": {"id": "a", '
          '"label": "jar {1}", "location": "in \\"your\\" hand"}, "evid';
      expect(EarlyReferentReader.parse(s)!.referent!.label, 'jar {1}');
    });

    test('null referent and clarification are reported', () {
      final r = EarlyReferentReader.parse(
        '{"needs_clarification": true, "clarification_options": ["a","b"], '
        '"referent": null, "evid',
      );
      expect(r!.needsClarification, isTrue);
      expect(r.referent, isNull);
    });

    test('streamed chunk by chunk, it reports exactly once', () {
      final reader = EarlyReferentReader();
      var reports = 0;
      for (var i = 0; i < full.length; i += 7) {
        if (reader.feed(full.substring(i, (i + 7).clamp(0, full.length))) !=
            null) {
          reports++;
        }
      }
      expect(reports, 1);
    });
  });

  group('referent-first speech', () {
    test('ASK: referent spoken early, the rest after', () async {
      final spoken = <String>[];
      final o = await _pipeline(
        FakeModelClient([modelFixture('labelled_jar_read.json')]),
      ).run(testSettings, _input(IntentType.ask, spoken.add));
      expect(spoken, ['Jar 1, in your right hand.']);
      expect(o.earlyReferent, 'Jar 1, in your right hand.');
      expect(o.spokenAfterEarly, 'The label says cumin. I read this directly.');
      expect(o.spokenText, startsWith('Jar 1, in your right hand.'));
    });

    test('CHALLENGE never streams early', () async {
      final spoken = <String>[];
      final o = await _pipeline(
        FakeModelClient([modelFixture('labelled_jar_read.json')]),
      ).run(testSettings, _input(IntentType.challenge, spoken.add));
      expect(spoken, isEmpty);
      expect(o.earlyReferent, isNull);
    });

    test('clarifications never stream early', () async {
      final spoken = <String>[];
      await _pipeline(
        FakeModelClient([modelFixture('two_jars_clarify.json')]),
      ).run(testSettings, _input(IntentType.ask, spoken.add));
      expect(spoken, isEmpty);
    });

    test('an unknown object without a location waits', () async {
      final spoken = <String>[];
      final noLocation = modelFixture(
        'labelled_jar_read.json',
      ).replaceFirst('"location": "in your right hand"', '"location": ""');
      await _pipeline(
        FakeModelClient([noLocation]),
      ).run(testSettings, _input(IntentType.ask, spoken.add));
      expect(spoken, isEmpty);
    });

    test('a known object streams early with its registry label', () async {
      final registry = ObjectRegistry()
        ..resolve(modelId: 'jar_1', modelLabel: 'jar 1');
      final spoken = <String>[];
      final noLocation = modelFixture(
        'labelled_jar_read.json',
      ).replaceFirst('"location": "in your right hand"', '"location": ""');
      await _pipeline(FakeModelClient([noLocation])).run(
        testSettings,
        _input(IntentType.repair, spoken.add, registry: registry),
      );
      expect(spoken, ['Jar 1.']);
    });

    test(
      'if guards change the referent, the rest starts with "Correction:"',
      () async {
        // The first attempt streams jar 1, but is invalid JSON overall; the
        // retry names a different object.
        final first = modelFixture(
          'labelled_jar_read.json',
        ).replaceFirst('"answer_changed": false', '"answer_changed": oops');
        final second = modelFixture('thumb_over_label.json');
        final registry = ObjectRegistry()
          ..resolve(modelId: 'jar_1', modelLabel: 'jar 1')
          ..resolve(modelId: 'jar_4', modelLabel: 'jar 4');
        final spoken = <String>[];
        final o = await _pipeline(FakeModelClient([first, second])).run(
          testSettings,
          _input(IntentType.ask, spoken.add, ocr: ['PAPR'], registry: registry),
        );
        expect(spoken, ['Jar 1, in your right hand.']);
        expect(o.spokenAfterEarly, startsWith('Correction: Jar 2'));
      },
    );
  });

  group('earcons (Section 13)', () {
    test('every earcon file exists and is at most 300 ms', () {
      for (final e in Earcon.values) {
        final f = File('assets/sounds/${e.file}.wav');
        expect(f.existsSync(), isTrue, reason: e.file);
        // 44.1 kHz mono 16-bit: 88.2 bytes per ms, plus a 44-byte header.
        final ms = (f.lengthSync() - 44) / 88.2;
        expect(ms, lessThanOrEqualTo(300), reason: e.file);
      }
    });

    test('confidence levels map to distinct earcons', () {
      expect(Earcon.forConfidence(Confidence.read), Earcon.read);
      expect(Earcon.forConfidence(Confidence.think), Earcon.think);
      expect(Earcon.forConfidence(Confidence.cantSee), Earcon.cantSee);
    });
  });

  group('onboarding (Section 10)', () {
    test('steps in order; learn-the-vibrations only if vibration is on', () {
      final on = <OnboardingStep>[];
      var s = OnboardingStep.language;
      while (s != OnboardingStep.done) {
        on.add(s);
        s = s.next(vibrationOn: true);
      }
      expect(on, contains(OnboardingStep.learnVibrations));
      expect(on.first, OnboardingStep.language);
      expect(on.last, OnboardingStep.practiceAsk);
      expect(
        OnboardingStep.vibration.next(vibrationOn: false),
        OnboardingStep.practiceHold,
      );
    });

    test('asks language, vision, positions, rate, earcons and vibration', () {
      expect(OnboardingStep.values.take(6), [
        OnboardingStep.language,
        OnboardingStep.vision,
        OnboardingStep.position,
        OnboardingStep.rate,
        OnboardingStep.earcons,
        OnboardingStep.vibration,
      ]);
    });
  });

  group('vibration practice (Section 11)', () {
    test('four correct in a row means ready; a miss resets the streak', () {
      final p = VibrationPractice();
      p.next();
      p.answer(p.current!);
      p.next();
      final wrong = VibrationPractice.directions.firstWhere(
        (d) => d != p.current,
      );
      expect(p.answer(wrong), isFalse);
      expect(p.streak, 0);
      for (var i = 0; i < 4; i++) {
        p.next();
        p.answer(p.current!);
      }
      expect(p.ready, isTrue);
      expect(p.accuracy, closeTo(5 / 6, 1e-9));
    });

    test('spoken answers in English and French', () {
      expect(VibrationPractice.parse('Left'), GuidancePattern.left);
      expect(VibrationPractice.parse('à droite'), GuidancePattern.right);
      expect(VibrationPractice.parse('vers le haut'), GuidancePattern.up);
      expect(VibrationPractice.parse('bas'), GuidancePattern.down);
      expect(VibrationPractice.parse('banana'), isNull);
    });
  });

  group('settings', () {
    test('feedback and thresholds survive a save/load round trip', () {
      const s = AppSettings(
        feedback: FeedbackSettings(
          earcons: false,
          intensity: VibrationIntensity.high,
          slowPatterns: true,
        ),
        thresholds: VisionThresholds(glareFraction: 0.2, lockIou: 0.4),
        onboardingDone: true,
      );
      final stored = <String, String>{
        'FEEDBACK': '{"earcons":false,"intensity":"high","slow_patterns":true}',
        'THRESHOLDS': '{"glare_fraction":0.2,"lock_iou":0.4}',
        'ONBOARDING_DONE': 'true',
      };
      final loaded = SettingsRepository.merge(stored, {});
      expect(loaded.feedback.earcons, s.feedback.earcons);
      expect(loaded.feedback.intensity, VibrationIntensity.high);
      expect(loaded.feedback.slowPatterns, isTrue);
      expect(loaded.feedback.vibrationGuidance, isTrue, reason: 'default');
      expect(loaded.thresholds.glareFraction, 0.2);
      expect(loaded.thresholds.lockIou, 0.4);
      expect(loaded.thresholds.farDistance, 0.6, reason: 'default');
      expect(loaded.onboardingDone, isTrue);
    });

    test('defaults match the specification', () {
      const f = FeedbackSettings();
      expect(f.vibrationGuidance, isTrue);
      expect(f.speakDirection, isFalse);
      expect(f.vibrateInSearch, isTrue);
      const t = VisionThresholds();
      expect(
        [t.farDistance, t.middleDistance, t.fullViewDistance],
        [0.6, 0.3, 0.15],
      );
      expect([t.lockIou, t.glareFraction], [0.3, 0.15]);
      expect([t.lostAfterMs, t.hysteresisMs, t.blurForMs], [3000, 300, 1000]);
    });
  });
}
