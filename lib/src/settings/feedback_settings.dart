import 'package:flutter/foundation.dart';

/// Vibration strength (Section 11, Settings).
enum VibrationIntensity {
  low(90),
  medium(170),
  high(255);

  const VibrationIntensity(this.amplitude);

  /// Base amplitude 1–255 for devices with amplitude control.
  final int amplitude;

  static VibrationIntensity fromName(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => medium);
}

/// Non-speech feedback the user controls: earcons and vibration guidance
/// (Sections 11, 13 and 17). Every field takes effect immediately.
@immutable
class FeedbackSettings {
  const FeedbackSettings({
    this.earcons = true,
    this.vibrationGuidance = true,
    this.intensity = VibrationIntensity.medium,
    this.vibrateInSearch = true,
    this.slowPatterns = false,
    this.speakDirection = false,
  });

  /// Short sounds for listening, confidence levels, clarification, errors.
  final bool earcons;

  /// Directional vibration patterns while aiming.
  final bool vibrationGuidance;
  final VibrationIntensity intensity;

  /// Keep guiding during search tasks ("find my keys").
  final bool vibrateInSearch;

  /// Longer gaps for users who need more time between beats.
  final bool slowPatterns;

  /// Adds a quiet one-word cue ("left") every third beat while learning.
  final bool speakDirection;

  FeedbackSettings copyWith({
    bool? earcons,
    bool? vibrationGuidance,
    VibrationIntensity? intensity,
    bool? vibrateInSearch,
    bool? slowPatterns,
    bool? speakDirection,
  }) => FeedbackSettings(
    earcons: earcons ?? this.earcons,
    vibrationGuidance: vibrationGuidance ?? this.vibrationGuidance,
    intensity: intensity ?? this.intensity,
    vibrateInSearch: vibrateInSearch ?? this.vibrateInSearch,
    slowPatterns: slowPatterns ?? this.slowPatterns,
    speakDirection: speakDirection ?? this.speakDirection,
  );

  Map<String, dynamic> toJson() => {
    'earcons': earcons,
    'vibration_guidance': vibrationGuidance,
    'intensity': intensity.name,
    'vibrate_in_search': vibrateInSearch,
    'slow_patterns': slowPatterns,
    'speak_direction': speakDirection,
  };

  factory FeedbackSettings.fromJson(Map<String, dynamic> j) {
    const d = FeedbackSettings();
    return FeedbackSettings(
      earcons: j['earcons'] as bool? ?? d.earcons,
      vibrationGuidance:
          j['vibration_guidance'] as bool? ?? d.vibrationGuidance,
      intensity: VibrationIntensity.fromName(j['intensity'] as String?),
      vibrateInSearch: j['vibrate_in_search'] as bool? ?? d.vibrateInSearch,
      slowPatterns: j['slow_patterns'] as bool? ?? d.slowPatterns,
      speakDirection: j['speak_direction'] as bool? ?? d.speakDirection,
    );
  }
}

/// Every tunable threshold for aiming, glare and blur (Section 11,
/// developer settings). Logged with each turn so results can be compared.
@immutable
class VisionThresholds {
  const VisionThresholds({
    this.farDistance = 0.6,
    this.middleDistance = 0.3,
    this.fullViewDistance = 0.15,
    this.fullViewMinArea = 0.08,
    this.fullViewMargin = 0.05,
    this.lockIou = 0.3,
    this.lostAfterMs = 3000,
    this.hysteresisMs = 300,
    this.switchDeadZone = 0.05,
    this.glareFraction = 0.15,
    this.glareLuma = 250,
    this.blurVariance = 40,
    this.blurForMs = 1000,
  });

  /// Distance bands (0–1 from frame centre) for beat repeat rates.
  final double farDistance;
  final double middleDistance;

  /// "In full view": centred within this distance …
  final double fullViewDistance;

  /// … covering at least this fraction of the frame …
  final double fullViewMinArea;

  /// … and fully inside the frame with this margin.
  final double fullViewMargin;

  /// Minimum overlap to lock onto a tracked object from `referent.bbox`.
  final double lockIou;

  /// A locked target is dropped after being unseen this long.
  final int lostAfterMs;

  /// A new direction or band must hold this long before the pattern changes.
  final int hysteresisMs;

  /// No direction flip while |dx| and |dy| differ by less than this.
  final double switchDeadZone;

  /// Glare: this fraction of target pixels at or above [glareLuma].
  final double glareFraction;
  final int glareLuma;

  /// Blur: Laplacian variance below this (on the downscaled luma grid) …
  final double blurVariance;

  /// … for this long.
  final int blurForMs;

  Map<String, dynamic> toJson() => {
    'far_distance': farDistance,
    'middle_distance': middleDistance,
    'full_view_distance': fullViewDistance,
    'full_view_min_area': fullViewMinArea,
    'full_view_margin': fullViewMargin,
    'lock_iou': lockIou,
    'lost_after_ms': lostAfterMs,
    'hysteresis_ms': hysteresisMs,
    'switch_dead_zone': switchDeadZone,
    'glare_fraction': glareFraction,
    'glare_luma': glareLuma,
    'blur_variance': blurVariance,
    'blur_for_ms': blurForMs,
  };

  factory VisionThresholds.fromJson(Map<String, dynamic> j) {
    const d = VisionThresholds();
    double dbl(String k, double def) => (j[k] as num?)?.toDouble() ?? def;
    int integer(String k, int def) => (j[k] as num?)?.toInt() ?? def;
    return VisionThresholds(
      farDistance: dbl('far_distance', d.farDistance),
      middleDistance: dbl('middle_distance', d.middleDistance),
      fullViewDistance: dbl('full_view_distance', d.fullViewDistance),
      fullViewMinArea: dbl('full_view_min_area', d.fullViewMinArea),
      fullViewMargin: dbl('full_view_margin', d.fullViewMargin),
      lockIou: dbl('lock_iou', d.lockIou),
      lostAfterMs: integer('lost_after_ms', d.lostAfterMs),
      hysteresisMs: integer('hysteresis_ms', d.hysteresisMs),
      switchDeadZone: dbl('switch_dead_zone', d.switchDeadZone),
      glareFraction: dbl('glare_fraction', d.glareFraction),
      glareLuma: integer('glare_luma', d.glareLuma),
      blurVariance: dbl('blur_variance', d.blurVariance),
      blurForMs: integer('blur_for_ms', d.blurForMs),
    );
  }
}
