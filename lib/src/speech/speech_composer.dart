import '../../l10n/gen/app_localizations.dart';
import '../conversation/object_registry.dart';
import '../guards/guards.dart';
import '../model/vlm_response.dart';
import '../text/text_normalize.dart';
import 'spoken_reply.dart';

/// Turn context the composer needs beyond the model JSON.
class ComposeExtras {
  const ComposeExtras({
    this.challenge = ChallengeOutcome.none,
    this.previous,
    this.taskObjectCount,
  });

  /// Result of guard 3 on a CHALLENGE turn.
  final ChallengeOutcome challenge;

  /// The referent's answer before this turn, for "I still read …".
  final RegisteredObject? previous;

  /// Set on START_TASK: how many objects were registered.
  final int? taskObjectCount;
}

/// Turns a guarded [VlmResponse] into a [SpokenReply] using the localized
/// AI-mode templates in `lib/l10n/*.arb` (Section 8):
///
/// `{referent}. {observation} {confidence_phrase} {next_step?}`
class SpeechComposer {
  const SpeechComposer(this.l10n);

  final AppLocalizations l10n;

  SpokenReply compose(
    VlmResponse r, [
    ComposeExtras extras = const ComposeExtras(),
  ]) {
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
    final challenge = _challengeReply(r, extras);
    if (challenge != null) return challenge;
    final count = extras.taskObjectCount;
    return SpokenReply(
      confidence: r.confidence,
      referent: r.referent == null && count != null
          ? l10n.taskRegistered(count)
          : referentPhrase(r.referent),
      observation: r.confidence == Confidence.cantSee
          ? l10n.cantSee
          : _sentence(r.observation),
      confidencePhrase: _confidencePhrase(r),
      nextStep: _nextStep(r),
      detail: _sentence(r.detail),
    );
  }

  /// Guard 3 wording: hold the earlier answer, or admit the change plainly.
  SpokenReply? _challengeReply(VlmResponse r, ComposeExtras extras) {
    final ref = referentPhrase(r.referent);
    switch (extras.challenge) {
      case ChallengeOutcome.none:
        return null;
      case ChallengeOutcome.accepted:
        return SpokenReply(
          confidence: Confidence.read,
          referent: ref,
          observation: l10n.challengeChanged(
            TextNormalize.speakable(r.readText),
          ),
        );
      case ChallengeOutcome.held:
        if (r.confidence != Confidence.read || r.readText.trim().isEmpty) {
          return null;
        }
        return SpokenReply(
          confidence: Confidence.read,
          referent: ref,
          observation: l10n.challengeStillRead(
            TextNormalize.speakable(r.readText),
          ),
        );
      case ChallengeOutcome.rejected:
        final prev = extras.previous;
        final read = prev?.readText ?? '';
        return SpokenReply(
          confidence: prev?.confidence ?? Confidence.think,
          referent: ref,
          observation: prev?.confidence == Confidence.read && read.isNotEmpty
              ? l10n.challengeStillRead(TextNormalize.speakable(read))
              : l10n.challengeStillThink(
                  TextNormalize.speakable(prev?.identifiedAs ?? ''),
                ),
        );
    }
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
