import 'dart:convert';

import 'vlm_response.dart';

/// Thrown when the model's output is not valid JSON for the schema.
class SchemaException implements Exception {
  SchemaException(this.message);

  final String message;

  @override
  String toString() => 'SchemaException: $message';
}

/// Validates raw model text against the [VlmResponse] schema.
class ResponseParser {
  const ResponseParser();

  /// Parses [raw] into a [VlmResponse], or throws [SchemaException].
  ///
  /// Tolerates a Markdown code fence or stray text around one JSON object,
  /// because some servers add them even when asked not to.
  VlmResponse parse(String raw) {
    final json = _decodeObject(_extractObject(raw));
    _requireKeys(json, const ['needs_clarification', 'evidence', 'confidence']);
    try {
      return VlmResponse.fromJson(json);
    } catch (e) {
      throw SchemaException('does not match schema: $e');
    }
  }

  String _extractObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw SchemaException('no JSON object found');
    }
    return raw.substring(start, end + 1);
  }

  Map<String, dynamic> _decodeObject(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException catch (e) {
      throw SchemaException('invalid JSON: ${e.message}');
    }
    throw SchemaException('top level is not an object');
  }

  void _requireKeys(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (!json.containsKey(k) || json[k] == null) {
        throw SchemaException('missing field "$k"');
      }
    }
  }
}
