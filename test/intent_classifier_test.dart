import 'package:bifrost/src/intent/intent_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final en = classifierFor('en');
  final fr = classifierFor('fr');

  // The examples from the Section 6 table, plus a few variants.
  const englishCases = {
    'help me sort these': IntentType.startTask,
    'find my keys': IntentType.startTask,
    'does this match': IntentType.startTask,
    'what is this': IntentType.ask,
    "What's this?": IntentType.ask,
    'is this the cumin': IntentType.ask,
    'where is the cumin': IntentType.ask,
    'are you sure': IntentType.challenge,
    "Are you sure it's not paprika?": IntentType.challenge,
    'is it really': IntentType.challenge,
    "I think it's paprika": IntentType.challenge,
    'no, the other one': IntentType.repair,
    'the left one': IntentType.repair,
    'item 3': IntentType.repair,
    'the closer one': IntentType.repair,
    'what have I done': IntentType.status,
    "what's left": IntentType.status,
    'tell me when you can read it': IntentType.watch,
    'keep looking': IntentType.watch,
    'more detail': IntentType.more,
    'tell me more': IntentType.more,
    'say that again': IntentType.repeat,
    'stop': IntentType.stop,
    'cancel': IntentType.stop,
  };

  const frenchCases = {
    'aide-moi à trier': IntentType.startTask,
    'trouve mes clés': IntentType.startTask,
    'est-ce que ça va avec': IntentType.startTask,
    "c'est quoi ça": IntentType.ask,
    "est-ce que c'est le cumin": IntentType.ask,
    'es-tu sûr': IntentType.challenge,
    "t'es sûr": IntentType.challenge,
    "je pense que c'est du paprika": IntentType.challenge,
    "non, l'autre": IntentType.repair,
    'celui de gauche': IntentType.repair,
    'le numéro 3': IntentType.repair,
    'le plus proche': IntentType.repair,
    "qu'est-ce que j'ai fait": IntentType.status,
    "qu'est-ce qui reste": IntentType.status,
    'dis-moi quand tu peux le lire': IntentType.watch,
    'continue de regarder': IntentType.watch,
    'plus de détails': IntentType.more,
    'répète': IntentType.repeat,
    'arrête': IntentType.stop,
    'annule': IntentType.stop,
  };

  group('English', () {
    englishCases.forEach((text, type) {
      test('"$text" -> ${type.wire}', () {
        expect(en.classify(text).type, type);
      });
    });
  });

  group('French', () {
    frenchCases.forEach((text, type) {
      test('"$text" -> ${type.wire}', () {
        expect(fr.classify(text).type, type);
      });
    });
  });

  group('slots', () {
    test('task type and goal', () {
      final i = en.classify('Can you find my house keys?');
      expect(i.task, 'find');
      expect(i.goal, 'house keys');
      expect(fr.classify('Trouve mes clés.').goal, 'clés');
      expect(en.classify('help me sort these spices').task, 'sort');
      expect(fr.classify("est-ce que ça va avec ma chemise").task, 'match');
    });

    test('repair relation and number', () {
      expect(en.classify('the closer one').relation, 'closer');
      expect(en.classify('no, the other one').relation, 'other');
      expect(en.classify('item 3').number, 3);
      expect(en.classify('jar three').number, 3);
      expect(en.classify('the second one').number, 2);
      expect(fr.classify('le numéro 3').number, 3);
      expect(fr.classify('le pot deux').number, 2);
      expect(fr.classify('celle de droite').relation, 'right');
    });
  });

  test('matching ignores case, accents and punctuation', () {
    expect(fr.classify('ARRÊTE !').type, IntentType.stop);
    expect(fr.classify('arrete').type, IntentType.stop);
    expect(fr.classify('QU’EST-CE QUE J’AI FAIT ?').type, IntentType.status);
    expect(en.classify('WHAT IS LEFT?').type, IntentType.status);
  });

  test('empty or unknown speech is ASK', () {
    expect(en.classify('').type, IntentType.ask);
    expect(en.classify('hmm').type, IntentType.ask);
  });

  test('local intents never need the model', () {
    expect(
      [
        for (final t in IntentType.values)
          if (t.isLocal) t,
      ],
      [IntentType.status, IntentType.more, IntentType.repeat, IntentType.stop],
    );
  });
}
