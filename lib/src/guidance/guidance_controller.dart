import '../settings/feedback_settings.dart';
import '../vision/geometry.dart';
import 'patterns.dart';

/// Something the guidance wants done. The controller only decides; a
/// player turns commands into vibration or speech.
sealed class GuidanceCommand {
  const GuidanceCommand();
}

/// Play one beat of [pattern] at [amplitude] (1–255).
class PlayBeat extends GuidanceCommand {
  const PlayBeat(this.pattern, this.amplitude, {this.spokenCue});

  final GuidancePattern pattern;
  final int amplitude;

  /// Optional quiet word ("left") every third beat, if enabled.
  final GuidancePattern? spokenCue;

  @override
  String toString() =>
      'PlayBeat(${pattern.name}, $amplitude'
      '${spokenCue != null ? ', cue' : ''})';
}

/// Say "Nothing in view. Sweep slowly." once (no vibration).
class SayNothingInView extends GuidanceCommand {
  const SayNothingInView();

  @override
  String toString() => 'SayNothingInView';
}

/// Distance band, which sets how often the beat repeats.
enum DistanceBand {
  far(1200),
  middle(700),
  close(400);

  const DistanceBand(this.repeatMs);

  final int repeatMs;
}

/// Pure-Dart vibration guidance (Section 11). Feed it the target position
/// over time with [tick]; it returns the beats to play. No device needed,
/// so every rule is unit-tested.
///
/// Rules implemented:
/// - direction = the axis with the larger offset, horizontal first when
///   similar; it means "move this way to reach the target";
/// - repeat interval shrinks with distance (1.2 s / 0.7 s / 0.4 s) and
///   amplitude rises as the target gets closer;
/// - hysteresis: a new direction or band must hold [VisionThresholds.hysteresisMs]
///   and does not flip within the dead zone of the switch point;
/// - no overlapping beats, at least 250 ms between beats;
/// - one full-view buzz, then silence;
/// - nothing in view: no vibration, one spoken line;
/// - settings off: nothing at all.
class GuidanceController {
  GuidanceController({
    this.thresholds = const VisionThresholds(),
    this.feedback = const FeedbackSettings(),
  });

  VisionThresholds thresholds;
  FeedbackSettings feedback;

  /// Minimum silence between two beats.
  static const minGapMs = 250;

  GuidancePattern? _direction;
  DistanceBand? _band;
  GuidancePattern? _pendingDirection;
  DistanceBand? _pendingBand;
  int _pendingSince = 0;
  int? _lastBeatAt;
  int _lastBeatLength = 0;
  int _beatCount = 0;
  bool _fullViewPlayed = false;
  int? _outOfViewSince;
  bool _nothingSaid = false;

  /// The direction currently being signalled (for logs and tests).
  GuidancePattern? get direction => _direction;
  DistanceBand? get band => _band;
  bool get fullViewReached => _fullViewPlayed;

  /// Forgets all state, e.g. when a new target is chosen.
  void reset() {
    _direction = null;
    _band = null;
    _pendingDirection = null;
    _pendingBand = null;
    _lastBeatAt = null;
    _lastBeatLength = 0;
    _beatCount = 0;
    _fullViewPlayed = false;
    _outOfViewSince = null;
    _nothingSaid = false;
  }

  /// Advances to [nowMs] with the target at [target] (null if nothing to
  /// aim at). Returns the commands to carry out now.
  List<GuidanceCommand> tick(int nowMs, NormBox? target) {
    if (!feedback.vibrationGuidance) return const [];

    if (target == null) {
      _direction = null;
      _band = null;
      _pendingDirection = null;
      if (_nothingSaid) return const [];
      _nothingSaid = true;
      return const [SayNothingInView()];
    }
    _nothingSaid = false;

    final dx = (target.centerX - 0.5) * 2;
    final dy = (target.centerY - 0.5) * 2;
    final distance = dx.abs() > dy.abs() ? dx.abs() : dy.abs();

    if (_inFullView(target, distance)) {
      _outOfViewSince = null;
      if (_fullViewPlayed || _beatPlaying(nowMs)) return const [];
      _fullViewPlayed = true;
      _direction = null;
      _band = null;
      return [_beat(nowMs, GuidancePattern.fullView, 255)];
    }
    if (_fullViewPlayed) {
      // Left full view: start guiding again only after it stays out.
      _outOfViewSince ??= nowMs;
      if (nowMs - _outOfViewSince! < thresholds.hysteresisMs) return const [];
      _fullViewPlayed = false;
    }

    _updateDirectionAndBand(nowMs, dx, dy, distance);
    final dir = _direction!;
    final band = _band!;
    if (!_dueForBeat(nowMs, band)) return const [];
    final cue = feedback.speakDirection && (_beatCount + 1) % 3 == 0
        ? dir
        : null;
    return [_beat(nowMs, dir, _amplitude(band), cue: cue)];
  }

  bool _inFullView(NormBox t, double distance) =>
      t.insideWithMargin(thresholds.fullViewMargin) &&
      distance <= thresholds.fullViewDistance &&
      t.area >= thresholds.fullViewMinArea;

  void _updateDirectionAndBand(int now, double dx, double dy, double distance) {
    final candidateDir = _candidateDirection(dx, dy);
    final candidateBand = distance > thresholds.farDistance
        ? DistanceBand.far
        : distance > thresholds.middleDistance
        ? DistanceBand.middle
        : DistanceBand.close;

    if (_direction == null) {
      _direction = candidateDir;
      _band = candidateBand;
      _pendingDirection = null;
      return;
    }
    if (candidateDir == _direction && candidateBand == _band) {
      _pendingDirection = null;
      return;
    }
    if (candidateDir != _pendingDirection || candidateBand != _pendingBand) {
      _pendingDirection = candidateDir;
      _pendingBand = candidateBand;
      _pendingSince = now;
      return;
    }
    if (now - _pendingSince >= thresholds.hysteresisMs) {
      _direction = candidateDir;
      _band = candidateBand;
      _pendingDirection = null;
    }
  }

  /// "Move this way to reach the target." Horizontal wins ties; near a
  /// switch point the current direction is kept (dead zone).
  GuidancePattern _candidateDirection(double dx, double dy) {
    final dead = thresholds.switchDeadZone;
    final current = _direction;
    final currentHorizontal =
        current == GuidancePattern.left || current == GuidancePattern.right;

    bool horizontal;
    final diff = dx.abs() - dy.abs();
    if (current != null && diff.abs() <= dead) {
      horizontal = currentHorizontal;
    } else {
      horizontal = diff >= -dead;
    }

    if (horizontal) {
      if (current != null && currentHorizontal && dx.abs() <= dead) {
        return current;
      }
      return dx < 0 ? GuidancePattern.left : GuidancePattern.right;
    }
    if (current != null && !currentHorizontal && dy.abs() <= dead) {
      return current;
    }
    return dy < 0 ? GuidancePattern.up : GuidancePattern.down;
  }

  bool _beatPlaying(int now) =>
      _lastBeatAt != null && now < _lastBeatAt! + _lastBeatLength;

  bool _dueForBeat(int now, DistanceBand band) {
    final last = _lastBeatAt;
    if (last == null) return true;
    final slow = feedback.slowPatterns ? 1.5 : 1.0;
    final interval = (band.repeatMs * slow).round();
    final earliest = last + _lastBeatLength + minGapMs;
    final due = last + interval;
    return now >= (due > earliest ? due : earliest);
  }

  int _amplitude(DistanceBand band) {
    final base = feedback.intensity.amplitude;
    final scale = switch (band) {
      DistanceBand.far => 0.6,
      DistanceBand.middle => 0.8,
      DistanceBand.close => 1.0,
    };
    return (base * scale).round().clamp(1, 255);
  }

  PlayBeat _beat(int now, GuidancePattern p, int amp, {GuidancePattern? cue}) {
    _lastBeatAt = now;
    _lastBeatLength = p.durationMs(slow: feedback.slowPatterns);
    _beatCount++;
    return PlayBeat(p, amp, spokenCue: cue);
  }
}
