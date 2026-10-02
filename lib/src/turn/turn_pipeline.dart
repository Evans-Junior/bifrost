import 'dart:async';

import 'package:dio/dio.dart';

import '../../l10n/gen/app_localizations.dart';
import '../conversation/object_registry.dart';
import '../guards/guards.dart';
import '../intent/intent_classifier.dart';
import '../model/model_client.dart';
import '../model/prompt_builder.dart';
import '../model/response_parser.dart';
import '../model/vlm_response.dart';
import '../settings/app_settings.dart';
import '../speech/speech_composer.dart';
import '../speech/spoken_reply.dart';
import '../vision/ocr_result.dart';

/// Why a turn did not produce an answer. Each maps to an honest spoken
/// status line (rule 12).
enum TurnFailure { timeout, lostTrack, connection, cancelled }

/// Everything one model turn needs.
class TurnInput {
  const TurnInput({
    required this.context,
    required this.intent,
    required this.registry,
    this.ocr = OcrResult.empty,
  });

  final TurnContext context;
  final IntentType intent;

  /// A working copy; the pipeline applies guard 6 and registry updates to
  /// it. The caller keeps it only if the turn succeeds.
  final ObjectRegistry registry;
  final OcrResult ocr;
}

/// The result of one model turn, ready to speak and log.
class TurnOutcome {
  const TurnOutcome({
    required this.spokenText,
    this.reply,
    this.response,
    this.registry,
    this.challenge = ChallengeOutcome.none,
    this.rawModelText = const [],
    this.guardEvents = const [],
    this.failure,
  });

  /// What BIFROST says. Always composed from templates.
  final String spokenText;
  final SpokenReply? reply;

  /// The guarded response, with registry ids and labels.
  final VlmResponse? response;

  /// The updated registry (only on success).
  final ObjectRegistry? registry;
  final ChallengeOutcome challenge;

  /// Raw model output of each attempt, for the turn log.
  final List<String> rawModelText;
  final List<GuardEvent> guardEvents;
  final TurnFailure? failure;

  bool get isSuccess => failure == null;
}

/// Runs steps 5–10 of the turn pipeline (Section 7): build the request,
/// call the model, validate the JSON (retry once), apply guards in order,
/// update the registry and compose speech. Free of Flutter plugins so it
/// can be tested with fixtures.
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
    TurnInput input, {
    CancelToken? cancel,
  }) async {
    final l10n = lookupAppLocalizations(settings.language.locale);
    final token = cancel ?? CancelToken();
    final raws = <String>[];
    try {
      return await _run(
        settings,
        input,
        token,
        l10n,
        raws,
      ).timeout(Duration(seconds: settings.timeoutS));
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
    TurnInput input,
    CancelToken token,
    AppLocalizations l10n,
    List<String> raws,
  ) async {
    final messages = await prompts.messages(settings, input.context);
    var response = await _attempt(settings, messages, token, raws);
    String? retryWith;
    if (response == null) {
      retryWith = await prompts.retryInstruction(settings);
    } else if (!Guards.clarificationValid(response)) {
      retryWith = await prompts.clarificationRetryInstruction(settings);
    }
    if (retryWith != null) {
      final retry = [
        ...messages,
        {'role': 'assistant', 'content': raws.last},
        {'role': 'user', 'content': retryWith},
      ];
      response = await _attempt(settings, retry, token, raws) ?? response;
    }
    if (response == null) {
      return _fail(TurnFailure.lostTrack, l10n.lostTrack, raws);
    }
    return answer(response, input, l10n, raws);
  }

  /// Applies guards and registry updates, then composes speech, for an
  /// already-parsed response.
  TurnOutcome answer(
    VlmResponse response,
    TurnInput input,
    AppLocalizations l10n, [
    List<String> raws = const [],
  ]) {
    final events = <GuardEvent>[];
    final registry = input.registry;

    // Guard 5: exactly two options, or we cannot ask.
    final valid = guards.fixClarification(response, events);
    if (valid == null) {
      return _fail(TurnFailure.lostTrack, l10n.lostTrack, raws);
    }

    // Guard 6: app-owned labels. Register in model order first so a new
    // task's objects are numbered as the model listed them.
    for (final u in valid.registryUpdates) {
      registry.resolve(
        modelId: u.id,
        modelLabel: u.label,
        shortDescription: u.shortDescription,
        location: u.location,
      );
    }
    var r = _stabilizeLabels(valid, registry, events);
    final referent = valid.needsClarification
        ? null
        : registry.byId(r.referent?.id);
    final previous = referent?.copy();

    r = guards.confidenceConsistency(r, events);
    r = guards.ocrCrossCheck(r, input.ocr, l10n.reasonLabelHardToRead, events);
    var challenge = ChallengeOutcome.none;
    if (input.intent == IntentType.challenge) {
      final c = guards.challenge(r, previous, events);
      r = c.response;
      challenge = c.outcome;
    }
    r = guards.noGuessFilling(r, events);
    r = guards.bannedPhrases(r, events);

    _applyIdentities(r, registry, referent, challenge);

    final composed = SpeechComposer(l10n).compose(
      r,
      ComposeExtras(
        challenge: challenge,
        previous: previous,
        taskObjectCount: input.intent == IntentType.startTask
            ? registry.length
            : null,
      ),
    );
    final reply = guards.lengthCap(composed, events);
    return TurnOutcome(
      spokenText: reply.text,
      reply: reply,
      response: r,
      registry: registry,
      challenge: challenge,
      rawModelText: List.unmodifiable(raws),
      guardEvents: events,
    );
  }

  /// Guard 6: rewrites the referent and registry updates to the app's ids
  /// and labels.
  VlmResponse _stabilizeLabels(
    VlmResponse r,
    ObjectRegistry registry,
    List<GuardEvent> log,
  ) {
    final ref = r.referent;
    Referent? stable;
    if (ref != null && !r.needsClarification) {
      final obj = registry.resolve(
        modelId: ref.id,
        modelLabel: ref.label,
        shortDescription: ref.shortDescription,
      );
      if (obj.label != ref.label || obj.id != ref.id) {
        log.add(
          GuardEvent(
            'label_stability',
            '${ref.id}/${ref.label}',
            '${obj.id}/${obj.label}',
          ),
        );
      }
      stable = ref.copyWith(id: obj.id, label: obj.label);
    }
    return r.copyWith(
      referent: stable ?? ref,
      registryUpdates: [
        for (final u in r.registryUpdates)
          u.copyWith(
            id: registry.byId(u.id)!.id,
            label: registry.byId(u.id)!.label,
          ),
      ],
    );
  }

  /// Stores what this turn established about each object. A weaker answer
  /// never overwrites a READ identification, and a rejected challenge
  /// changes nothing about the referent.
  void _applyIdentities(
    VlmResponse r,
    ObjectRegistry registry,
    RegisteredObject? referent,
    ChallengeOutcome challenge,
  ) {
    for (final u in r.registryUpdates) {
      final obj = registry.byId(u.id);
      if (obj == null || obj.id == referent?.id || u.identifiedAs.isEmpty) {
        continue;
      }
      if (obj.confidence == Confidence.read) continue;
      obj
        ..identifiedAs = u.identifiedAs
        ..confidence = Confidence.think;
    }
    if (referent == null ||
        challenge == ChallengeOutcome.rejected ||
        r.confidence == Confidence.cantSee) {
      return;
    }
    final identity = Guards.identityOf(r);
    if (identity.isEmpty) return;
    if (referent.confidence == Confidence.read &&
        r.confidence != Confidence.read) {
      return;
    }
    referent
      ..identifiedAs = identity
      ..readText = r.confidence == Confidence.read ? r.readText : ''
      ..confidence = r.confidence
      ..confidenceReason = r.confidenceReason;
  }

  Future<VlmResponse?> _attempt(
    AppSettings settings,
    List<Map<String, dynamic>> messages,
    CancelToken token,
    List<String> raws,
  ) async {
    final buffer = StringBuffer();
    await for (final delta in client.streamChat(
      settings,
      messages,
      cancel: token,
    )) {
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
