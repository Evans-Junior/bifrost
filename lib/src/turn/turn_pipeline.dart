import 'dart:async';

import 'package:dio/dio.dart';

import '../../l10n/gen/app_localizations.dart';
import '../guards/guards.dart';
import '../model/model_client.dart';
import '../model/prompt_builder.dart';
import '../model/response_parser.dart';
import '../model/vlm_response.dart';
import '../settings/app_settings.dart';
import '../speech/speech_composer.dart';
import '../speech/spoken_reply.dart';

/// Why a turn did not produce an answer. Each maps to an honest spoken
/// status line (rule 12).
enum TurnFailure { timeout, lostTrack, connection, cancelled }

/// The result of one model turn, ready to speak and log.
class TurnOutcome {
  const TurnOutcome({
    required this.spokenText,
    this.reply,
    this.response,
    this.rawModelText = const [],
    this.guardEvents = const [],
    this.failure,
  });

  /// What BIFROST says. Always composed from templates.
  final String spokenText;
  final SpokenReply? reply;

  /// The guarded response.
  final VlmResponse? response;

  /// Raw model output of each attempt, for the turn log.
  final List<String> rawModelText;
  final List<GuardEvent> guardEvents;
  final TurnFailure? failure;

  bool get isSuccess => failure == null;
}

/// Runs steps 5–10 of the turn pipeline (Section 7): build the request,
/// call the model, validate the JSON (retry once), apply guards and compose
/// speech. Free of Flutter plugins so it can be tested with fixtures.
class TurnPipeline {
  TurnPipeline({
    required this.client,
    required this.prompts,
    this.parser = const ResponseParser(),
    this.guards = const Guards(),
  });

  final ModelClient client;
  final PromptBuilder prompts;
  final ResponseParser parser;
  final Guards guards;

  /// Runs one turn with the hard timeout from [settings].
  Future<TurnOutcome> run(
    AppSettings settings,
    TurnContext ctx, {
    CancelToken? cancel,
  }) async {
    final l10n = lookupAppLocalizations(settings.language.locale);
    final token = cancel ?? CancelToken();
    final raws = <String>[];
    try {
      return await _run(settings, ctx, token, l10n, raws)
          .timeout(Duration(seconds: settings.timeoutS));
    } on TimeoutException {
      token.cancel('timeout');
      return _fail(TurnFailure.timeout, l10n.timeout, raws);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return _fail(TurnFailure.cancelled, '', raws);
      }
      return _fail(TurnFailure.connection, l10n.cannotConnect, raws);
    } on ModelConnectionException {
      return _fail(TurnFailure.connection, l10n.cannotConnect, raws);
    }
  }

  Future<TurnOutcome> _run(
    AppSettings settings,
    TurnContext ctx,
    CancelToken token,
    AppLocalizations l10n,
    List<String> raws,
  ) async {
    final messages = await prompts.messages(settings, ctx);
    var response = await _attempt(settings, messages, token, raws);
    if (response == null) {
      final retry = [
        ...messages,
        {'role': 'assistant', 'content': raws.last},
        {'role': 'user', 'content': await prompts.retryInstruction(settings)},
      ];
      response = await _attempt(settings, retry, token, raws);
    }
    if (response == null) {
      return _fail(TurnFailure.lostTrack, l10n.lostTrack, raws);
    }
    return answer(response, l10n, raws);
  }

  /// Applies guards and composes speech for an already-parsed response.
  TurnOutcome answer(
    VlmResponse response,
    AppLocalizations l10n, [
    List<String> raws = const [],
  ]) {
    final events = <GuardEvent>[];
    final guarded = guards.applyToResponse(response, events);
    final composed = SpeechComposer(l10n).compose(guarded);
    final reply = guards.lengthCap(composed, events);
    return TurnOutcome(
      spokenText: reply.text,
      reply: reply,
      response: guarded,
      rawModelText: List.unmodifiable(raws),
      guardEvents: events,
    );
  }

  Future<VlmResponse?> _attempt(
    AppSettings settings,
    List<Map<String, dynamic>> messages,
    CancelToken token,
    List<String> raws,
  ) async {
    final buffer = StringBuffer();
    await for (final delta
        in client.streamChat(settings, messages, cancel: token)) {
      buffer.write(delta);
    }
    final raw = buffer.toString();
    raws.add(raw);
    try {
      return parser.parse(raw);
    } on SchemaException {
      return null;
    }
  }

  TurnOutcome _fail(TurnFailure f, String text, List<String> raws) =>
      TurnOutcome(
        spokenText: text,
        failure: f,
        rawModelText: List.unmodifiable(raws),
      );
}
