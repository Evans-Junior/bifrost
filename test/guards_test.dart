import 'package:bifrost/src/guards/guards.dart';
import 'package:bifrost/src/model/vlm_response.dart';
import 'package:bifrost/src/speech/spoken_reply.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

VlmResponse _resp({
  required Evidence evidence,
  required Confidence confidence,
  String readText = '',
  String observation = 'The label says cumin.',
}) => VlmResponse(
  needsClarification: false,
  referent: const Referent(id: 'jar_1', label: 'jar 1'),
  evidence: evidence,
  confidence: confidence,
  readText: readText,
  observation: observation,
);

void main() {
  const guards = Guards();

  group('Guard 1: confidence consistency', () {
    test('READ with READ evidence is kept', () {
      final log = <GuardEvent>[];
      final r = guards.confidenceConsistency(
        _resp(evidence: Evidence.read, confidence: Confidence.read),
        log,
      );
      expect(r.confidence, Confidence.read);
      expect(log, isEmpty);
    });

    test('READ with SEEN evidence is downgraded to THINK', () {
      final log = <GuardEvent>[];
      final r = guards.confidenceConsistency(
        _resp(evidence: Evidence.seen, confidence: Confidence.read),
        log,
      );
      expect(r.confidence, Confidence.think);
      expect(log.single.guard, 'confidence_consistency');
    });

    test('NOT_VISIBLE forces CANT_SEE from READ', () {
      final log = <GuardEvent>[];
      final r = guards.confidenceConsistency(
        _resp(evidence: Evidence.notVisible, confidence: Confidence.read),
        log,
      );
      expect(r.confidence, Confidence.cantSee);
      expect(log, hasLength(1));
    });

    test('NOT_VISIBLE forces CANT_SEE from THINK', () {
      final log = <GuardEvent>[];
      final r = guards.confidenceConsistency(
        _resp(evidence: Evidence.notVisible, confidence: Confidence.think),
        log,
      );
      expect(r.confidence, Confidence.cantSee);
    });

    test('THINK with SEEN evidence is unchanged', () {
      final log = <GuardEvent>[];
      final r = guards.confidenceConsistency(
        _resp(evidence: Evidence.seen, confidence: Confidence.think),
        log,
      );
      expect(r.confidence, Confidence.think);
      expect(log, isEmpty);
    });

    test('fixture: READ claim from colour only becomes THINK', () {
      final log = <GuardEvent>[];
      final r = basicGuards(
        guards,
        responseFixture('read_claim_seen_only.json'),
        log,
      );
      expect(r.confidence, Confidence.think);
    });
  });

  group('Guard 4: no guess-filling', () {
    test('CANT_SEE drops read text, observation, detail and identities', () {
      final log = <GuardEvent>[];
      final r = basicGuards(
        guards,
        responseFixture('label_away_leaky.json'),
        log,
      );
      expect(r.confidence, Confidence.cantSee);
      expect(r.readText, isEmpty);
      expect(r.observation, isEmpty);
      expect(r.detail, isEmpty);
      expect(r.registryUpdates.every((u) => u.identifiedAs.isEmpty), isTrue);
      expect(r.nextStep, 'Turn it a quarter turn.');
      expect(r.referent?.label, 'jar 1');
      expect(
        log.map((e) => e.guard),
        containsAllInOrder(['confidence_consistency', 'no_guess_filling']),
      );
    });

    test('clean CANT_SEE is not logged', () {
      final log = <GuardEvent>[];
      guards.noGuessFilling(responseFixture('label_away_clean.json'), log);
      expect(log, isEmpty);
    });

    test('THINK answers are untouched', () {
      final log = <GuardEvent>[];
      final input = responseFixture('thumb_over_label.json');
      expect(guards.noGuessFilling(input, log), input);
      expect(log, isEmpty);
    });
  });

  group('Guard 8: length cap', () {
    SpokenReply reply(Confidence c, {String next = ''}) => SpokenReply(
      confidence: c,
      referent: 'Jar 4, in your right hand.',
      observation: 'The label says paprika, with a picture of a red pepper.',
      confidencePhrase: 'I think so, because your thumb covers part of it.',
      nextStep: next,
    );

    test('short replies are unchanged', () {
      final log = <GuardEvent>[];
      final r = SpokenReply(
        confidence: Confidence.read,
        referent: 'Jar 1.',
        observation: 'Cumin.',
        nextStep: 'Put it on the left.',
      );
      expect(guards.lengthCap(r, log).text, r.text);
      expect(log, isEmpty);
    });

    test('long reply moves next step to detail, keeps the core', () {
      final log = <GuardEvent>[];
      final long = reply(
        Confidence.read,
        next: 'You can put it with the other red spices on the left side.',
      );
      expect(long.wordCount, greaterThan(25));
      final r = guards.lengthCap(long, log);
      expect(r.nextStep, isEmpty);
      expect(r.detail, contains('other red spices'));
      expect(r.text, startsWith('Jar 4, in your right hand.'));
      expect(r.text, contains('paprika'));
      expect(r.text, contains('I think so'));
      expect(log.single.guard, 'length_cap');
    });

    test('THINK keeps its evidence action even when long', () {
      final long = reply(
        Confidence.think,
        next: 'Move your thumb a little to the left and I will confirm it.',
      );
      expect(long.wordCount, greaterThan(25));
      expect(guards.lengthCap(long, []).nextStep, contains('Move your thumb'));
    });

    test('CANT_SEE keeps its physical action even when long', () {
      final log = <GuardEvent>[];
      final long = SpokenReply(
        confidence: Confidence.cantSee,
        referent:
            'Jar 1, the tall glass jar with the black lid, in your right hand.',
        observation: "I can't see enough to tell.",
        nextStep: 'Turn it a quarter turn slowly toward you and hold it still.',
      );
      expect(long.wordCount, greaterThan(25));
      expect(guards.lengthCap(long, log).nextStep, isNotEmpty);
    });

    test('word count uses whitespace', () {
      expect(SpokenReply.countWords('  one two\nthree  '), 3);
      expect(SpokenReply.countWords(''), 0);
    });
  });

  test('l10n is available for both languages', () {
    expect(l10nFor('en').cantSee, isNotEmpty);
    expect(l10nFor('fr').cantSee, isNotEmpty);
  });
}
