import '../vision/ocr_result.dart';

/// What watch mode wants done.
enum WatchEventType {
  /// Play the soft pulse so the user knows it is still watching.
  pulse,

  /// Text is stable: capture a still and ask the model.
  trigger,

  /// 20 s passed without readable text.
  timeout,
}

class WatchEvent {
  const WatchEvent(this.type, [this.tokens = const {}]);

  final WatchEventType type;

  /// The stable tokens, for [WatchEventType.trigger].
  final Set<String> tokens;

  @override
  String toString() =>
      'WatchEvent(${type.name}${tokens.isEmpty ? '' : ' $tokens'})';
}

/// Watch mode, "tell me when you can read it" (Section 12). Pure Dart:
/// fed OCR results from the camera stream (about 4 per second) and clock
/// ticks, it decides when to pulse, trigger or give up.
///
/// Trigger: the same normalized tokens of 3+ letters appear in two
/// consecutive frames. Tokens shared by both frames count, so one flickering
/// OCR word does not block a stable label.
class WatchController {
  WatchController({
    this.timeoutMs = 20000,
    this.pulseMs = 2000,
    this.minLetters = 3,
  });

  final int timeoutMs;
  final int pulseMs;
  final int minLetters;

  bool _active = false;
  int _startedAt = 0;
  int _lastPulse = 0;
  Set<String> _previous = const {};

  bool get isActive => _active;

  void start(int nowMs) {
    _active = true;
    _startedAt = nowMs;
    _lastPulse = nowMs;
    _previous = const {};
  }

  /// Ends watch mode (STOP, any new utterance, trigger or timeout).
  void cancel() => _active = false;

  /// Handles one OCR frame.
  List<WatchEvent> onFrame(int nowMs, OcrResult ocr) {
    if (!_active) return const [];
    final tokens = {
      for (final t in ocr.tokens)
        if (RegExp('[A-Z]').allMatches(t).length >= minLetters) t,
    };
    final stable = tokens.intersection(_previous);
    _previous = tokens;
    if (stable.isNotEmpty) {
      _active = false;
      return [WatchEvent(WatchEventType.trigger, stable)];
    }
    return tick(nowMs);
  }

  /// Handles the passage of time without a frame.
  List<WatchEvent> tick(int nowMs) {
    if (!_active) return const [];
    if (nowMs - _startedAt >= timeoutMs) {
      _active = false;
      return const [WatchEvent(WatchEventType.timeout)];
    }
    if (nowMs - _lastPulse >= pulseMs) {
      _lastPulse = nowMs;
      return const [WatchEvent(WatchEventType.pulse)];
    }
    return const [];
  }
}
