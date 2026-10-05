import 'package:dio/dio.dart';

import '../../l10n/gen/app_localizations.dart';
import '../intent/intent_classifier.dart';
import '../model/prompt_builder.dart';
import '../model/vlm_response.dart';
import '../settings/app_settings.dart';
import '../text/text_normalize.dart';
import '../turn/turn_pipeline.dart';
import '../vision/ocr_result.dart';
import '../vision/scene_monitor.dart';
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

  /// True right after "Want me to tell you when I can read it?".
  bool pendingWatchOffer = false;

  /// The last question that went to the model; watch mode asks it again.
  String lastQuestion = '';
}

/// Why the engine answered before calling the model (Section 7, step 3).
enum PreCheck {
  /// Nothing detected in the camera stream: aim first.
  nothingInView,

  /// Too much glare on the target.
  glare,
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
    this.startWatch = false,
    this.preCheck,
    this.referentBox,
    this.offeredWatch = false,
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

  /// Watch mode should start now (WATCH intent, or "yes" to the offer).
  final bool startWatch;

  /// Set when the pre-check answered instead of the model.
  final PreCheck? preCheck;

  /// The referent's box in the image, for locking the guidance target.
  final List<double>? referentBox;

  /// The reply ended with the watch-mode offer.
  final bool offeredWatch;

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
  ///
  /// [scene] returns the latest camera-stream snapshot (null when there is
  /// no stream, e.g. in the simulator). [onEarlyReferent] receives the
  /// referent phrase when it can be spoken before the full answer.
  Future<EngineReply> handle({
    required String transcript,
    required AppSettings settings,
    required IntentClassifier classifier,
    required Future<CapturedFrame?> Function() capture,
    CancelToken? cancel,
    SceneSnapshot? Function()? scene,
    void Function(String phrase)? onEarlyReferent,
  }) async {
    final l10n = lookupAppLocalizations(settings.language.locale);

    // Answer to "Want me to tell you when I can read it?"
    if (state.pendingWatchOffer) {
      state.pendingWatchOffer = false;
      if (classifier.isYes(transcript)) {
        return _local(
          const Intent(IntentType.watch),
          l10n.watchStarted,
          startWatch: true,
        );
      }
      if (classifier.isNo(transcript)) {
        return _local(const Intent(IntentType.ask), l10n.watchDeclined);
      }
    }

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
        return _local(intent, l10n.watchStarted, startWatch: true);
      case IntentType.startTask:
        _startTask(intent, l10n);
      case IntentType.ask:
      case IntentType.challenge:
      case IntentType.repair:
        if (state.registry.length == 0) {
          state.registry = ObjectRegistry(fallbackNoun: l10n.itemNoun);
        }
    }

    final check = _preCheck(intent, scene?.call());
    if (check != null) {
      return _local(
        intent,
        check == PreCheck.glare ? l10n.glare : l10n.aimNothingInView,
        preCheck: check,
      );
    }
    return _askModel(
      transcript: transcript,
      intent: intent,
      settings: settings,
      classifier: classifier,
      capture: capture,
      cancel: cancel,
      onEarlyReferent: onEarlyReferent,
    );
  }

  /// Watch mode found readable text: ask the last question again as ASK
  /// (Section 12).
  Future<EngineReply> handleWatchTrigger({
    required AppSettings settings,
    required IntentClassifier classifier,
    required Future<CapturedFrame?> Function() capture,
    CancelToken? cancel,
  }) {
    final question = state.lastQuestion.isEmpty
        ? lookupAppLocalizations(settings.language.locale).watchQuestion
        : state.lastQuestion;
    return _askModel(
      transcript: question,
      intent: const Intent(IntentType.ask),
      settings: settings,
      classifier: classifier,
      capture: capture,
      cancel: cancel,
    );
  }

  /// Section 7 step 3: no object or glare -> speak a hint instead of
  /// calling the model. START_TASK and search tasks always need the whole
  /// scene, so they skip it.
  PreCheck? _preCheck(Intent intent, SceneSnapshot? scene) {
    if (scene == null) return null;
    if (intent.type == IntentType.startTask || state.task.type == 'find') {
      return null;
    }
    if (!scene.hasObject) return PreCheck.nothingInView;
    if (scene.glareFraction > glareThreshold) return PreCheck.glare;
    return null;
  }

  /// Glare fraction above which the pre-check speaks the glare hint.
  double glareThreshold = 0.15;

  Future<EngineReply> _askModel({
    required String transcript,
    required Intent intent,
    required AppSettings settings,
    required IntentClassifier classifier,
    required Future<CapturedFrame?> Function() capture,
    CancelToken? cancel,
    void Function(String phrase)? onEarlyReferent,
  }) async {
    final l10n = lookupAppLocalizations(settings.language.locale);
    if (!settings.isServerConfigured) return _local(intent, l10n.notConfigured);
    final frame = await capture();
    if (frame == null) return _local(intent, l10n.noImage);
    state.lastQuestion = transcript;

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
        onEarlyReferent: onEarlyReferent,
      ),
      cancel: cancel,
    );
    if (outcome.failure == TurnFailure.cancelled) {
      return EngineReply(text: '', intent: intent, outcome: outcome);
    }
    _remember(transcript, outcome);

    // After CANT_SEE, offer watch mode (Section 12).
    final cantSee = outcome.reply?.confidence == Confidence.cantSee;
    var text = outcome.spokenText;
    if (cantSee) {
      text = '$text ${l10n.watchOffer}';
      state
        ..pendingWatchOffer = true
        ..lastSpoken = text;
    }
    return EngineReply(
      text: text,
      intent: intent,
      outcome: outcome,
      confidence: outcome.reply?.confidence,
      isClarification: outcome.reply?.isClarification ?? false,
      ocrTokens: frame.ocr.tokens.toList(),
      referentBox: outcome.response?.referent?.bbox,
      offeredWatch: cantSee,
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

  EngineReply _local(
    Intent intent,
    String text, {
    bool remember = true,
    bool startWatch = false,
    PreCheck? preCheck,
  }) {
    if (remember) state.lastSpoken = text;
    return EngineReply(
      text: text,
      intent: intent,
      startWatch: startWatch,
      preCheck: preCheck,
    );
  }

  static String _join(List<String> items, AppLocalizations l10n) {
    if (items.length <= 1) return items.join();
    return '${items.sublist(0, items.length - 1).join('; ')} ${l10n.listAnd} ${items.last}';
  }
}
