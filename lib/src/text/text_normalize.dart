/// Text helpers shared by the intent classifier and the OCR cross-check.
/// Matching in BIFROST is always case- and accent-insensitive.
class TextNormalize {
  static const _accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'œ': 'oe',
    'æ': 'ae',
  };

  /// Lowercase, accents removed, punctuation and apostrophes turned into
  /// single spaces. "Qu'est-ce que j'ai fait ?" -> "qu est ce que j ai fait".
  static String forMatching(String s) {
    final lower = s.toLowerCase();
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(_accents[ch] ?? ch);
    }
    return buf.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  /// Label form used by the OCR cross-check: uppercase, no accents, no
  /// punctuation. "Paprika fumé!" -> "PAPRIKA FUME".
  static String label(String s) => forMatching(s).toUpperCase();

  /// Words of [s] in label form.
  static List<String> labelWords(String s) {
    final l = label(s);
    return l.isEmpty ? const [] : l.split(' ');
  }

  /// Similarity in 0..1 from Levenshtein distance (1 = identical).
  static double similarity(String a, String b) {
    if (a == b) return 1;
    final longest = a.length > b.length ? a.length : b.length;
    if (longest == 0) return 1;
    return 1 - levenshtein(a, b) / longest;
  }

  /// Classic edit distance.
  static int levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = [
          prev[j] + 1,
          cur[j - 1] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  /// Label text in a form text-to-speech says as words: "CUMIN" -> "Cumin",
  /// "SMOKED PAPRIKA" -> "Smoked paprika". Short acronyms stay as they are.
  static String speakable(String s) {
    final t = s.trim();
    if (t.length <= 3 || t != t.toUpperCase() || t == t.toLowerCase()) return t;
    final lower = t.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
