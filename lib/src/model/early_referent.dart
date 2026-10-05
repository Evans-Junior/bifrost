import 'dart:convert';

import 'vlm_response.dart';

/// What can be known from the first part of a streamed reply.
class EarlyFields {
  const EarlyFields(this.needsClarification, this.referent);

  final bool needsClarification;

  /// Null when the model set `"referent": null`.
  final Referent? referent;
}

/// Tolerant partial parser over the accumulating stream buffer (Section 9).
/// The schema puts `needs_clarification` and `referent` first, so both are
/// usually complete long before the rest of the reply arrives.
class EarlyReferentReader {
  final StringBuffer _buffer = StringBuffer();
  bool _done = false;

  /// Adds a streamed chunk. Returns the early fields once, as soon as both
  /// are complete; null before that and after.
  EarlyFields? feed(String delta) {
    if (_done) return null;
    _buffer.write(delta);
    final result = parse(_buffer.toString());
    if (result != null) _done = true;
    return result;
  }

  /// Parses [text] (possibly incomplete JSON). Null until both fields are
  /// complete.
  static EarlyFields? parse(String text) {
    final nc = RegExp(
      r'"needs_clarification"\s*:\s*(true|false)',
    ).firstMatch(text);
    if (nc == null) return null;
    final needs = nc.group(1) == 'true';

    final key = RegExp(r'"referent"\s*:\s*').firstMatch(text);
    if (key == null) return null;
    final rest = text.substring(key.end);
    if (rest.startsWith('null')) return EarlyFields(needs, null);
    if (!rest.startsWith('{')) return null;
    final end = _matchingBrace(rest);
    if (end < 0) return null;
    try {
      final json = jsonDecode(rest.substring(0, end + 1));
      return EarlyFields(
        needs,
        Referent.fromJson(json as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }

  /// Index of the brace closing the object that starts at 0, or -1 if the
  /// object is not complete yet. Braces inside strings are ignored.
  static int _matchingBrace(String s) {
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (c == r'\') {
          escaped = true;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '"') {
        inString = true;
      } else if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }
}
