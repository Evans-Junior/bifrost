import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../conversation/conversation_engine.dart';
import '../settings/app_settings.dart';

/// Times of one turn (Section 13): button release, first audio, full answer
/// and end of speech.
class TurnTimes {
  TurnTimes(this.release);

  final DateTime release;
  DateTime? firstAudio;
  DateTime? fullAnswer;
  DateTime? speechEnd;

  int? _ms(DateTime? t) => t?.difference(release).inMilliseconds;

  Map<String, dynamic> toJson() => {
    'release': release.toUtc().toIso8601String(),
    'first_audio': firstAudio?.toUtc().toIso8601String(),
    'full_answer': fullAnswer?.toUtc().toIso8601String(),
    'speech_end': speechEnd?.toUtc().toIso8601String(),
  };

  Map<String, dynamic> latency() => {
    'first_audio': _ms(firstAudio),
    'full_answer': _ms(fullAnswer),
  };
}

/// Builds log entries and writes them as JSON Lines, locally and (if set)
/// to the log server. Images are never logged.
class TurnLogger {
  TurnLogger({Dio? dio, String? sessionId})
    : _dio = dio ?? Dio(),
      sessionId = sessionId ?? _newSessionId();

  final Dio _dio;

  /// Identifies this app run in the logs.
  final String sessionId;
  int _turnIndex = 0;

  /// Entries kept for resending while the server is unreachable. Older ones
  /// remain in the local file.
  static const maxPending = 200;
  final List<Map<String, dynamic>> _unsent = [];

  static String _newSessionId() {
    final now = DateTime.now().toUtc();
    final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '${now.toIso8601String().substring(0, 19).replaceAll(':', '')}-$rand';
  }

  /// One JSON-serializable entry for a finished turn. Pure, so it is tested
  /// without a device.
  Map<String, dynamic> entry({
    required String transcript,
    required EngineReply reply,
    required ConversationState state,
    required AppSettings settings,
    required TurnTimes times,
    String mode = 'AI',
  }) {
    final outcome = reply.outcome;
    final response = outcome?.response;
    return {
      'schema': 1,
      'session_id': sessionId,
      'participant': settings.participant,
      'mode': mode,
      'language': settings.language.localeTag,
      'profile': settings.profile.assetKey,
      'task': {'type': state.task.type, 'goal': state.task.goal},
      'turn_index': _turnIndex++,
      'transcript': transcript,
      'intent': reply.intent.type.wire,
      'intent_slots': reply.intent.slots,
      'timestamps': times.toJson(),
      'latency_ms': times.latency(),
      'used_model': reply.usedModel,
      'failure': outcome?.failure?.name,
      'confidence': switch (reply.confidence?.name) {
        'read' => 'READ',
        'think' => 'THINK',
        'cantSee' => 'CANT_SEE',
        _ => null,
      },
      'clarification': reply.isClarification,
      'challenge': outcome?.challenge.name ?? 'none',
      'spoken_text': reply.text,
      'detail': outcome?.reply?.detail ?? '',
      'raw_model': outcome?.rawModelText ?? const [],
      'response': response?.toJson(),
      'ocr_tokens': reply.ocrTokens,
      'guards': [
        for (final g in outcome?.guardEvents ?? const [])
          {'guard': g.guard, 'before': g.before, 'after': g.after},
      ],
      'registry': [
        for (final o in state.registry.objects)
          {
            'id': o.id,
            'label': o.label,
            'identified_as': o.identifiedAs,
            'confidence': o.confidence?.name,
          },
      ],
    };
  }

  /// Appends [entry] to the local session file and sends it to the log
  /// server. Never throws: logging must not break a turn.
  Future<void> write(Map<String, dynamic> entry, AppSettings settings) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/bifrost_logs/$sessionId.jsonl');
      await file.parent.create(recursive: true);
      await file.writeAsString('${jsonEncode(entry)}\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('[log] local write failed: $e');
    }
    final url = settings.logServerUrl.trim();
    if (url.isEmpty) return;
    _unsent.add(entry);
    if (_unsent.length > maxPending) _unsent.removeAt(0);
    try {
      await _dio.post<void>(
        '${url.replaceAll(RegExp(r'/+$'), '')}/api/logs',
        data: List.of(_unsent),
        options: Options(
          headers: {
            if (settings.logToken.isNotEmpty)
              'Authorization': 'Bearer ${settings.logToken}',
          },
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      _unsent.clear();
    } catch (e) {
      // Kept and resent with the next turn.
      debugPrint('[log] upload failed (${_unsent.length} pending): $e');
    }
  }
}
