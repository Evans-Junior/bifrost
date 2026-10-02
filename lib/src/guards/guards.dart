import '../model/vlm_response.dart';
import '../speech/spoken_reply.dart';

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

/// App-side guards from Section 8. Each guard is a small pure function that
/// returns the (possibly changed) value and appends a [GuardEvent] to [log]
/// when it changes something.
///
/// Phase 1 implements guards 1, 4 and 8.
class Guards {
  const Guards({this.maxWords = 25});

  /// Word limit for the spoken reply (rule 9).
  final int maxWords;

  /// Runs the response-level guards (1 then 4) in order.
  VlmResponse applyToResponse(VlmResponse r, List<GuardEvent> log) {
    var out = confidenceConsistency(r, log);
    out = noGuessFilling(out, log);
    return out;
  }

  /// Guard 1. `READ` confidence needs `READ` evidence, otherwise it becomes
  /// `THINK`. `NOT_VISIBLE` evidence always forces `CANT_SEE`.
  VlmResponse confidenceConsistency(VlmResponse r, List<GuardEvent> log) {
    if (r.evidence == Evidence.notVisible &&
        r.confidence != Confidence.cantSee) {
      log.add(GuardEvent('confidence_consistency', r.confidence.name,
          Confidence.cantSee.name));
      return r.copyWith(confidence: Confidence.cantSee);
    }
    if (r.confidence == Confidence.read && r.evidence != Evidence.read) {
      log.add(GuardEvent('confidence_consistency', Confidence.read.name,
          Confidence.think.name));
      return r.copyWith(confidence: Confidence.think);
    }
    return r;
  }

  /// Guard 4. A `CANT_SEE` answer keeps only the referent and the physical
  /// action. Any identity claim (read text, observation, detail, identified
  /// names) is dropped so the model cannot guess-fill.
  VlmResponse noGuessFilling(VlmResponse r, List<GuardEvent> log) {
    if (r.confidence != Confidence.cantSee) return r;
    final hadClaim = r.readText.isNotEmpty ||
        r.observation.isNotEmpty ||
        r.detail.isNotEmpty ||
        r.registryUpdates.any((u) => u.identifiedAs.isNotEmpty);
    if (!hadClaim) return r;
    log.add(GuardEvent(
      'no_guess_filling',
      'read_text="${r.readText}" observation="${r.observation}"',
      'dropped',
    ));
    return r.copyWith(
      readText: '',
      observation: '',
      detail: '',
      registryUpdates: [
        for (final u in r.registryUpdates) u.copyWith(identifiedAs: ''),
      ],
    );
  }

  /// Guard 8. If the spoken reply is over [maxWords], keep the referent,
  /// observation and confidence phrase, and move the rest to `detail` so the
  /// user can ask for it with MORE.
  ///
  /// For `CANT_SEE` the next step is the required physical action (rule 4),
  /// so it is never moved.
  SpokenReply lengthCap(SpokenReply reply, List<GuardEvent> log) {
    final before = reply.wordCount;
    if (before <= maxWords || reply.nextStepIsRequired) return reply;
    if (reply.nextStep.isEmpty) return reply;
    final moved = reply.copyWith(
      nextStep: '',
      detail: [reply.nextStep, reply.detail]
          .where((s) => s.isNotEmpty)
          .join(' '),
    );
    log.add(GuardEvent('length_cap', '$before words', '${moved.wordCount} words'));
    return moved;
  }
}
