import 'dart:async';

import 'package:flutter/foundation.dart';

import '../audio/earcons.dart';
import '../guidance/guidance_controller.dart';
import '../guidance/haptic_player.dart';
import '../guidance/patterns.dart';
import '../guidance/target_tracker.dart';
import '../settings/app_settings.dart';
import '../vision/geometry.dart';
import '../vision/scene_monitor.dart';
import '../vision/stream_analyzer.dart';
import '../watch/watch_controller.dart';

/// Something the perception layer wants said. The turn controller decides
/// whether it can be spoken now (never over an answer).
enum Hint {
  nothingInView,
  glare,
  blur,
  watchTimeout,
  cueLeft,
  cueRight,
  cueUp,
  cueDown,
}

/// One logged aiming, glare, vibration or watch event (Section 13).
class PerceptionEvent {
  PerceptionEvent(this.type, [this.detail = '']) : at = DateTime.now();

  final String type;
  final String detail;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'type': type,
    if (detail.isNotEmpty) 'detail': detail,
  };
}

/// Runs everything that watches the live camera stream (Sections 5, 11,
/// 12): the stream analyser, glare and blur warnings, target locking,
/// vibration guidance and watch mode. Decisions are made by the pure
/// controllers ([GuidanceController], [TargetTracker], [SceneMonitor],
/// [WatchController]); this class only connects them to the device.
class PerceptionController {
  PerceptionController({
    required this.analyzer,
    required this.haptics,
    required this.earcons,
  });

  final StreamAnalyzer analyzer;
  final HapticPlayer haptics;
  final EarconPlayer earcons;

  final GuidanceController guidance = GuidanceController();
  final TargetTracker tracker = TargetTracker();
  final SceneMonitor monitor = SceneMonitor();
  final WatchController watch = WatchController();

  /// Called when a hint should be spoken.
  void Function(Hint hint)? onHint;

  /// Called when watch mode sees stable text.
  void Function()? onWatchTrigger;

  AppSettings _settings = const AppSettings();
  StreamSubscription<FrameResult>? _sub;
  Timer? _ticker;
  bool _aiming = false;
  bool _searchTask = false;
  bool _suspended = false;
  final List<PerceptionEvent> _events = [];

  bool get isRunning => analyzer.isRunning;
  bool get isAiming => _aiming;

  /// The latest fresh camera snapshot, for the pre-check.
  SceneSnapshot? get scene => monitor.fresh(_now());

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  /// Applies settings immediately (Section 11 rule 5).
  void applySettings(AppSettings s) {
    _settings = s;
    guidance
      ..feedback = s.feedback
      ..thresholds = s.thresholds;
    tracker.thresholds = s.thresholds;
    monitor.thresholds = s.thresholds;
    if (!s.feedback.vibrationGuidance) {
      haptics.stop();
    }
  }

  /// Starts the camera stream analysis.
  Future<void> start(AppSettings s) async {
    applySettings(s);
    analyzer.targetFor = (objects) => tracker.isLocked
        ? tracker.target(objects, _now())
        : TargetTracker.defaultTarget(objects);
    _sub ??= analyzer.results.listen(_onFrame);
    await analyzer.start();
    final mode = await haptics.init();
    _log('vibration_mode', mode.name);
    _ticker ??= Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _tick(),
    );
  }

  /// Stops everything (app in the background).
  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    await haptics.stop();
    await analyzer.stop();
  }

  /// Starts aiming guidance toward the default target or a locked one.
  void startAiming({bool search = false}) {
    if (!_aiming) _log('aiming_start', search ? 'search' : '');
    _aiming = true;
    _searchTask = _searchTask || search;
    guidance.reset();
  }

  /// Locks guidance onto the model's referent box (Section 11). Returns
  /// true if a tracked object matched.
  bool lockOn(List<double> bbox, {bool search = false}) {
    final objects = monitor.latest?.objects ?? const [];
    final ok = tracker.lockFromBbox(NormBox.fromList(bbox), objects, _now());
    _log('target_lock', ok ? 'id ${tracker.lockedId}' : 'no match');
    if (ok) startAiming(search: search);
    return ok;
  }

  /// Ends aiming (STOP, task step ended, full view reached).
  void stopAiming([String why = '']) {
    if (_aiming) _log('aiming_stop', why);
    _aiming = false;
    _searchTask = false;
    tracker.unlock();
    guidance.reset();
    haptics.stop();
  }

  /// Pauses vibration while a model call runs or speech plays. Search
  /// tasks keep guiding if "vibrate in search tasks" is on.
  void suspend() {
    _suspended = true;
    if (!(_searchTask && _settings.feedback.vibrateInSearch)) haptics.stop();
  }

  void resume() => _suspended = false;

  /// Watch mode (Section 12).
  void startWatch() {
    watch.start(_now());
    analyzer.ocrEnabled = true;
    _log('watch_start');
  }

  void cancelWatch() {
    if (watch.isActive) _log('watch_cancel');
    watch.cancel();
    analyzer.ocrEnabled = false;
  }

  /// Takes the events logged since the last call (for the turn log).
  List<Map<String, dynamic>> drainEvents() {
    final out = [for (final e in _events) e.toJson()];
    _events.clear();
    return out;
  }

  void _onFrame(FrameResult f) {
    for (final e in monitor.update(f.scene)) {
      _log(
        e.name,
        'glare ${f.scene.glareFraction.toStringAsFixed(2)} '
        'blur ${f.scene.blurVariance.toStringAsFixed(0)}',
      );
      if (!(_aiming || watch.isActive)) continue;
      if (e == SceneEvent.glareStarted) onHint?.call(Hint.glare);
      if (e == SceneEvent.blurStarted) onHint?.call(Hint.blur);
    }
    if (f.ocr != null && watch.isActive) {
      _handleWatch(watch.onFrame(f.scene.atMs, f.ocr!));
    }
  }

  void _tick() {
    final now = _now();
    if (watch.isActive) _handleWatch(watch.tick(now));
    if (!_aiming) return;
    if (_suspended && !(_searchTask && _settings.feedback.vibrateInSearch)) {
      return;
    }

    final snapshot = monitor.fresh(now);
    final objects = snapshot?.objects ?? const <TrackedObject>[];
    final target = tracker.isLocked
        ? tracker.target(objects, now)
        : TargetTracker.defaultTarget(objects);
    if (tracker.lostLock) _log('target_lost');

    for (final c in guidance.tick(now, target)) {
      switch (c) {
        case PlayBeat():
          _log('beat', '${c.pattern.name} ${c.amplitude}');
          haptics.play(
            c.pattern,
            c.amplitude,
            slow: _settings.feedback.slowPatterns,
          );
          final cue = c.spokenCue;
          if (cue != null) onHint?.call(_cueFor(cue));
          if (c.pattern == GuidancePattern.fullView) {
            _log('full_view');
            Future<void>.delayed(
              const Duration(milliseconds: 600),
              () => stopAiming('full view'),
            );
          }
        case SayNothingInView():
          _log('nothing_in_view');
          onHint?.call(Hint.nothingInView);
      }
    }
  }

  void _handleWatch(List<WatchEvent> events) {
    for (final e in events) {
      _log('watch_${e.type.name}', e.tokens.join(' '));
      switch (e.type) {
        case WatchEventType.pulse:
          earcons.play(Earcon.watchPulse, enabled: _settings.feedback.earcons);
        case WatchEventType.trigger:
          analyzer.ocrEnabled = false;
          onWatchTrigger?.call();
        case WatchEventType.timeout:
          analyzer.ocrEnabled = false;
          onHint?.call(Hint.watchTimeout);
      }
    }
  }

  static Hint _cueFor(GuidancePattern p) => switch (p) {
    GuidancePattern.left => Hint.cueLeft,
    GuidancePattern.right => Hint.cueRight,
    GuidancePattern.up => Hint.cueUp,
    _ => Hint.cueDown,
  };

  void _log(String type, [String detail = '']) {
    _events.add(PerceptionEvent(type, detail));
    if (_events.length > 500) _events.removeAt(0);
    if (kDebugMode) debugPrint('[perception] $type $detail');
  }

  Future<void> dispose() async {
    await stop();
    await _sub?.cancel();
    await analyzer.dispose();
    await earcons.dispose();
  }
}
