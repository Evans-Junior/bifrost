import 'package:bifrost/src/guards/guards.dart';
import 'package:bifrost/src/model/vlm_response.dart';
import 'package:bifrost/src/speech/speech_composer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final en = SpeechComposer(l10nFor('en'));
  final fr = SpeechComposer(l10nFor('fr'));

  test('READ answer: referent, observation, confidence phrase', () {
    final r = en.compose(responseFixture('labelled_jar_read.json'));
    expect(
      r.text,
      'Jar 1, in your right hand. The label says cumin. I read this directly.',
    );
    expect(r.detail, 'Ground cumin, 45 g.');
  });

  test('THINK answer includes the reason and next step', () {
    final r = en.compose(responseFixture('thumb_over_label.json'));
    expect(r.text, startsWith('Jar 4, in your right hand.'));
    expect(
      r.text,
      contains('I think so, because your thumb covers part of the label.'),
    );
    expect(r.text, endsWith("Move your thumb and I'll confirm."));
  });

  test('CANT_SEE answer: referent, cannot-see phrase, action', () {
    final r = en.compose(responseFixture('label_away_clean.json'));
    expect(
      r.text,
      "Jar 1, in your right hand. I can't see enough to tell. Turn it a quarter turn.",
    );
  });

  test('CANT_SEE without an action gets the default action', () {
    final input = responseFixture(
      'label_away_clean.json',
    ).copyWith(nextStep: '');
    expect(en.compose(input).nextStep, l10nFor('en').cantSeeDefaultAction);
  });

  test('a scene-level answer (no referent) opens with "Overall view"', () {
    const input = VlmResponse(
      needsClarification: false,
      evidence: Evidence.seen,
      confidence: Confidence.think,
      observation: 'a mug',
    );
    final text = en.compose(input).text;
    expect(text, startsWith('Overall view.'));
    expect(text, contains('A mug.'));
  });

  test('clarification asks one either/or question', () {
    final r = en.compose(responseFixture('two_jars_clarify.json'));
    expect(r.isClarification, isTrue);
    expect(r.text, 'the jar on your left or the jar on your right?');
  });

  test('French templates are used in French', () {
    final r = fr.compose(responseFixture('labelled_jar_read.json'));
    expect(r.text, contains("Je l'ai lu directement."));
    final c = fr.compose(responseFixture('label_away_clean.json'));
    expect(c.text, contains(l10nFor('fr').cantSee));
  });

  test('acronym reasons keep their capitals', () {
    final input = responseFixture(
      'thumb_over_label.json',
    ).copyWith(confidenceReason: 'PAPR is all I can read');
    expect(en.compose(input).text, contains('because PAPR is all I can read.'));
  });

  test('guarded leaky CANT_SEE never speaks a spice name', () {
    final guarded = basicGuards(
      const Guards(),
      responseFixture('label_away_leaky.json'),
      [],
    );
    final text = en.compose(guarded).text.toLowerCase();
    expect(text, isNot(contains('cumin')));
    expect(text, contains("can't see"));
  });

  test('a referent without a label still gets a referent phrase', () {
    final input = responseFixture('thumb_over_label.json').copyWith(
      referent: const Referent(id: 'x', label: ''),
    );
    expect(
      en.compose(input).text,
      startsWith('The item in front of the camera.'),
    );
  });
}
