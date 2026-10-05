import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../camera/camera_service.dart';
import '../model/model_client.dart';
import '../conversation/conversation_engine.dart';
import '../guards/banned_phrases.dart';
import '../guards/guards.dart';
import '../intent/intent_classifier.dart';
import '../model/prompt_builder.dart';
import '../settings/app_settings.dart';
import '../settings/settings_repository.dart';
import '../speech/stt_service.dart';
import '../speech/tts_service.dart';
import '../audio/earcons.dart';
import '../guidance/haptic_player.dart';
import '../logging/turn_logger.dart';
import '../perception/perception_controller.dart';
import '../vision/stream_analyzer.dart';
import '../vision/image_prep.dart';
import '../vision/sample_image.dart';
import '../vision/ocr_service.dart';
import 'turn_pipeline.dart';

/// What the app is doing right now. Announced to screen readers (rule 12).
enum TurnStatus { ready, listening, checking, speaking, offline, noCamera }

/// UI-facing state of the voice loop.
@immutable
class TurnState {
  const TurnState({
    this.status = TurnStatus.ready,
    this.lastSpoken = '',
    this.lastTranscript = '',
  });

  final TurnStatus status;
  final String lastSpoken;

  /// What the user last said, shown on screen for researchers.
  final String lastTranscript;

  TurnState copyWith({
    TurnStatus? status,
    String? lastSpoken,
    String? lastTranscript,
  }) => TurnState(
    status: status ?? this.status,
    lastSpoken: lastSpoken ?? this.lastSpoken,
    lastTranscript: lastTranscript ?? this.lastTranscript,
  );
}

/// Provides the rear camera.
final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(service.stop);
  return service;
});

/// Provides speech-to-text.
final sttServiceProvider = Provider<SttService>((ref) => SttService());

/// Provides text-to-speech.
final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

/// Provides the model client.
final modelClientProvider = Provider<ModelClient>(
  (ref) => OpenAiCompatibleClient(),
);

/// Provides on-device OCR.
final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.close);
  return service;
});

/// Intent rules for a language code (`en`, `fr`).
final intentClassifierProvider =
    FutureProvider.family<IntentClassifier, String>(
      (ref, code) => IntentClassifier.load(code),
    );

/// The conversation engine, with guards loaded from assets. Kept for the
/// whole session so the registry and task memory persist.
final conversationEngineProvider = FutureProvider<ConversationEngine>((
  ref,
) async {
  final banned = await BannedPhrases.load();
  return ConversationEngine(
    TurnPipeline(
      client: ref.watch(modelClientProvider),
      prompts: PromptBuilder(BundlePromptAssets()),
      guards: Guards(banned: banned),
    ),
  );
});

/// Writes turn logs for this app session.
final turnLoggerProvider = Provider<TurnLogger>((ref) => TurnLogger());

/// Plays earcons.
final earconPlayerProvider = Provider<EarconPlayer>((ref) => EarconPlayer());

/// Camera-stream analysis, vibration guidance and watch mode.
final perceptionProvider = Provider<PerceptionController>((ref) {
  final p = PerceptionController(
    analyzer: StreamAnalyzer(ref.read(cameraServiceProvider)),
    haptics: HapticPlayer(),
    earcons: ref.read(earconPlayerProvider),
  );
  ref.onDispose(p.dispose);
  return p;
});

/// Runs the voice loop: hold to talk, classify, answer locally or capture
/// and ask the model, speak the guarded answer. Only one turn is in flight;
/// a new press cancels the current turn, watch mode and any speech.
class TurnController extends Notifier<TurnState> {
  /// Speak "checking…" if nothing has been said this long after release.
  static const checkingDelay = Duration(milliseconds: 1500);

  CancelToken? _cancel;
  int _turnId = 0;
  bool _held = false;
  bool _turnActive = false;

  /// Everything spoken in a turn goes through this queue, in order.
  Future<void> _speech = Future.value();

  CameraService get _camera => ref.read(cameraServiceProvider);
  SttService get _stt => ref.read(sttServiceProvider);
  TtsService get _tts => ref.read(ttsServiceProvider);
  EarconPlayer get _earcons => ref.read(earconPlayerProvider);
  PerceptionController get _perception => ref.read(perceptionProvider);

  @override
  TurnState build() {
    final p = ref.read(perceptionProvider);
    p.onHint = _onHint;
    p.onWatchTrigger = _onWatchTrigger;
    ref.listen(settingsProvider, (_, next) {
      final s = next.value;
      if (s != null) p.applySettings(s);
    });
    return const TurnState();
  }

  /// Opens the camera and starts stream analysis; called by the home screen.
  Future<bool> startCamera() async {
    final ok = await _camera.start();
    if (!ok) {
      state = state.copyWith(status: TurnStatus.noCamera);
      return false;
    }
    final settings = await ref.read(settingsProvider.future);
    await _perception.start(settings);
    return true;
  }

  /// Stops the camera stream and vibration (app in the background).
  Future<void> stopCamera() async {
    await _perception.stop();
    await _camera.stop();
  }

  /// Hold-to-talk pressed: cancel everything in flight and start listening.
  Future<void> pressStart() async {
    _held = true;
    _turnId++;
    _cancel?.cancel('new utterance');
    _perception
      ..cancelWatch()
      ..suspend();
    await _tts.stop();
    final settings = await ref.read(settingsProvider.future);
    await HapticFeedback.selectionClick();
    unawaited(_earcons.play(Earcon.listen, enabled: settings.feedback.earcons));
    state = state.copyWith(status: TurnStatus.listening);
    final ok = await _stt.start(settings.language.sttLocaleId);
    if (!ok) return _say(_l10n(settings).noMicrophone, settings);
    // Released while the microphone was still starting.
    if (!_held) await pressEnd();
  }

  /// Hold-to-talk released: take the transcript and handle it.
  Future<void> pressEnd() async {
    _held = false;
    if (state.status != TurnStatus.listening) return;
    final id = _turnId;
    final released = DateTime.now();
    final settings = await ref.read(settingsProvider.future);
    state = state.copyWith(status: TurnStatus.checking);
    final transcript = (await _stt.stop()).trim();
    if (id != _turnId) return;
    if (transcript.isEmpty) {
      _perception.resume();
      return _say(_l10n(settings).didNotHear, settings);
    }
    await handleTranscript(transcript, releasedAt: released);
  }

  /// Handles one utterance. Also used to type a question in the simulator,
  /// where there is no microphone.
  Future<void> handleTranscript(
    String transcript, {
    DateTime? releasedAt,
  }) async {
    await _runTurn(
      transcript: transcript,
      releasedAt: releasedAt,
      ask: (engine, settings, classifier, cancel, onEarly) => engine.handle(
        transcript: transcript,
        settings: settings,
        classifier: classifier,
        capture: _capture,
        cancel: cancel,
        scene: () => _perception.scene,
        onEarlyReferent: onEarly,
      ),
    );
  }

  /// Watch mode saw readable text: capture and ask again (Section 12).
  void _onWatchTrigger() {
    if (_turnActive) return;
    _runTurn(
      transcript: '(watch mode)',
      ask: (engine, settings, classifier, cancel, _) =>
          engine.handleWatchTrigger(
            settings: settings,
            classifier: classifier,
            capture: _capture,
            cancel: cancel,
          ),
    );
  }

  Future<void> _runTurn({
    required String transcript,
    DateTime? releasedAt,
    required Future<EngineReply> Function(
      ConversationEngine engine,
      AppSettings settings,
      IntentClassifier classifier,
      CancelToken cancel,
      void Function(String) onEarly,
    )
    ask,
  }) async {
    final times = TurnTimes(releasedAt ?? DateTime.now());
    final id = ++_turnId;
    _turnActive = true;
    _cancel?.cancel('new utterance');
    _perception
      ..cancelWatch()
      ..suspend();
    await _tts.stop();
    _speech = Future.value();
    final settings = await ref.read(settingsProvider.future);
    final l10n = _l10n(settings);
    final engine = await ref.read(conversationEngineProvider.future);
    engine.glareThreshold = settings.thresholds.glareFraction;
    final classifier = await ref.read(
      intentClassifierProvider(settings.language.code).future,
    );
    state = state.copyWith(
      status: TurnStatus.checking,
      lastTranscript: transcript,
    );
    await _tts.configure(settings.language, settings.speechRate);

    var spokeEarly = false;
    final checkingTimer = Timer(checkingDelay, () {
      if (id != _turnId || spokeEarly) return;
      times.firstAudio ??= DateTime.now();
      _enqueue(id, () => _tts.speak(l10n.checking));
    });
    void onEarly(String phrase) {
      if (id != _turnId) return;
      spokeEarly = true;
      times.firstAudio ??= DateTime.now();
      state = state.copyWith(status: TurnStatus.speaking, lastSpoken: phrase);
      _enqueue(id, () => _tts.speak(phrase));
    }

    _cancel = CancelToken();
    final reply = await ask(engine, settings, classifier, _cancel!, onEarly);
    times.fullAnswer = DateTime.now();
    checkingTimer.cancel();
    if (id != _turnId || reply.text.isEmpty) {
      if (id == _turnId) _turnActive = false;
      return;
    }

    _logReply(transcript, reply);
    if (reply.outcome?.isSuccess ?? false) {
      unawaited(HapticFeedback.lightImpact());
    }
    final outcome = reply.outcome;
    final rest = outcome?.spokenAfterEarly;
    final text = rest == null
        ? reply.text
        : (reply.offeredWatch ? '$rest ${l10n.watchOffer}' : rest);
    final earcon = _earconFor(reply);
    if (earcon != null) {
      times.firstAudio ??= DateTime.now();
      _enqueue(
        id,
        () => _earcons.play(earcon, enabled: settings.feedback.earcons),
      );
    }
    times.firstAudio ??= DateTime.now();
    state = state.copyWith(status: TurnStatus.speaking, lastSpoken: reply.text);
    _enqueue(id, () => _tts.speak(text));
    await _speech;
    times.speechEnd = DateTime.now();
    if (id != _turnId) return;
    _turnActive = false;
    state = state.copyWith(
      status: outcome?.failure == TurnFailure.connection
          ? TurnStatus.offline
          : TurnStatus.ready,
    );

    _afterReply(reply, engine);
    await _log(transcript, reply, engine, settings, times);
  }

  /// Starts guidance or watch mode as the reply requires.
  void _afterReply(EngineReply reply, ConversationEngine engine) {
    final search = engine.state.task.type == 'find';
    if (reply.intent.type == IntentType.stop) {
      _perception.stopAiming('stop');
    } else if (reply.startWatch) {
      _perception.startWatch();
    } else if (reply.preCheck == PreCheck.nothingInView) {
      _perception.startAiming();
    } else if (reply.referentBox != null) {
      if (!_perception.lockOn(reply.referentBox!, search: search) && search) {
        _perception.startAiming(search: true);
      }
    }
    _perception.resume();
  }

  /// The confidence, clarification or error earcon that precedes speech.
  static Earcon? _earconFor(EngineReply r) {
    final o = r.outcome;
    if (o == null) return null; // local answers have no earcon
    if (o.failure != null) return Earcon.error;
    if (r.isClarification) return Earcon.clarify;
    return Earcon.forConfidence(r.confidence);
  }

  void _enqueue(int id, Future<void> Function() speak) {
    _speech = _speech.then((_) => id == _turnId ? speak() : null);
  }

  /// Speaks a perception hint when nothing else is being said.
  Future<void> _onHint(Hint hint) async {
    if (_turnActive || state.status == TurnStatus.listening) return;
    final settings = await ref.read(settingsProvider.future);
    final l10n = _l10n(settings);
    final text = switch (hint) {
      Hint.nothingInView => l10n.aimNothingInView,
      Hint.glare => l10n.glare,
      Hint.blur => l10n.blur,
      Hint.watchTimeout => l10n.watchTimeout,
      Hint.cueLeft => l10n.dirLeft,
      Hint.cueRight => l10n.dirRight,
      Hint.cueUp => l10n.dirUp,
      Hint.cueDown => l10n.dirDown,
    };
    await _tts.configure(settings.language, settings.speechRate);
    await _tts.speak(text);
  }

  /// Captures a still, resizes it off the UI isolate and runs OCR on the
  /// exact image the model will see.
  Future<CapturedFrame?> _capture() async {
    final still =
        await _camera.captureStill() ??
        // Simulator only: no camera, so use a generated labelled jar.
        (kDebugMode && !_camera.isReady
            ? await SampleImage.jar('CUMIN')
            : null);
    if (still == null) return null;
    final image = await ImagePrep.prepare(still);
    final ocr = await ref
        .read(ocrServiceProvider)
        .readJpeg(image.jpeg, image.width, image.height);
    return CapturedFrame(image.base64, ocr);
  }

  Future<void> _say(
    String text,
    AppSettings settings, {
    TurnStatus after = TurnStatus.ready,
  }) async {
    final id = _turnId;
    state = state.copyWith(status: TurnStatus.speaking, lastSpoken: text);
    await _tts.configure(settings.language, settings.speechRate);
    await _tts.speak(text);
    if (id == _turnId) state = state.copyWith(status: after);
  }

  Future<void> _log(
    String transcript,
    EngineReply reply,
    ConversationEngine engine,
    AppSettings settings,
    TurnTimes times,
  ) async {
    final logger = ref.read(turnLoggerProvider);
    final entry =
        logger.entry(
            transcript: transcript,
            reply: reply,
            state: engine.state,
            settings: settings,
            times: times,
          )
          ..['perception_events'] = _perception.drainEvents()
          ..['thresholds'] = settings.thresholds.toJson()
          ..['early_referent'] = reply.outcome?.earlyReferent;
    await logger.write(entry, settings);
  }

  AppLocalizations _l10n(AppSettings s) =>
      lookupAppLocalizations(s.language.locale);

  /// Console log; the uploaded turn log is written by [_log].
  void _logReply(String transcript, EngineReply r) {
    debugPrint(
      '[turn] "$transcript" ${r.intent} -> "${r.text}" '
      'failure=${r.outcome?.failure} guards=${r.outcome?.guardEvents}',
    );
  }
}

/// The app-wide turn controller.
final turnControllerProvider = NotifierProvider<TurnController, TurnState>(
  TurnController.new,
);
