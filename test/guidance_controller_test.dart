// Phase 3 acceptance: GuidanceController unit tests (Section 14).

import 'package:bifrost/src/guidance/guidance_controller.dart';
import 'package:bifrost/src/guidance/patterns.dart';
import 'package:bifrost/src/guidance/target_tracker.dart';
import 'package:bifrost/src/settings/feedback_settings.dart';
import 'package:bifrost/src/vision/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 0.1 × 0.1 box centred at (cx, cy).
NormBox at(double cx, double cy, {double size = 0.1}) =>
    NormBox(cx - size / 2, cy - size / 2, size, size);

/// Runs the controller every 50 ms for [ms] with a fixed target and
/// returns (time, beat) pairs.
List<(int, PlayBeat)> run(
  GuidanceController g,
  NormBox? target, {
  int from = 0,
  int ms = 5000,
}) {
  final beats = <(int, PlayBeat)>[];
  for (var t = from; t < from + ms; t += 50) {
    for (final c in g.tick(t, target)) {
      if (c is PlayBeat) beats.add((t, c));
    }
  }
  return beats;
}

List<int> gaps(List<(int, PlayBeat)> beats) => [
  for (var i = 1; i < beats.length; i++) beats[i].$1 - beats[i - 1].$1,
];

void main() {
  group('direction', () {
    test('target left, right, above and below centre', () {
      expect(
        run(GuidanceController(), at(0.2, 0.5)).first.$2.pattern,
        GuidancePattern.left,
      );
      expect(
        run(GuidanceController(), at(0.8, 0.5)).first.$2.pattern,
        GuidancePattern.right,
      );
      expect(
        run(GuidanceController(), at(0.5, 0.15)).first.$2.pattern,
        GuidancePattern.up,
      );
      expect(
        run(GuidanceController(), at(0.5, 0.85)).first.$2.pattern,
        GuidancePattern.down,
      );
    });

    test('the larger offset wins; similar offsets go horizontal first', () {
      expect(
        run(GuidanceController(), at(0.3, 0.1)).first.$2.pattern,
        GuidancePattern.up,
        reason: '|dy| 0.8 > |dx| 0.4',
      );
      expect(
        run(GuidanceController(), at(0.2, 0.21)).first.$2.pattern,
        GuidancePattern.left,
        reason: 'similar offsets -> horizontal',
      );
    });

    test('image-to-user mapping: image left is the user\'s left', () {
      // A detection on the left of a portrait rear-camera frame (Android,
      // sensor rotated 90°): x is scaled by the raw image height.
      final box = normalizeDetection(
        left: 100,
        top: 900,
        width: 200,
        height: 200,
        imageWidth: 1920,
        imageHeight: 1080,
        rotationDegrees: 90,
        isIOS: false,
      );
      expect(box.centerX, lessThan(0.5));
      expect(
        run(GuidanceController(), box).first.$2.pattern,
        GuidancePattern.left,
      );
      // Same object on iOS, where frames are already upright.
      final ios = normalizeDetection(
        left: 100,
        top: 900,
        width: 200,
        height: 200,
        imageWidth: 1080,
        imageHeight: 1920,
        rotationDegrees: 90,
        isIOS: true,
      );
      expect(ios.centerX, lessThan(0.5));
    });
  });

  group('distance', () {
    test('repeat interval shrinks as the target gets closer', () {
      final far = gaps(run(GuidanceController(), at(0.1, 0.5)));
      final middle = gaps(run(GuidanceController(), at(0.25, 0.5)));
      final close = gaps(run(GuidanceController(), at(0.4, 0.5)));
      expect(far.first, 1200);
      expect(middle.first, 700);
      // Close beats are 400 ms apart, or more if the beat itself is long.
      expect(close.first, lessThan(middle.first));
      expect(middle.first, lessThan(far.first));
    });

    test('amplitude rises as the target gets closer', () {
      final far = run(GuidanceController(), at(0.1, 0.5)).first.$2.amplitude;
      final close = run(GuidanceController(), at(0.4, 0.5)).first.$2.amplitude;
      expect(close, greaterThan(far));
    });

    test('slow patterns lengthen the interval', () {
      final g = GuidanceController(
        feedback: const FeedbackSettings(slowPatterns: true),
      );
      expect(gaps(run(g, at(0.1, 0.5))).first, 1800);
    });
  });

  group('hysteresis', () {
    test('a new direction must hold 300 ms before the pattern changes', () {
      final g = GuidanceController();
      run(g, at(0.2, 0.5), ms: 1000);
      expect(g.direction, GuidancePattern.left);
      // Overshoot to the right for only 200 ms: no change.
      run(g, at(0.8, 0.5), from: 1000, ms: 200);
      expect(g.direction, GuidancePattern.left);
      run(g, at(0.8, 0.5), from: 1200, ms: 400);
      expect(g.direction, GuidancePattern.right);
    });

    test('no flip within the dead zone of the switch point', () {
      final g = GuidanceController();
      run(g, at(0.2, 0.5), ms: 500); // left
      // Now |dx| and |dy| nearly equal, |dy| slightly larger: still left.
      for (var i = 0; i < 20; i++) {
        final wobble = i.isEven ? 0.21 : 0.19;
        run(g, at(0.2, wobble), from: 500 + i * 100, ms: 100);
      }
      expect(g.direction, GuidancePattern.left);
    });

    test('no left/right flip while the target is near the centre line', () {
      final g = GuidanceController();
      run(g, at(0.45, 0.1), ms: 400); // up
      run(g, at(0.3, 0.5), from: 400, ms: 1000); // left
      for (var i = 0; i < 10; i++) {
        run(g, at(i.isEven ? 0.48 : 0.52, 0.9), from: 1400 + i * 100, ms: 100);
      }
      expect(g.direction, isNot(GuidancePattern.right));
    });
  });

  test('beats never overlap and keep at least 250 ms between them', () {
    final g = GuidanceController();
    final beats = run(g, at(0.5, 0.95), ms: 8000); // down = longest beat
    expect(beats.length, greaterThan(3));
    for (var i = 1; i < beats.length; i++) {
      final prevLength = beats[i - 1].$2.pattern.durationMs();
      expect(
        beats[i].$1 - beats[i - 1].$1,
        greaterThanOrEqualTo(prevLength + GuidanceController.minGapMs),
      );
    }
  });

  test('full-view buzz plays once, then silence', () {
    final g = GuidanceController();
    final beats = run(g, at(0.5, 0.5, size: 0.4), ms: 5000);
    expect(beats, hasLength(1));
    expect(beats.single.$2.pattern, GuidancePattern.fullView);
    expect(g.fullViewReached, isTrue);
  });

  test('nothing to aim at: no vibration, one spoken line', () {
    final g = GuidanceController();
    final cmds = <GuidanceCommand>[];
    for (var t = 0; t < 3000; t += 50) {
      cmds.addAll(g.tick(t, null));
    }
    expect(cmds.whereType<PlayBeat>(), isEmpty);
    expect(cmds.whereType<SayNothingInView>(), hasLength(1));
  });

  test('settings off: no vibration and no speech at all', () {
    final g = GuidanceController(
      feedback: const FeedbackSettings(vibrationGuidance: false),
    );
    final cmds = <GuidanceCommand>[];
    for (var t = 0; t < 3000; t += 50) {
      cmds
        ..addAll(g.tick(t, at(0.1, 0.5)))
        ..addAll(g.tick(t, null))
        ..addAll(g.tick(t, at(0.5, 0.5, size: 0.4)));
    }
    expect(cmds, isEmpty);
  });

  test('"also speak direction" adds a cue every third beat', () {
    final g = GuidanceController(
      feedback: const FeedbackSettings(speakDirection: true),
    );
    final beats = run(g, at(0.1, 0.5), ms: 6000);
    expect(
      [for (final b in beats) b.$2.spokenCue != null],
      [false, false, true, false, false],
    );
  });

  test('script step 11: keys to the left, overshoot, then full view', () {
    // The user turns the phone left: the keys drift from the far left to
    // the centre, overshoot to the right, and come back to full view.
    final g = GuidanceController();
    final beats = <(int, PlayBeat)>[];
    var t = 0;
    void hold(NormBox box, int ms) {
      beats.addAll(run(g, box, from: t, ms: ms));
      t += ms;
    }

    hold(at(0.08, 0.5), 2500); // far left
    hold(at(0.3, 0.5), 2000); // middle left
    hold(at(0.4, 0.5), 1500); // close left
    hold(at(0.75, 0.5), 2000); // overshoot right
    hold(at(0.5, 0.5, size: 0.35), 2000); // in full view

    final patterns = [for (final b in beats) b.$2.pattern];
    final firstRight = patterns.indexOf(GuidancePattern.right);
    expect(patterns.first, GuidancePattern.left);
    expect(firstRight, greaterThan(0), reason: 'switches after overshoot');
    expect(patterns.sublist(0, firstRight).toSet(), {GuidancePattern.left});
    expect(patterns.last, GuidancePattern.fullView);
    expect(patterns.where((p) => p == GuidancePattern.fullView), hasLength(1));

    final leftBeats = beats.where((b) => b.$2.pattern == GuidancePattern.left);
    final leftGaps = gaps(leftBeats.toList());
    expect(leftGaps.last, lessThan(leftGaps.first), reason: 'repeats faster');
  });

  group('target tracker', () {
    final objects = [
      TrackedObject(1, at(0.2, 0.5, size: 0.2)),
      TrackedObject(2, at(0.55, 0.5, size: 0.3)),
    ];

    test('default target: largest object nearest the centre', () {
      expect(
        TargetTracker.defaultTarget(objects)!.centerX,
        closeTo(0.55, 1e-9),
      );
      expect(TargetTracker.defaultTarget(const []), isNull);
    });

    test('locks onto the best IoU match, only above the threshold', () {
      final t = TargetTracker();
      expect(t.lockFromBbox(at(0.21, 0.5, size: 0.2), objects, 0), isTrue);
      expect(t.lockedId, 1);
      expect(TargetTracker().lockFromBbox(at(0.9, 0.9), objects, 0), isFalse);
    });

    test('a lost lock is kept briefly, then dropped after 3 s', () {
      final t = TargetTracker()..lockFromBbox(objects.first.box, objects, 0);
      expect(t.target(const [], 1000), isNotNull);
      expect(t.target(const [], 3500), isNull);
      expect(t.lostLock, isTrue);
      expect(t.isLocked, isFalse);
    });
  });
}
