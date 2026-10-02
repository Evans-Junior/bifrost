import 'dart:convert';
import 'dart:io';

import 'package:bifrost/src/conversation/object_registry.dart';
import 'package:bifrost/src/guards/banned_phrases.dart';
import 'package:bifrost/src/guards/guards.dart';
import 'package:bifrost/src/model/vlm_response.dart';
import 'package:bifrost/src/vision/ocr_result.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

VlmResponse _read(String text, {bool changed = false}) => VlmResponse(
  needsClarification: false,
  referent: const Referent(id: 'jar_2', label: 'jar 2'),
  evidence: Evidence.read,
  readText: text,
  confidence: Confidence.read,
  answerChanged: changed,
);

RegisteredObject _cuminJar() => RegisteredObject(
  id: 'jar_2',
  label: 'jar 2',
  number: 2,
  identifiedAs: 'CUMIN',
  readText: 'CUMIN',
  confidence: Confidence.read,
);

void main() {
  const guards = Guards();

  group('Guard 2: OCR cross-check', () {
    test('READ text found by OCR is kept', () {
      final log = <GuardEvent>[];
      final r = guards.ocrCrossCheck(
        _read('CUMIN'),
        ocrOf(['Cumin', 'Net 45 g']),
        'hard',
        log,
      );
      expect(r.confidence, Confidence.read);
      expect(log, isEmpty);
    });

    test('invented label with empty OCR is downgraded (script step 5)', () {
      final log = <GuardEvent>[];
      final r = guards.ocrCrossCheck(
        _read('CHILI'),
        OcrResult.empty,
        'the label is hard to read',
        log,
      );
      expect(r.confidence, Confidence.think);
      expect(r.confidenceReason, 'the label is hard to read');
      expect(log.single.guard, 'ocr_cross_check');
    });

    test('label OCR does not contain is downgraded', () {
      final r = guards.ocrCrossCheck(
        _read('PAPRIKA'),
        ocrOf(['CUMIN']),
        'hard',
        [],
      );
      expect(r.confidence, Confidence.think);
    });

    test('accents, case and punctuation are ignored', () {
      expect(
        Guards.ocrConfirms('Paprika fumé', ocrOf(['PAPRIKA FUME!'])),
        isTrue,
      );
    });

    test('one misread letter still matches (similarity >= 0.8)', () {
      expect(Guards.ocrConfirms('OREGANO', ocrOf(['0REGANO'])), isTrue);
    });

    test('words spread over two OCR lines match', () {
      expect(
        Guards.ocrConfirms('smoked paprika', ocrOf(['SMOKED', 'PAPRIKA'])),
        isTrue,
      );
    });

    test('a short fragment does not confirm a longer word', () {
      expect(Guards.ocrConfirms('PAPRIKA', ocrOf(['PAP'])), isFalse);
    });

    test('THINK answers are not checked', () {
      final think = _read('CUMIN').copyWith(confidence: Confidence.think);
      expect(guards.ocrCrossCheck(think, OcrResult.empty, 'x', []), think);
    });
  });

  group('Guard 3: challenge', () {
    test('kept answer is "held"', () {
      final c = guards.challenge(_read('CUMIN'), _cuminJar(), []);
      expect(c.outcome, ChallengeOutcome.held);
    });

    test('change without READ is rejected and the old answer restored', () {
      final log = <GuardEvent>[];
      final flipped = _read(
        'PAPRIKA',
        changed: true,
      ).copyWith(confidence: Confidence.think);
      final c = guards.challenge(flipped, _cuminJar(), log);
      expect(c.outcome, ChallengeOutcome.rejected);
      expect(c.response.readText, 'CUMIN');
      expect(c.response.confidence, Confidence.read);
      expect(c.response.answerChanged, isFalse);
      expect(log.single.guard, 'challenge');
    });

    test('change with OCR-confirmed READ is accepted', () {
      final c = guards.challenge(
        _read('PAPRIKA', changed: true),
        _cuminJar(),
        [],
      );
      expect(c.outcome, ChallengeOutcome.accepted);
    });

    test('a silent change (answer_changed false) is still detected', () {
      final silent = _read('PAPRIKA').copyWith(confidence: Confidence.think);
      expect(
        guards.challenge(silent, _cuminJar(), []).outcome,
        ChallengeOutcome.rejected,
      );
    });

    test('nothing to compare against gives "none"', () {
      expect(
        guards.challenge(_read('CUMIN'), null, []).outcome,
        ChallengeOutcome.none,
      );
    });

    test('same identity in other words is not a change', () {
      expect(Guards.sameIdentity('Ground cumin', 'CUMIN'), isTrue);
      expect(Guards.sameIdentity('PAPRIKA', 'CUMIN'), isFalse);
    });
  });

  group('Guard 5: clarification validity', () {
    final base = responseFixture('two_jars_clarify.json');

    test('exactly two options is valid', () {
      expect(Guards.clarificationValid(base), isTrue);
    });

    test('three options are cut to two after the retry', () {
      final three = base.copyWith(clarificationOptions: ['a', 'b', 'c']);
      expect(Guards.clarificationValid(three), isFalse);
      final log = <GuardEvent>[];
      expect(guards.fixClarification(three, log)!.clarificationOptions, [
        'a',
        'b',
      ]);
      expect(log.single.guard, 'clarification_validity');
    });

    test('one option cannot be asked', () {
      final one = base.copyWith(clarificationOptions: ['a']);
      expect(guards.fixClarification(one, []), isNull);
    });
  });

  group('Guard 6: label stability', () {
    test('unknown ids get the next sequential label', () {
      final reg = ObjectRegistry();
      final a = reg.resolve(modelId: 'jar_1', modelLabel: 'jar 1');
      final b = reg.resolve(modelId: 'bottle_9', modelLabel: 'bottle 9');
      expect(a.label, 'jar 1');
      expect(b.label, 'bottle 2');
      expect(b.id, 'bottle_2');
    });

    test('known ids keep their label', () {
      final reg = ObjectRegistry();
      final a = reg.resolve(modelId: 'x', modelLabel: 'jar 7');
      expect(reg.resolve(modelId: 'x', modelLabel: 'jar 99').label, a.label);
      expect(reg.resolve(modelId: a.id).label, a.label);
    });

    test('numbers are never reused, even in a copy', () {
      final reg = ObjectRegistry()..resolve(modelId: 'a', modelLabel: 'jar');
      final copy = reg.copy();
      expect(copy.resolve(modelId: 'b', modelLabel: 'jar').number, 2);
      expect(
        reg.resolve(modelId: 'c', modelLabel: 'jar').number,
        2,
        reason: 'the discarded copy does not advance the original',
      );
    });

    test('labels without a noun use the fallback noun', () {
      final reg = ObjectRegistry(fallbackNoun: 'objet');
      expect(reg.resolve(modelId: 'q', modelLabel: '3').label, 'objet 1');
    });

    test('lookup by number', () {
      final reg = ObjectRegistry()
        ..resolve(modelId: 'a', modelLabel: 'jar')
        ..resolve(modelId: 'b', modelLabel: 'jar');
      expect(reg.byNumber(2)!.id, 'jar_2');
      expect(reg.byNumber(9), isNull);
    });
  });

  group('Guard 7: banned phrases', () {
    final banned = BannedPhrases.fromJson(
      jsonDecode(File('assets/guards/banned_phrases.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final g = Guards(banned: banned);

    test('filler phrase is stripped, sentence kept', () {
      expect(
        banned.clean('As you can see, the lid is black.'),
        'The lid is black.',
      );
    });

    test('sentence asking the user to look is dropped', () {
      expect(
        banned.clean('Check the label to be sure. Turn it toward me.'),
        'Turn it toward me.',
      );
    });

    test('French phrases are removed too', () {
      expect(
        banned.clean("Comme tu peux le voir, c'est du cumin."),
        "C'est du cumin.",
      );
      expect(
        banned.clean("Vérifie l'étiquette. Tourne-le vers moi."),
        'Tourne-le vers moi.',
      );
    });

    test('the AI describing its own view is not banned', () {
      const ok = "I can't read the label. Turn it so I can look at the back.";
      expect(banned.clean(ok), ok);
      expect(banned.clean('Je regarde encore.'), 'Je regarde encore.');
    });

    test('guard logs each change across fields', () {
      final log = <GuardEvent>[];
      final r = g.bannedPhrases(
        VlmResponse.fromJson(jsonFixture('script/s_banned.json')),
        log,
      );
      expect(r.observation, 'The lid is black.');
      expect(r.nextStep, 'Turn it toward me.');
      expect(log.where((e) => e.guard == 'banned_phrases'), hasLength(2));
    });
  });
}
