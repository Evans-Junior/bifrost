import 'package:dio/dio.dart';

import '../../l10n/gen/app_localizations.dart';
import '../intent/intent_classifier.dart';
import '../model/prompt_builder.dart';
import '../model/vlm_response.dart';
import '../settings/app_settings.dart';
import '../text/text_normalize.dart';
import '../turn/turn_pipeline.dart';
import '../vision/ocr_result.dart';
import 'object_registry.dart';
import 'task_memory.dart';

/// A captured still prepared for the model, with its on-device OCR.
class CapturedFrame {
  const CapturedFrame(this.imageBase64, [this.ocr = OcrResult.empty]);

  final String imageBase64;
  final OcrResult ocr;
}

/// Everything the conversation remembers between turns.
class ConversationState {
  ObjectRegistry registry = ObjectRegistry();
  TaskMemory task = TaskMemory();
  final List<PastTurn> history = [];
  String lastSpoken = '';
  String lastDetail = '';

  /// Options of the clarification question just asked, if any.
  List<String> pendingClarification = const [];

  /// The registry id of the object the last answer was about.
  String? lastReferentId;
}

/// What the engine decided for one utterance.
class EngineReply {
  const EngineReply({
    required this.text,
    required this.intent,
    this.outcome,
    this.confidence,
    this.isClarification = false,
    this.ocrTokens = const [],
  });

  /// Text to speak (may be empty when a turn was cancelled).
  final String text;
  final Intent intent;

  /// The model turn, when one was made.
  final TurnOutcome? outcome;
  final Confidence? confidence;
  final bool isClarification;

  /// Normalized words on-device OCR found in the still, for the log.
  final List<String> ocrTokens;

  bool get usedModel => outcome != null;
}

/// Phase 2 conversation logic (Sections 6–8): classifies each utterance,
/// answers STATUS, REPEAT, MORE and STOP locally, and otherwise builds the
/// model request with registry, task state and repair/challenge context.
/// Pure Dart: the camera is passed in as [capture], so the scripted test
/// runs on fixtures.
class ConversationEngine {
  ConversationEngine(this.pipeline);

  final TurnPipeline pipeline;
  ConversationState state = ConversationState();

  /// Handles one utterance.
  Future<EngineReply> handle({
    required String transcript,
    required AppSettings settings,
    required IntentClassifier classifier,
    required Future<CapturedFrame?> Function() capture,
    CancelToken? cancel,
  }) async {
    final l10n = lookupAppLocalizations(settings.language.locale);
    final intent = classifier.classify(transcript);
    switch (intent.type) {
      case IntentType.stop:
        return _local(intent, l10n.stopped, remember: false);
      case IntentType.repeat:
        final last = state.lastSpoken;
        return _local(
          intent,
          last.isEmpty ? l10n.repeatNone : last,
          remember: false,
        );
      case IntentType.more:
        final detail = state.lastDetail;
        return _local(intent, detail.isEmpty ? l10n.moreNone : detail);
      case IntentType.status:
        return _local(intent, statusText(l10n));
      case IntentType.watch:
        return _local(intent, l10n.watchNotReady);
      case IntentType.startTask:
        _startTask(intent, l10n);
      case IntentType.ask:
      case IntentType.challenge:
      case IntentType.repair:
        if (state.registry.length == 0) {
          state.registry = ObjectRegistry(fallbackNoun: l10n.itemNoun);
        }
    }

    if (!settings.isServerConfigured) return _local(intent, l10n.notConfigured);
    final frame = await capture();
    if (frame == null) return _local(intent, l10n.noImage);

    final outcome = await pipeline.run(
      settings,
      TurnInput(
        context: TurnContext(
          transcript: transcript,
          intent: intent.type.wire,
          imageBase64Jpeg: frame.imageBase64,
          objectRegistry: state.registry.toPrompt(),
          taskState: state.task.toPrompt(state.registry),
          recentTurns: List.of(state.history),
          ocrText: frame.ocr.toPrompt(),
          extras: _extras(intent, classifier),
        ),
        intent: intent.type,
        registry: state.registry.copy(),
        ocr: frame.ocr,
      ),
      cancel: cancel,
    );
    if (outcome.failure == TurnFailure.cancelled) {
      return EngineReply(text: '', intent: intent, outcome: outcome);
    }
    _remember(transcript, outcome);
    return EngineReply(
      text: outcome.spokenText,
      intent: intent,
      outcome: outcome,
      confidence: outcome.reply?.confidence,
      isClarification: outcome.reply?.isClarification ?? false,
      ocrTokens: frame.ocr.tokens.toList(),
    );
  }

  /// The STATUS answer, built only from task memory (rule 8).
  String statusText(AppLocalizations l10n) {
    final registry = state.registry;
    final task = state.task;
    if (!task.isActive && registry.length == 0) return l10n.statusNoTask;
    final parts = <String>[];
    if (task.type == 'find' && task.goal != null) {
      parts.add(l10n.statusFinding(task.goal!));
    }
    final done = task.done(registry);
    final left = task.left(registry);
    if (done.isEmpty && left.isEmpty) {
      return [...parts, l10n.statusNoItems].join(' ');
    }
    parts.add(
      done.isEmpty
          ? l10n.statusNothingDone
          : l10n.statusDone(
              _join([
                for (final o in done)
                  l10n.statusItem(
                    o.label,
                    TextNormalize.speakable(o.identifiedAs),
                  ),
              ], l10n),
            ),
    );
    parts.add(
      left.isEmpty
          ? l10n.statusNothingLeft
          : l10n.statusLeft(_join([for (final o in left) o.label], l10n)),
    );
    return parts.join(' ');
  }

  void _startTask(Intent intent, AppLocalizations l10n) {
    state
      ..registry = ObjectRegistry(fallbackNoun: l10n.itemNoun)
      ..task = TaskMemory(type: intent.task, goal: intent.goal)
      ..pendingClarification = const []
      ..lastReferentId = null;
  }

  /// REPAIR and CHALLENGE context for the request.
  Map<String, Object?> _extras(Intent intent, IntentClassifier classifier) {
    final registry = state.registry;
    final last = registry.byId(state.lastReferentId);
    switch (intent.type) {
      case IntentType.repair:
        final extras = <String, Object?>{};
        final byNumber = intent.number == null
            ? null
            : registry.byNumber(intent.number!);
        if (byNumber != null) {
          extras['CHOSEN_REFERENT'] = byNumber.toPrompt();
          return extras;
        }
        final options = state.pendingClarification;
        if (options.isNotEmpty) {
          extras['CLARIFICATION_OPTIONS'] = options;
          final chosen = pickOption(options, intent.relation, classifier);
          if (chosen != null) {
            extras['CHOSEN_REFERENT'] = {'description': chosen};
          }
        } else if (last != null) {
          extras['PREVIOUS_REFERENT'] = last.toPrompt();
        }
        if (intent.relation != null) {
          extras['REPAIR_RELATION'] = intent.relation;
        }
        return extras;
      case IntentType.challenge:
        if (last == null) return const {};
        return {
          'PREVIOUS_ANSWER': {
            ...last.toPrompt(),
            if (last.readText.isNotEmpty) 'read_text': last.readText,
            if (last.confidence != null) 'confidence': last.confidence!.name,
          },
        };
      default:
        return const {};
    }
  }

  /// Picks the clarification option a one-phrase repair refers to, e.g.
  /// "the closer one" -> "the jar closer to you". Null if not exactly one.
  static String? pickOption(
    List<String> options,
    String? relation,
    IntentClassifier classifier,
  ) {
    if (relation == null) return null;
    final words = classifier.relationWords(relation);
    final hits = [
      for (final o in options)
        if (words.any(
          (w) => ' ${TextNormalize.forMatching(o)} '.contains(' $w '),
        ))
          o,
    ];
    return hits.length == 1 ? hits.single : null;
  }

  void _remember(String transcript, TurnOutcome outcome) {
    state.lastSpoken = outcome.spokenText;
    if (!outcome.isSuccess) return;
    final response = outcome.response!;
    state
      ..registry = outcome.registry ?? state.registry
      ..lastDetail = outcome.reply?.detail ?? ''
      ..pendingClarification = response.needsClarification
          ? response.clarificationOptions
          : const []
      ..lastReferentId = response.needsClarification
          ? state.lastReferentId
          : (response.referent?.id ?? state.lastReferentId);
    state.history.add(
      PastTurn(user: transcript, assistant: outcome.spokenText),
    );
  }

  EngineReply _local(Intent intent, String text, {bool remember = true}) {
    if (remember) state.lastSpoken = text;
    return EngineReply(text: text, intent: intent);
  }

  static String _join(List<String> items, AppLocalizations l10n) {
    if (items.length <= 1) return items.join();
    return '${items.sublist(0, items.length - 1).join('; ')} ${l10n.listAnd} ${items.last}';
  }
}
