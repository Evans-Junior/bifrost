// Regression tests built from replies seen in the 5 October 2026 test on a
// real iPhone with live Qwen3.8 (known issues 1-4 in ARCHITECTURE.md).

import 'dart:convert';
import 'dart:io';

import 'package:bifrost/src/guards/banned_phrases.dart';
import 'package:bifrost/src/guards/guards.dart';
import 'package:bifrost/src/model/vlm_response.dart';
import 'package:bifrost/src/speech/speech_composer.dart';
import 'package:bifrost/src/speech/spoken_reply.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final banned = BannedPhrases.fromJson(
    jsonDecode(File('assets/guards/banned_phrases.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final guards = Guards(banned: banned);
  final en = SpeechComposer(l10nFor('en'));

  SpokenReply speak(VlmResponse r) {
    final log = <GuardEvent>[];
    final g = guards.bannedPhrases(guards.confidenceConsistency(r, log), log);
    return guards.lengthCap(en.compose(g), log);
  }

  group('1. long answers are capped at 25 words', () {
    test('a long single-sentence observation is cut at a clause', () {
      final r = speak(
        const VlmResponse(
          needsClarification: false,
          referent: Referent(
            id: 'm3',
            label: 'monitor 3',
            location: 'to your right',
          ),
          evidence: Evidence.read,
          readText: 'ISAIAH 45:3',
          confidence: Confidence.read,
          observation:
              'The monitor to your right is showing a desktop with a purple '
              "background and the text 'ISAIAH 45:3' at the top.",
        ),
      );
      expect(r.wordCount, lessThanOrEqualTo(25));
      expect(r.text, startsWith('Monitor 3, to your right.'));
      expect(r.text, endsWith('I read this directly.'));
      expect(r.detail, contains('ISAIAH 45:3'));
    });

    test('a multi-sentence observation keeps its first sentence', () {
      final r = speak(
        const VlmResponse(
          needsClarification: false,
          referent: Referent(
            id: 'k1',
            label: 'keyboard 1',
            location: 'in front of you',
          ),
          evidence: Evidence.seen,
          confidence: Confidence.think,
          confidenceReason: 'the logo is partly cut off',
          observation:
              'It is a black gaming keyboard with green lights. It has a logo '
              'in the bottom right corner and a cable going to the left.',
        ),
      );
      expect(r.wordCount, lessThanOrEqualTo(25));
      expect(r.observation, 'It is a black gaming keyboard with green lights.');
      expect(r.detail, contains('cable going to the left'));
      expect(
        r.text,
        contains('I think so, because the logo is partly cut off.'),
      );
    });

    test('THINK keeps its physical action while the observation shrinks', () {
      final r = speak(
        const VlmResponse(
          needsClarification: false,
          referent: Referent(
            id: 'j5',
            label: 'jar 5',
            location: 'in your left hand',
          ),
          evidence: Evidence.read,
          readText: 'TUR',
          confidence: Confidence.think,
          confidenceReason: 'your thumb covers the label',
          observation:
              'The label starts with T U R. The rest of the word is hidden.',
          nextStep: "Move your thumb and I'll confirm.",
        ),
      );
      expect(r.text, contains('Move your thumb'));
      expect(r.text, isNot(contains('The rest of the word')));
    });

    test('nothing is cut when there is no clause boundary', () {
      const long =
          'A very large unlabelled glass storage container full of dried mixed '
          'herbs sits in the exact middle of the long wooden kitchen table';
      final r = speak(
        const VlmResponse(
          needsClarification: false,
          referent: Referent(id: 'c1', label: 'container 1'),
          evidence: Evidence.seen,
          confidence: Confidence.think,
          observation: long,
        ),
      );
      expect(r.observation, '$long.');
    });
  });

  group('2. model chatter is removed', () {
    test('offers of more help are dropped (en + fr)', () {
      expect(
        banned.clean(
          'The keyboard has a logo. Let me know if you want me to read it.',
        ),
        'The keyboard has a logo.',
      );
      expect(
        banned.clean("C'est du cumin. N'hésite pas à me demander autre chose."),
        "C'est du cumin.",
      );
      expect(banned.clean('Would you like me to describe the rest?'), isEmpty);
    });
  });

  group('3. READ wording fits screens and signs', () {
    test('the READ phrase does not mention a label', () {
      expect(l10nFor('en').confidenceRead, isNot(contains('label')));
      expect(l10nFor('fr').confidenceRead, isNot(contains('étiquette')));
    });
  });

  group('4. whole-scene answers', () {
    test('open with "Overall view." instead of a fake object', () {
      final r = speak(
        const VlmResponse(
          needsClarification: false,
          evidence: Evidence.seen,
          confidence: Confidence.think,
          confidenceReason: 'some items are partly hidden',
          observation: 'A keyboard in front of you, a laptop on your left.',
        ),
      );
      expect(r.text, startsWith('Overall view. A keyboard in front of you'));
    });

    test('the prompt asks for "you", short observations and no offers', () {
      final en = File('assets/prompts/system_en.txt').readAsStringSync();
      final fr = File('assets/prompts/system_fr.txt').readAsStringSync();
      expect(en, contains('never as "the user"'));
      expect(en, contains('at most 12 words'));
      expect(en, contains('whole scene'));
      expect(fr, contains('12 mots'));
      expect(fr, contains('toute la scène'));
    });
  });
}
