import '../guidance/target_tracker.dart';
import '../settings/feedback_settings.dart';
import 'geometry.dart';

/// What the camera stream showed most recently (Section 5).
class SceneSnapshot {
  const SceneSnapshot({
    required this.atMs,
    this.objects = const [],
    this.glareFraction = 0,
    this.blurVariance = double.infinity,
    this.target,
  });

  final int atMs;
  final List<TrackedObject> objects;

  /// Saturated-pixel fraction inside the current target (or whole frame).
  final double glareFraction;
  final double blurVariance;

  /// The box guidance is aiming at, if any.
  final NormBox? target;

  bool get hasObject => objects.isNotEmpty;
}

/// Glare and blur problems, spoken once per event (Section 11).
enum SceneEvent { glareStarted, glareEnded, blurStarted, blurEnded }

/// Turns per-frame measurements into once-per-event glare and blur
/// warnings. Pure Dart.
class SceneMonitor {
  SceneMonitor({this.thresholds = const VisionThresholds()});

  VisionThresholds thresholds;

  SceneSnapshot? _latest;
  bool _glare = false;
  bool _blur = false;
  int? _blurrySince;

  SceneSnapshot? get latest => _latest;
  bool get glare => _glare;
  bool get blurry => _blur;

  /// Records a new frame and returns the events it caused.
  List<SceneEvent> update(SceneSnapshot s) {
    _latest = s;
    final events = <SceneEvent>[];

    final glareNow = s.glareFraction > thresholds.glareFraction;
    if (glareNow != _glare) {
      _glare = glareNow;
      events.add(glareNow ? SceneEvent.glareStarted : SceneEvent.glareEnded);
    }

    final blurryFrame = s.blurVariance < thresholds.blurVariance;
    if (blurryFrame) {
      _blurrySince ??= s.atMs;
      if (!_blur && s.atMs - _blurrySince! >= thresholds.blurForMs) {
        _blur = true;
        events.add(SceneEvent.blurStarted);
      }
    } else {
      _blurrySince = null;
      if (_blur) {
        _blur = false;
        events.add(SceneEvent.blurEnded);
      }
    }
    return events;
  }

  /// A snapshot older than this is treated as unknown.
  static const staleAfterMs = 1500;

  /// The latest snapshot if it is fresh, else null (no stream running).
  SceneSnapshot? fresh(int nowMs) {
    final s = _latest;
    if (s == null || nowMs - s.atMs > staleAfterMs) return null;
    return s;
  }
}
