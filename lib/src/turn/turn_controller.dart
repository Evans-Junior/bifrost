import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../camera/camera_service.dart';
import '../model/model_client.dart';
import '../model/prompt_builder.dart';
import '../settings/app_settings.dart';
import '../settings/settings_repository.dart';
import '../speech/stt_service.dart';
import '../speech/tts_service.dart';
import '../vision/image_prep.dart';
import 'turn_pipeline.dart';

/// What the app is doing right now. Announced to screen readers (rule 12).
enum TurnStatus { ready, listening, checking, speaking, offline, noCamera }

/// UI-facing state of the voice loop.
@immutable
class TurnState {
  const TurnState({
    this.status = TurnStatus.ready,
    this.lastSpoken = '',
    this.lastDetail = '',
  });

  final TurnStatus status;
  final String lastSpoken;

  /// Detail held back for MORE (answered locally from Phase 2).
  final String lastDetail;

  TurnState copyWith({
    TurnStatus? status,
    String? lastSpoken,
    String? lastDetail,
  }) =>
      TurnState(
        status: status ?? this.status,
        lastSpoken: lastSpoken ?? this.lastSpoken,
        lastDetail: lastDetail ?? this.lastDetail,
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
final modelClientProvider =
    Provider<ModelClient>((ref) => OpenAiCompatibleClient());

/// Provides the turn pipeline.
final turnPipelineProvider = Provider<TurnPipeline>(
  (ref) => TurnPipeline(
    client: ref.watch(modelClientProvider),
    prompts: PromptBuilder(BundlePromptAssets()),
  ),
);

/// Runs the Phase 1 voice loop: hold to talk, capture, ask the model,
/// speak the guarded answer. Only one turn is in flight; a new press
/// cancels the current turn and any speech.
class TurnController extends Notifier<TurnState> {
  /// Speak "checking…" if nothing has been said this long after release.
  static const checkingDelay = Duration(milliseconds: 1500);

  CancelToken? _cancel;
  int _turnId = 0;
  bool _held = false;
  final List<PastTurn> _history = [];

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

  /// Hold-to-talk released: take the transcript and run a turn.
  Future<void> pressEnd() async {
    _held = false;
    if (state.status != TurnStatus.listening) return;
    final id = _turnId;
    final settings = await ref.read(settingsProvider.future);
    final l10n = _l10n(settings);
    state = state.copyWith(status: TurnStatus.checking);
    final transcript = (await _stt.stop()).trim();
    if (id != _turnId) return;
    if (transcript.isEmpty) return _say(l10n.didNotHear, settings);
    if (!settings.isServerConfigured) {
      return _say(l10n.notConfigured, settings);
    }
    await _runTurn(id, transcript, settings, l10n);
  }

  Future<void> _runTurn(
    int id,
    String transcript,
    AppSettings settings,
    AppLocalizations l10n,
  ) async {
    await _tts.configure(settings.language, settings.speechRate);
    Future<void>? checkingSpeech;
    final checkingTimer = Timer(checkingDelay, () {
      if (id == _turnId) checkingSpeech = _tts.speak(l10n.checking);
    });

    final still = await _camera.captureStill();
    if (still == null) {
      checkingTimer.cancel();
      return _say(_camera.isReady ? l10n.noImage : l10n.noCamera, settings);
    }
    final image = await ImagePrep.toModelJpegBase64(still);
    if (id != _turnId) return checkingTimer.cancel();

    _cancel = CancelToken();
    final outcome = await ref.read(turnPipelineProvider).run(
          settings,
          TurnContext(
            transcript: transcript,
            intent: 'ASK',
            imageBase64Jpeg: image,
            recentTurns: List.of(_history),
          ),
          cancel: _cancel,
        );
    checkingTimer.cancel();
    if (id != _turnId || outcome.failure == TurnFailure.cancelled) return;
    await checkingSpeech;
    if (id != _turnId) return;

    _logOutcome(transcript, outcome);
    if (outcome.isSuccess) {
      _history.add(PastTurn(user: transcript, assistant: outcome.spokenText));
      await HapticFeedback.lightImpact();
    }
    await _say(
      outcome.spokenText,
      settings,
      detail: outcome.reply?.detail ?? '',
      after: outcome.failure == TurnFailure.connection
          ? TurnStatus.offline
          : TurnStatus.ready,
    );
  }

  Future<void> _say(
    String text,
    AppSettings settings, {
    String detail = '',
    TurnStatus after = TurnStatus.ready,
  }) async {
    final id = _turnId;
    state = TurnState(
      status: TurnStatus.speaking,
      lastSpoken: text,
      lastDetail: detail,
    );
    await _tts.configure(settings.language, settings.speechRate);
    await _tts.speak(text);
    if (id == _turnId) state = state.copyWith(status: after);
  }

  AppLocalizations _l10n(AppSettings s) =>
      lookupAppLocalizations(s.language.locale);

  /// Temporary console log until turn logging lands in Phase 5.
  void _logOutcome(String transcript, TurnOutcome o) {
    debugPrint('[turn] "$transcript" -> "${o.spokenText}" '
        'failure=${o.failure} guards=${o.guardEvents}');
  }
}

/// The app-wide turn controller.
final turnControllerProvider =
    NotifierProvider<TurnController, TurnState>(TurnController.new);
