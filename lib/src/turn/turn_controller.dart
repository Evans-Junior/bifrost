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
import '../logging/turn_logger.dart';
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

/// Runs the voice loop: hold to talk, classify, answer locally or capture
/// and ask the model, speak the guarded answer. Only one turn is in flight;
/// a new press cancels the current turn and any speech.
class TurnController extends Notifier<TurnState> {
  /// Speak "checking…" if nothing has been said this long after release.
  static const checkingDelay = Duration(milliseconds: 1500);

  CancelToken? _cancel;
  int _turnId = 0;
  bool _held = false;

  CameraService get _camera => ref.read(cameraServiceProvider);
  SttService get _stt => ref.read(sttServiceProvider);
  TtsService get _tts => ref.read(ttsServiceProvider);

  @override
  TurnState build() => const TurnState();

  /// Opens the camera; called once the home screen is shown.
  Future<bool> startCamera() async {
    final ok = await _camera.start();
    if (!ok) state = state.copyWith(status: TurnStatus.noCamera);
    return ok;
  }

  /// Hold-to-talk pressed: cancel everything in flight and start listening.
  Future<void> pressStart() async {
    _held = true;
    _turnId++;
    _cancel?.cancel('new utterance');
    await _tts.stop();
    final settings = await ref.read(settingsProvider.future);
    await HapticFeedback.selectionClick();
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
    if (transcript.isEmpty) return _say(_l10n(settings).didNotHear, settings);
    await handleTranscript(transcript, releasedAt: released);
  }

  /// Handles one utterance. Also used to type a question in the simulator,
  /// where there is no microphone.
  Future<void> handleTranscript(
    String transcript, {
    DateTime? releasedAt,
  }) async {
    final times = TurnTimes(releasedAt ?? DateTime.now());
    final id = ++_turnId;
    _cancel?.cancel('new utterance');
    await _tts.stop();
    final settings = await ref.read(settingsProvider.future);
    final l10n = _l10n(settings);
    final engine = await ref.read(conversationEngineProvider.future);
    final classifier = await ref.read(
      intentClassifierProvider(settings.language.code).future,
    );
    state = state.copyWith(
      status: TurnStatus.checking,
      lastTranscript: transcript,
    );
    await _tts.configure(settings.language, settings.speechRate);

    Future<void>? checkingSpeech;
    final checkingTimer = Timer(checkingDelay, () {
      if (id != _turnId) return;
      times.firstAudio ??= DateTime.now();
      checkingSpeech = _tts.speak(l10n.checking);
    });
    _cancel = CancelToken();
    final reply = await engine.handle(
      transcript: transcript,
      settings: settings,
      classifier: classifier,
      capture: _capture,
      cancel: _cancel,
    );
    times.fullAnswer = DateTime.now();
    checkingTimer.cancel();
    if (id != _turnId || reply.text.isEmpty) return;
    await checkingSpeech;
    if (id != _turnId) return;

    _logReply(transcript, reply);
    if (reply.outcome?.isSuccess ?? false) await HapticFeedback.lightImpact();
    times.firstAudio ??= DateTime.now();
    await _say(
      reply.text,
      settings,
      after: reply.outcome?.failure == TurnFailure.connection
          ? TurnStatus.offline
          : TurnStatus.ready,
    );
    times.speechEnd = DateTime.now();
    final logger = ref.read(turnLoggerProvider);
    await logger.write(
      logger.entry(
        transcript: transcript,
        reply: reply,
        state: engine.state,
        settings: settings,
        times: times,
      ),
      settings,
    );
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

  AppLocalizations _l10n(AppSettings s) =>
      lookupAppLocalizations(s.language.locale);

  /// Console log; the uploaded turn log is added separately.
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
