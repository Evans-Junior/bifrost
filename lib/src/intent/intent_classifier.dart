import 'dart:convert';

import 'package:flutter/services.dart';

import '../text/text_normalize.dart';

/// The intents of Section 6. Anything unmatched is [ask].
enum IntentType {
  startTask('START_TASK'),
  ask('ASK'),
  challenge('CHALLENGE'),
  repair('REPAIR'),
  status('STATUS'),
  watch('WATCH'),
  more('MORE'),
  repeat('REPEAT'),
  stop('STOP');

  const IntentType(this.wire);

  /// Name used in the asset files and in the model request.
  final String wire;

  static IntentType fromWire(String s) =>
      values.firstWhere((i) => i.wire == s, orElse: () => ask);

  /// Intents answered on the phone without a model call.
  bool get isLocal =>
      this == status || this == more || this == repeat || this == stop;
}

/// A classified utterance with optional slots: `task` (sort/find/match),
/// `goal` ("keys"), `relation` (other/left/right/closer/further) and `n`.
class Intent {
  const Intent(this.type, [this.slots = const {}]);

  final IntentType type;
  final Map<String, String> slots;

  String? get task => slots['task'];
  String? get goal => slots['goal'];
  String? get relation => slots['relation'];
  int? get number => int.tryParse(slots['n'] ?? '');

  @override
  String toString() => '${type.wire}$slots';
}

/// One rule from `assets/intents/<lang>.json`.
class _Rule {
  _Rule(this.type, this.fixedSlots, this.phrases, this.patterns);

  final IntentType type;
  final Map<String, String> fixedSlots;
  final List<RegExp> phrases;
  final List<RegExp> patterns;
}

/// Local, rule-based intent classifier (Section 6). All phrases live in
/// `assets/intents/{en,fr}.json` so the team can edit them without code.
class IntentClassifier {
  IntentClassifier._(this._rules, this._numbers, this._relationWords);

  final List<_Rule> _rules;
  final Map<String, int> _numbers;
  final Map<String, List<String>> _relationWords;

  /// Words that identify a clarification option for a REPAIR relation,
  /// e.g. closer -> [closer, near, front].
  List<String> relationWords(String relation) =>
      _relationWords[relation] ?? const [];

  /// Builds a classifier from the decoded JSON of an intents file.
  factory IntentClassifier.fromJson(Map<String, dynamic> json) {
    final numbers = {
      for (final e in (json['numbers'] as Map? ?? {}).entries)
        TextNormalize.forMatching(e.key as String): e.value as int,
    };
    final rules = [
      for (final r in json['rules'] as List)
        _Rule(
          IntentType.fromWire(r['intent'] as String),
          {
            if (r['task'] != null) 'task': r['task'] as String,
            if (r['relation'] != null) 'relation': r['relation'] as String,
          },
          [
            for (final p in (r['phrases'] as List? ?? const []))
              RegExp(
                '(?:^| )${RegExp.escape(TextNormalize.forMatching(p as String))}(?: |\$)',
              ),
          ],
          [
            for (final p in (r['patterns'] as List? ?? const []))
              RegExp(p as String),
          ],
        ),
    ];
    final relationWords = {
      for (final e in (json['relation_words'] as Map? ?? {}).entries)
        e.key as String: [
          for (final w in e.value as List)
            TextNormalize.forMatching(w as String),
        ],
    };
    return IntentClassifier._(rules, numbers, relationWords);
  }

  /// Loads `assets/intents/<languageCode>.json`.
  static Future<IntentClassifier> load(
    String languageCode, [
    AssetBundle? bundle,
  ]) async {
    final text = await (bundle ?? rootBundle).loadString(
      'assets/intents/$languageCode.json',
    );
    return IntentClassifier.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  /// Classifies [utterance]; the first matching rule wins.
  Intent classify(String utterance) {
    final text = TextNormalize.forMatching(utterance);
    if (text.isEmpty) return const Intent(IntentType.ask);
    for (final rule in _rules) {
      if (rule.phrases.any((p) => p.hasMatch(text))) {
        return Intent(rule.type, rule.fixedSlots);
      }
      for (final pattern in rule.patterns) {
        final m = pattern.firstMatch(text);
        if (m != null) return Intent(rule.type, _slots(rule, m, utterance));
      }
    }
    return const Intent(IntentType.ask);
  }

  Map<String, String> _slots(_Rule rule, RegExpMatch m, String utterance) {
    final slots = Map<String, String>.from(rule.fixedSlots);
    for (final name in m.groupNames) {
      final value = m.namedGroup(name)?.trim();
      if (value == null || value.isEmpty) continue;
      slots[name] = switch (name) {
        'n' => '${_numbers[value] ?? value}',
        'goal' => _originalTail(utterance, value),
        _ => value,
      };
    }
    return slots;
  }

  /// The last words of [utterance] matching the normalized [tail], so a goal
  /// keeps its accents for speech ("clés", not "cles").
  static String _originalTail(String utterance, String tail) {
    final count = tail.split(' ').length;
    final words = utterance
        .replaceAll(RegExp(r'[.!?…]+$'), '')
        .trim()
        .split(RegExp(r'\s+'));
    if (words.length < count) return tail;
    final picked = words.sublist(words.length - count).join(' ');
    return TextNormalize.forMatching(picked) == tail ? picked : tail;
  }
}
