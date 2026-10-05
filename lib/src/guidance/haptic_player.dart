import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'patterns.dart';

/// How the phone can vibrate (logged, Section 11 rule 4).
enum HapticMode {
  /// Custom patterns with amplitude control.
  patternsWithAmplitude,

  /// Custom patterns, fixed strength.
  patterns,

  /// No custom patterns: built-in HapticFeedback impacts.
  impactsFallback,

  /// No vibrator.
  none,
}

/// Plays [GuidancePattern]s on the device. Uses the `vibration` package
/// where custom patterns work, and the built-in HapticFeedback fallback
/// (left = one heavy, right = two light, up = three light, down = two
/// heavy, full view = three heavy) where they do not.
class HapticPlayer {
  HapticMode? _mode;

  /// The detected mode, after [init].
  HapticMode get mode => _mode ?? HapticMode.none;

  /// Checks what the device supports. Safe to call more than once.
  Future<HapticMode> init() async {
    if (_mode != null) return _mode!;
    try {
      if (!await Vibration.hasVibrator()) {
        _mode = HapticMode.none;
      } else if (await Vibration.hasCustomVibrationsSupport()) {
        _mode = await Vibration.hasAmplitudeControl()
            ? HapticMode.patternsWithAmplitude
            : HapticMode.patterns;
      } else {
        _mode = HapticMode.impactsFallback;
      }
    } catch (_) {
      _mode = HapticMode.impactsFallback;
    }
    debugPrint('[haptics] mode: ${_mode!.name}');
    return _mode!;
  }

  /// Plays one beat. Never throws.
  Future<void> play(
    GuidancePattern p,
    int amplitude, {
    bool slow = false,
  }) async {
    try {
      switch (await init()) {
        case HapticMode.patternsWithAmplitude:
          await Vibration.vibrate(
            pattern: p.vibrationPattern(slow: slow),
            intensities: p.intensities(amplitude, slow: slow),
          );
        case HapticMode.patterns:
          await Vibration.vibrate(pattern: p.vibrationPattern(slow: slow));
        case HapticMode.impactsFallback:
          await _fallback(p);
        case HapticMode.none:
          return;
      }
    } catch (e) {
      debugPrint('[haptics] play failed: $e');
    }
  }

  Future<void> _fallback(GuidancePattern p) async {
    Future<void> times(int n, Future<void> Function() impact) async {
      for (var i = 0; i < n; i++) {
        if (i > 0) await Future<void>.delayed(const Duration(milliseconds: 90));
        await impact();
      }
    }

    switch (p) {
      case GuidancePattern.left:
        await HapticFeedback.heavyImpact();
      case GuidancePattern.right:
        await times(2, HapticFeedback.lightImpact);
      case GuidancePattern.up:
        await times(3, HapticFeedback.lightImpact);
      case GuidancePattern.down:
        await times(2, HapticFeedback.heavyImpact);
      case GuidancePattern.fullView:
        await times(3, HapticFeedback.heavyImpact);
    }
  }

  /// Stops any vibration now.
  Future<void> stop() async {
    try {
      if (mode != HapticMode.none) await Vibration.cancel();
    } catch (_) {}
  }
}
