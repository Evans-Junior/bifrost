import '../conversation/object_registry.dart';
import '../model/vlm_response.dart';
import '../speech/spoken_reply.dart';
import '../text/text_normalize.dart';
import '../vision/ocr_result.dart';
import 'banned_phrases.dart';

/// A record of one guard changing the answer, kept for the turn log.
class GuardEvent {
  const GuardEvent(this.guard, this.before, this.after);

  /// Guard name, e.g. `confidence_consistency`.
  final String guard;
  final String before;
  final String after;

  @override
  String toString() => '$guard: $before -> $after';
}

/// How a CHALLENGE turn ended (guard 3).
enum ChallengeOutcome {
  /// Not a challenge, or nothing to compare against.
  none,

  /// The model kept its earlier answer.
  held,

  /// The model changed its answer with OCR-confirmed text.
  accepted,

  /// The model changed its answer without direct evidence; reverted.
  rejected,
}

/// Result of guard 3.
class ChallengeResult {
  const ChallengeResult(this.response, this.outcome);

  final VlmResponse response;
  final ChallengeOutcome outcome;
}

/// App-side guards from Section 8. Each guard is a small pure function that
/// returns the (possibly changed) value and appends a [GuardEvent] to `log`
/// when it changes something. Guard 6 (label stability) lives in
/// [ObjectRegistry].
class Guards {
  const Guards({this.maxWords = 25, this.banned = BannedPhrases.empty});

  /// Word limit for the spoken reply (rule 9).
  final int maxWords;

  /// Sight-assuming phrases for guard 7.
  final BannedPhrases banned;

  /// OCR similarity needed to confirm read text (guard 2).
  static const ocrSimilarity = 0.8;

  /// Guard 1. `READ` confidence needs `READ` evidence, otherwise it becomes
  /// `THINK`. `NOT_VISIBLE` evidence always forces `CANT_SEE`.
  VlmResponse confidenceConsistency(VlmResponse r, List<GuardEvent> log) {
    if (r.evidence == Evidence.notVisible &&
        r.confidence != Confidence.cantSee) {
      log.add(
        GuardEvent(
          'confidence_consistency',
          r.confidence.name,
          Confidence.cantSee.name,
        ),
      );
      return r.copyWith(confidence: Confidence.cantSee);
    }
    if (r.confidence == Confidence.read && r.evidence != Evidence.read) {
      log.add(
        GuardEvent(
          'confidence_consistency',
          Confidence.read.name,
          Confidence.think.name,
        ),
      );
      return r.copyWith(confidence: Confidence.think);
    }
    return r;
  }

  /// Guard 2. A `READ` answer must be backed by on-device OCR, otherwise it
  /// becomes `THINK` with [hardToReadReason]. This blocks invented labels.
  VlmResponse ocrCrossCheck(
    VlmResponse r,
    OcrResult ocr,
    String hardToReadReason,
    List<GuardEvent> log,
  ) {
    if (r.confidence != Confidence.read) return r;
    if (ocrConfirms(r.readText, ocr)) return r;
    log.add(
      GuardEvent(
        'ocr_cross_check',
        'READ "${r.readText}"',
        'THINK (ocr: ${ocr.tokens.join(' ')})',
      ),
    );
    return r.copyWith(
      confidence: Confidence.think,
      confidenceReason: hardToReadReason,
    );
  }

  /// True if [readText] matches the OCR result: every word found, or a line
  /// or word sequence with similarity >= [ocrSimilarity].
  static bool ocrConfirms(String readText, OcrResult ocr) {
    final words = TextNormalize.labelWords(readText);
    if (words.isEmpty || ocr.isEmpty) return false;
    final tokens = ocr.tokens;
    if (words.every(tokens.contains)) return true;

    final target = words.join(' ');
    for (final line in ocr.normalizedLines) {
      if (TextNormalize.similarity(target, line) >= ocrSimilarity) return true;
    }
    final sequence = [
      for (final line in ocr.normalizedLines) ...line.split(' '),
    ];
    for (var i = 0; i + words.length <= sequence.length; i++) {
      final window = sequence.sublist(i, i + words.length).join(' ');
      if (TextNormalize.similarity(target, window) >= ocrSimilarity) {
        return true;
      }
    }
    return false;
  }

  /// Guard 3. On CHALLENGE, a changed answer is accepted only if it is now
  /// `READ` (after guards 1 and 2, so OCR-confirmed). Otherwise the previous
  /// answer about [previous] is restored.
  ChallengeResult challenge(
    VlmResponse r,
    RegisteredObject? previous,
    List<GuardEvent> log,
  ) {
    if (previous == null || !previous.isIdentified) {
      return ChallengeResult(r, ChallengeOutcome.none);
    }
    final now = identityOf(r);
    final changed =
        r.answerChanged ||
        (now.isNotEmpty &&
            !sameIdentity(now, previous.identifiedAs) &&
            !sameIdentity(now, previous.readText));
    if (!changed) return ChallengeResult(r, ChallengeOutcome.held);
    if (r.confidence == Confidence.read) {
      return ChallengeResult(r, ChallengeOutcome.accepted);
    }
    log.add(
      GuardEvent(
        'challenge',
        'changed to "$now" (${r.confidence.name})',
        'kept "${previous.identifiedAs}"',
      ),
    );
    final reverted = r.copyWith(
      answerChanged: false,
      evidence: previous.readText.isNotEmpty ? Evidence.read : Evidence.seen,
      readText: previous.readText,
      confidence: previous.confidence ?? Confidence.think,
      confidenceReason: previous.confidenceReason,
      observation: '',
      nextStep: '',
      detail: '',
      registryUpdates: [
        for (final u in r.registryUpdates)
          if (u.id != r.referent?.id) u,
      ],
    );
    return ChallengeResult(reverted, ChallengeOutcome.rejected);
  }

  /// The identity a response claims for its referent.
  static String identityOf(VlmResponse r) {
    if (r.readText.trim().isNotEmpty) return r.readText.trim();
    for (final u in r.registryUpdates) {
      if (u.id == r.referent?.id && u.identifiedAs.isNotEmpty) {
        return u.identifiedAs;
      }
    }
    return '';
  }

  /// "CUMIN" and "Ground cumin" name the same thing; "PAPRIKA" does not.
  static bool sameIdentity(String a, String b) {
    final la = TextNormalize.label(a);
    final lb = TextNormalize.label(b);
    if (la.isEmpty || lb.isEmpty) return false;
    return la == lb ||
        la.contains(lb) ||
        lb.contains(la) ||
        TextNormalize.similarity(la, lb) >= ocrSimilarity;
  }

  /// Guard 4. A `CANT_SEE` answer keeps only the referent and the physical
  /// action. Any identity claim (read text, observation, detail, identified
  /// names) is dropped so the model cannot guess-fill.
  VlmResponse noGuessFilling(VlmResponse r, List<GuardEvent> log) {
    if (r.confidence != Confidence.cantSee) return r;
    final hadClaim =
        r.readText.isNotEmpty ||
        r.observation.isNotEmpty ||
        r.detail.isNotEmpty ||
        r.registryUpdates.any((u) => u.identifiedAs.isNotEmpty);
    if (!hadClaim) return r;
    log.add(
      GuardEvent(
        'no_guess_filling',
        'read_text="${r.readText}" observation="${r.observation}"',
        'dropped',
      ),
    );
    return r.copyWith(
      readText: '',
      observation: '',
      detail: '',
      registryUpdates: [
        for (final u in r.registryUpdates) u.copyWith(identifiedAs: ''),
      ],
    );
  }

  /// Guard 5. A clarification needs exactly two options.
  static bool clarificationValid(VlmResponse r) =>
      !r.needsClarification || r.clarificationOptions.length == 2;

  /// Guard 5 fallback after the retry: keep the first two options if there
  /// are more. Returns null if fewer than two remain (cannot ask).
  VlmResponse? fixClarification(VlmResponse r, List<GuardEvent> log) {
    if (clarificationValid(r)) return r;
    if (r.clarificationOptions.length < 2) return null;
    log.add(
      GuardEvent(
        'clarification_validity',
        '${r.clarificationOptions.length} options',
        '2 options',
      ),
    );
    return r.copyWith(
      clarificationOptions: r.clarificationOptions.sublist(0, 2),
    );
  }

  /// Guard 7. Removes sight-assuming phrases from every model text field.
  VlmResponse bannedPhrases(VlmResponse r, List<GuardEvent> log) {
    String clean(String field, String text) {
      final out = banned.clean(text);
      if (out != text) log.add(GuardEvent('banned_phrases', text, out));
      return out;
    }

    final ref = r.referent;
    return r.copyWith(
      observation: clean('observation', r.observation),
      nextStep: clean('next_step', r.nextStep),
      detail: clean('detail', r.detail),
      confidenceReason: clean('confidence_reason', r.confidenceReason),
      clarificationOptions: [
        for (final o in r.clarificationOptions) clean('option', o),
      ],
      referent: ref?.copyWith(location: clean('location', ref.location)),
    );
  }

  /// Guard 8. If the spoken reply is over [maxWords], it is shortened in
  /// steps, and everything removed goes to `detail` for MORE:
  ///
  /// 1. the next step moves out, except for `THINK` and `CANT_SEE`, where it
  ///    is the physical action that gets better evidence (rule 4);
  /// 2. a multi-sentence observation keeps only its first sentence;
  /// 3. a long single sentence is cut at the last clause boundary (comma,
  ///    semicolon, "and"/"et") that fits.
  ///
  /// The referent and confidence phrase are always kept.
  SpokenReply lengthCap(SpokenReply reply, List<GuardEvent> log) {
    final before = reply.wordCount;
    if (before <= maxWords) return reply;
    var r = reply;
    final moved = <String>[];

    if (!r.nextStepIsRequired && r.nextStep.isNotEmpty) {
      moved.add(r.nextStep);
      r = r.copyWith(nextStep: '');
    }
    if (r.wordCount > maxWords) {
      final sentences = _sentences(r.observation);
      if (sentences.length > 1) {
        moved.insert(0, sentences.skip(1).join(' '));
        r = r.copyWith(observation: sentences.first);
      }
    }
    if (r.wordCount > maxWords) {
      final budget =
          maxWords - (r.wordCount - SpokenReply.countWords(r.observation));
      final cut = _cutAtClause(r.observation, budget);
      if (cut != null) {
        moved.insert(0, cut.$2);
        r = r.copyWith(observation: cut.$1);
      }
    }
    if (moved.isEmpty) return reply;
    r = r.copyWith(
      detail: [...moved, reply.detail].where((s) => s.isNotEmpty).join(' '),
    );
    log.add(GuardEvent('length_cap', '$before words', '${r.wordCount} words'));
    return r;
  }

  static List<String> _sentences(String text) => text
      .trim()
      .split(RegExp(r'(?<=[.!?])\s+'))
      .where((s) => s.isNotEmpty)
      .toList();

  /// Splits [sentence] at the last clause boundary that leaves at most
  /// [budget] words (and at least 4) in the first part. Returns
  /// (kept sentence, moved remainder) or null if there is no such boundary.
  static (String, String)? _cutAtClause(String sentence, int budget) {
    if (budget < 4) return null;
    final boundary = RegExp(r'[,;]\s+|\s+(?:and|et)\s+');
    (String, String)? best;
    for (final m in boundary.allMatches(sentence)) {
      final head = sentence.substring(0, m.start).trim();
      final words = SpokenReply.countWords(head);
      if (words < 4) continue;
      if (words > budget) break;
      final tail = sentence.substring(m.end).trim();
      if (tail.isEmpty) continue;
      best = ('$head.', _capitalize(tail));
    }
    return best;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
