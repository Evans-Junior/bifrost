import '../model/vlm_response.dart';

/// The parts of one spoken answer, in speaking order. Built by the
/// [SpeechComposer] from the guarded model JSON; the model's free text is
/// never spoken as a whole.
class SpokenReply {
  const SpokenReply({
    required this.confidence,
    this.referent = '',
    this.observation = '',
    this.confidencePhrase = '',
    this.nextStep = '',
    this.detail = '',
    this.isClarification = false,
  });

  /// Confidence level, used later to choose the earcon.
  final Confidence? confidence;
  final String referent;
  final String observation;
  final String confidencePhrase;
  final String nextStep;

  /// Extra text kept for MORE; not spoken by default.
  final String detail;
  final bool isClarification;

  /// For `CANT_SEE` and `THINK` the next step is the physical action that
  /// gets better evidence ("move your thumb"), so it must be spoken.
  bool get nextStepIsRequired =>
      confidence == Confidence.cantSee || confidence == Confidence.think;

  /// The text to speak now.
  String get text => [
    referent,
    observation,
    confidencePhrase,
    nextStep,
  ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(' ');

  int get wordCount => countWords(text);

  SpokenReply copyWith({
    String? observation,
    String? nextStep,
    String? detail,
  }) => SpokenReply(
    confidence: confidence,
    referent: referent,
    observation: observation ?? this.observation,
    confidencePhrase: confidencePhrase,
    nextStep: nextStep ?? this.nextStep,
    detail: detail ?? this.detail,
    isClarification: isClarification,
  );

  /// The same reply without its referent, for when the referent was
  /// already spoken during streaming.
  SpokenReply copyWithoutReferent() => SpokenReply(
    confidence: confidence,
    observation: observation,
    confidencePhrase: confidencePhrase,
    nextStep: nextStep,
    detail: detail,
    isClarification: isClarification,
  );

  /// Counts words separated by whitespace.
  static int countWords(String s) =>
      s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;
}
