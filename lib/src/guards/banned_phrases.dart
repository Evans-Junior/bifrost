import 'dart:convert';

import 'package:flutter/services.dart';

/// Sight-assuming wording for guard 7, loaded from
/// `assets/guards/banned_phrases.json` (English and French together).
class BannedPhrases {
  const BannedPhrases({
    this.strip = const [],
    this.dropSentence = const [],
    this.chatter = const [],
  });

  static const empty = BannedPhrases();

  /// Phrases removed on their own ("as you can see").
  final List<String> strip;

  /// Phrases whose whole sentence is removed ("check the label").
  final List<String> dropSentence;

  /// Filler whose whole sentence is removed ("let me know if…").
  final List<String> chatter;

  factory BannedPhrases.fromJson(Map<String, dynamic> j) => BannedPhrases(
    strip: [for (final s in j['strip'] as List? ?? const []) s as String],
    dropSentence: [
      for (final s in j['drop_sentence'] as List? ?? const []) s as String,
    ],
    chatter: [for (final s in j['chatter'] as List? ?? const []) s as String],
  );

  static Future<BannedPhrases> load([AssetBundle? bundle]) async {
    final text = await (bundle ?? rootBundle).loadString(
      'assets/guards/banned_phrases.json',
    );
    return BannedPhrases.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  /// Returns [text] without banned phrases, tidied up.
  String clean(String text) {
    if (text.trim().isEmpty) return text;
    final normalized = text.replaceAll('’', "'");
    final sentences = normalized.split(RegExp(r'(?<=[.!?])\s+'));
    final kept = <String>[];
    for (var sentence in sentences) {
      for (final p in strip) {
        sentence = sentence.replaceAll(_find(p), ' ');
      }
      if ([
        ...dropSentence,
        ...chatter,
      ].any((p) => _find(p).hasMatch(sentence))) {
        continue;
      }
      final tidy = _tidy(sentence);
      if (tidy.isNotEmpty) kept.add(tidy);
    }
    final out = kept.join(' ');
    return out == _tidy(normalized) ? text : out;
  }

  static RegExp _find(String phrase) => RegExp(
    '(?<![\\p{L}\\p{N}])${RegExp.escape(phrase.replaceAll('’', "'"))}(?![\\p{L}\\p{N}])',
    caseSensitive: false,
    unicode: true,
  );

  /// Removes leftover leading punctuation and doubled spaces, and
  /// capitalizes the first letter.
  static String _tidy(String s) {
    var t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceFirst(RegExp(r'^[,;:\-–—\s]+'), '');
    t = t.replaceAll(RegExp(r'\s+([,.!?;:])'), r'$1');
    if (t.isEmpty || !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(t)) {
      return '';
    }
    return t[0].toUpperCase() + t.substring(1);
  }
}
