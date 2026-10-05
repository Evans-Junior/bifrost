import 'package:flutter/widgets.dart';

import 'feedback_settings.dart';

export 'feedback_settings.dart';

/// The two app languages. Speech-to-text, text-to-speech, templates and
/// prompts all follow this value.
enum AppLanguage {
  en('en', 'en-CA'),
  fr('fr', 'fr-CA');

  const AppLanguage(this.code, this.localeTag);

  /// Short code used for asset file names (`system_en.txt`).
  final String code;

  /// BCP-47 tag used by speech-to-text and text-to-speech.
  final String localeTag;

  /// Flutter locale used to pick the `.arb` strings.
  Locale get locale => Locale(code, 'CA');

  /// Speech-to-text locale id (`en_CA` style).
  String get sttLocaleId => localeTag.replaceAll('-', '_');

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => en);
}

/// The user's vision profile, which selects a prompt block (Section 10).
enum VisionProfile {
  blind('blind'),
  lowVision('low_vision');

  const VisionProfile(this.assetKey);

  /// Key used in `assets/prompts/profile_<key>_<lang>.txt`.
  final String assetKey;

  static VisionProfile fromKey(String? key) =>
      values.firstWhere((p) => p.assetKey == key, orElse: () => blind);
}

/// How positions are described to the user (Section 10).
enum PositionStyle {
  clock('clock'),
  leftRight('left_right');

  const PositionStyle(this.assetKey);

  /// Key used in `assets/prompts/position_<key>_<lang>.txt`.
  final String assetKey;

  static PositionStyle fromKey(String? key) =>
      values.firstWhere((p) => p.assetKey == key, orElse: () => leftRight);
}

/// Reasoning effort sent to the model. `off` disables Qwen thinking.
enum ReasoningEffort {
  off,
  low,
  medium,
  high;

  static ReasoningEffort fromName(String? name) =>
      values.firstWhere((r) => r.name == name, orElse: () => off);
}

/// All user and researcher settings. Server fields mirror Section 4:
/// `MODEL_BASE_URL`, `MODEL_NAME`, `API_KEY`, `REASONING_EFFORT`, `TIMEOUT_S`.
@immutable
class AppSettings {
  const AppSettings({
    this.modelBaseUrl = '',
    this.modelName = 'Qwen/Qwen3.8-27B',
    this.apiKey = '',
    this.reasoningEffort = ReasoningEffort.off,
    this.timeoutS = 15,
    this.language = AppLanguage.en,
    this.speechRate = 0.5,
    this.profile = VisionProfile.blind,
    this.positionStyle = PositionStyle.leftRight,
    this.logServerUrl = '',
    this.logToken = '',
    this.participant = 'dev',
    this.feedback = const FeedbackSettings(),
    this.thresholds = const VisionThresholds(),
    this.onboardingDone = false,
  });

  final String modelBaseUrl;
  final String modelName;
  final String apiKey;
  final ReasoningEffort reasoningEffort;
  final int timeoutS;
  final AppLanguage language;

  /// Text-to-speech rate, 0.0–1.0 as used by `flutter_tts`.
  final double speechRate;
  final VisionProfile profile;
  final PositionStyle positionStyle;

  /// Where turn logs are sent (the bifrost_logs server). Empty = local only.
  final String logServerUrl;

  /// Optional bearer token the log server expects.
  final String logToken;

  /// Participant code recorded in every log entry.
  final String participant;

  /// Earcons and vibration guidance.
  final FeedbackSettings feedback;

  /// Aiming, glare and blur thresholds (developer section).
  final VisionThresholds thresholds;

  /// True once the spoken first-run setup has been completed.
  final bool onboardingDone;

  /// True when the app has enough to call a model server.
  bool get isServerConfigured =>
      modelBaseUrl.trim().isNotEmpty && modelName.trim().isNotEmpty;

  AppSettings copyWith({
    String? modelBaseUrl,
    String? modelName,
    String? apiKey,
    ReasoningEffort? reasoningEffort,
    int? timeoutS,
    AppLanguage? language,
    double? speechRate,
    VisionProfile? profile,
    PositionStyle? positionStyle,
    String? logServerUrl,
    String? logToken,
    String? participant,
    FeedbackSettings? feedback,
    VisionThresholds? thresholds,
    bool? onboardingDone,
  }) {
    return AppSettings(
      modelBaseUrl: modelBaseUrl ?? this.modelBaseUrl,
      modelName: modelName ?? this.modelName,
      apiKey: apiKey ?? this.apiKey,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      timeoutS: timeoutS ?? this.timeoutS,
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      profile: profile ?? this.profile,
      positionStyle: positionStyle ?? this.positionStyle,
      logServerUrl: logServerUrl ?? this.logServerUrl,
      logToken: logToken ?? this.logToken,
      participant: participant ?? this.participant,
      feedback: feedback ?? this.feedback,
      thresholds: thresholds ?? this.thresholds,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}
