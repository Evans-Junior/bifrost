import '../settings/feedback_settings.dart';
import '../vision/geometry.dart';

/// An object the on-device detector is tracking in the camera stream.
class TrackedObject {
  const TrackedObject(this.trackingId, this.box);

  final int trackingId;
  final NormBox box;
}

/// Chooses what the guidance aims at (Section 11):
/// - default: the largest tracked object nearest the centre;
/// - locked: after the model names a referent with a bbox, the tracked
///   object overlapping it most (IoU ≥ threshold), until the step ends,
///   STOP, or it is unseen for [VisionThresholds.lostAfterMs].
class TargetTracker {
  TargetTracker({this.thresholds = const VisionThresholds()});

  VisionThresholds thresholds;

  int? _lockedId;
  int? _lastSeenAt;
  NormBox? _lastBox;

  bool get isLocked => _lockedId != null;
  int? get lockedId => _lockedId;

  /// Locks onto the tracked object that best overlaps the model's [bbox].
  /// Returns true if a lock was made.
  bool lockFromBbox(NormBox bbox, List<TrackedObject> objects, int nowMs) {
    TrackedObject? best;
    var bestIou = 0.0;
    for (final o in objects) {
      final iou = o.box.iou(bbox);
      if (iou > bestIou) {
        bestIou = iou;
        best = o;
      }
    }
    if (best == null || bestIou < thresholds.lockIou) return false;
    _lockedId = best.trackingId;
    _lastSeenAt = nowMs;
    _lastBox = best.box;
    return true;
  }

  /// Drops the lock (task step ended, STOP, new question).
  void unlock() {
    _lockedId = null;
    _lastSeenAt = null;
    _lastBox = null;
  }

  /// The target for this frame, or null if there is nothing to aim at.
  /// Sets [lostLock] when a locked target has been unseen too long.
  NormBox? target(List<TrackedObject> objects, int nowMs) {
    lostLock = false;
    final id = _lockedId;
    if (id != null) {
      for (final o in objects) {
        if (o.trackingId == id) {
          _lastSeenAt = nowMs;
          _lastBox = o.box;
          return o.box;
        }
      }
      if (nowMs - (_lastSeenAt ?? nowMs) < thresholds.lostAfterMs) {
        return _lastBox; // briefly unseen: keep guiding to where it was
      }
      unlock();
      lostLock = true;
      return null;
    }
    return defaultTarget(objects);
  }

  /// True after [target] dropped a lock because the object was lost.
  bool lostLock = false;

  /// The largest object nearest the centre: area minus a centre-distance
  /// penalty.
  static NormBox? defaultTarget(List<TrackedObject> objects) {
    NormBox? best;
    var bestScore = double.negativeInfinity;
    for (final o in objects) {
      final dx = o.box.centerX - 0.5;
      final dy = o.box.centerY - 0.5;
      final score = o.box.area - (dx * dx + dy * dy);
      if (score > bestScore) {
        bestScore = score;
        best = o.box;
      }
    }
    return best;
  }
}
