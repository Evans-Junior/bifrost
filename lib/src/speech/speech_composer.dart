import '../../l10n/gen/app_localizations.dart';
import '../model/vlm_response.dart';
import 'spoken_reply.dart';

/// Turns a guarded [VlmResponse] into a [SpokenReply] using the localized
/// AI-mode templates in `lib/l10n/*.arb` (Section 8):
///
/// `{referent}. {observation} {confidence_phrase} {next_step?}`
class SpeechComposer {
  const SpeechComposer(this.l10n);

  final AppLocalizations l10n;

  SpokenReply compose(VlmResponse r) {
    if (r.needsClarification && r.clarificationOptions.length >= 2) {
      return SpokenReply(
        confidence: null,
        isClarification: true,
        referent: l10n.clarification(
          _clean(r.clarificationOptions[0]),
          _clean(r.clarificationOptions[1]),
        ),
      );
    }
    return SpokenReply(
      confidence: r.confidence,
      referent: referentPhrase(r.referent),
      observation: r.confidence == Confidence.cantSee
          ? l10n.cantSee
          : _sentence(r.observation),
      confidencePhrase: _confidencePhrase(r),
      nextStep: _nextStep(r),
      detail: _sentence(r.detail),
    );
  }

  /// "Jar 2, in your right hand." Falls back to a generic name so every
  /// answer still starts with a referent (rule 1).
  String referentPhrase(Referent? ref) {
    final label = _capitalize(_clean(ref?.label ?? ''));
    final location = _clean(ref?.location ?? '');
    if (label.isEmpty) return '${l10n.referentFallback}.';
    if (location.isEmpty) return l10n.referentOnly(label);
    return l10n.referentWithLocation(label, location);
  }

  String _confidencePhrase(VlmResponse r) {
    switch (r.confidence) {
      case Confidence.read:
        return l10n.confidenceRead;
      case Confidence.think:
        final reason = _clean(r.confidenceReason);
        return reason.isEmpty
            ? l10n.confidenceThinkNoReason
            : l10n.confidenceThink(_lowerFirst(reason));
      case Confidence.cantSee:
        // The "I can't see" phrase is already in the observation slot.
        return '';
    }
  }

  String _nextStep(VlmResponse r) {
    final step = _sentence(r.nextStep);
    if (step.isEmpty && r.confidence == Confidence.cantSee) {
      return l10n.cantSeeDefaultAction;
    }
    return step;
  }

  static String _clean(String s) =>
      s.trim().replaceAll(RegExp(r'[\s.]+$'), '').trim();

  static String _sentence(String s) {
    final c = s.trim();
    if (c.isEmpty) return '';
    final capped = _capitalize(c);
    return RegExp(r'[.!?…]$').hasMatch(capped) ? capped : '$capped.';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Lowercases the first letter unless the first word is an acronym or
  /// label text such as "CUMIN".
  static String _lowerFirst(String s) {
    if (s.length < 2 || s[1] != s[1].toLowerCase()) return s;
    return s[0].toLowerCase() + s.substring(1);
  }
}
