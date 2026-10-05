// Phase 3 acceptance on fixtures: watch mode, glare, OCR cross-check,
// geometry and the camera-frame helpers (Section 14).

import 'dart:typed_data';

import 'package:bifrost/src/conversation/conversation_engine.dart';
import 'package:bifrost/src/guidance/target_tracker.dart';
import 'package:bifrost/src/intent/intent_classifier.dart';
import 'package:bifrost/src/model/prompt_builder.dart';
import 'package:bifrost/src/turn/turn_pipeline.dart';
import 'package:bifrost/src/vision/geometry.dart';
import 'package:bifrost/src/vision/luma.dart';
import 'package:bifrost/src/settings/app_settings.dart';
import 'package:bifrost/src/vision/ocr_result.dart';
import 'package:bifrost/src/vision/scene_monitor.dart';
import 'package:bifrost/src/watch/watch_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A grid with a saturated (glare) square over [box].
LumaGrid gridWithGlare(NormBox? box, {int w = 120, int h = 160}) {
  final v = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final inGlare =
          box != null &&
          x >= box.left * w &&
          x < box.right * w &&
          y >= box.top * h &&
          y < box.bottom * h;
      // Textured background so the frame is sharp.
      v[y * w + x] = inGlare ? 255 : ((x * 7 + y * 13) % 2 == 0 ? 60 : 160);
    }
  }
  return LumaGrid(w, h, v);
}

void main() {
  group('watch mode (Section 12)', () {
    test(
      'speaks within 1 s of the label becoming readable (rotation fixture)',
      () {
        final fixture = jsonFixture('watch/cumin_rotation.json') as Map;
        final readableFrom = fixture['readable_from_ms'] as int;
        final watch = WatchController()..start(0);
        int? triggeredAt;
        for (final f in fixture['frames'] as List) {
          final at = f['at_ms'] as int;
          final events = watch.onFrame(
            at,
            ocrOf([for (final l in f['lines'] as List) l as String]),
          );
          if (events.any((e) => e.type == WatchEventType.trigger)) {
            triggeredAt = at;
            expect(events.first.tokens, contains('CUMIN'));
            break;
          }
        }
        expect(triggeredAt, isNotNull);
        expect(triggeredAt! - readableFrom, lessThanOrEqualTo(1000));
        expect(
          triggeredAt,
          greaterThanOrEqualTo(readableFrom),
          reason: 'never triggers on partial text',
        );
      },
    );

    test('pulses every 2 s and times out after 20 s', () {
      final watch = WatchController()..start(0);
      final events = <WatchEvent>[];
      for (var t = 0; t <= 21000; t += 250) {
        events.addAll(watch.onFrame(t, OcrResult.empty));
      }
      expect(
        events.where((e) => e.type == WatchEventType.pulse).length,
        inInclusiveRange(9, 10),
      );
      expect(events.last.type, WatchEventType.timeout);
      expect(watch.isActive, isFalse);
    });

    test('short fragments (under 3 letters) never trigger', () {
      final watch = WatchController()..start(0);
      expect(watch.onFrame(0, ocrOf(['45 g'])), isEmpty);
      expect(watch.onFrame(250, ocrOf(['45 g'])), isEmpty);
    });

    test('cancel stops everything', () {
      final watch = WatchController()..start(0);
      watch.cancel();
      expect(watch.onFrame(250, ocrOf(['CUMIN'])), isEmpty);
      expect(watch.tick(30000), isEmpty);
    });
  });

  group('glare and blur (Section 11)', () {
    final target = const NormBox(0.3, 0.3, 0.4, 0.4);

    test('glare fixture: saturated pixels inside the target box', () {
      final g = gridWithGlare(const NormBox(0.3, 0.3, 0.4, 0.2));
      expect(LumaMetrics.glareFraction(g, target), closeTo(0.5, 0.05));
      expect(LumaMetrics.glareFraction(gridWithGlare(null), target), 0);
    });

    test('a flat image is blurry, a textured one is sharp', () {
      final flat = LumaGrid(50, 50, Uint8List(2500)..fillRange(0, 2500, 128));
      expect(LumaMetrics.laplacianVariance(flat), 0);
      expect(
        LumaMetrics.laplacianVariance(gridWithGlare(null)),
        greaterThan(1000),
      );
    });

    test('glare is reported once per event; blur after 1 s', () {
      final m = SceneMonitor();
      final events = <SceneEvent>[];
      for (var t = 0; t < 3000; t += 200) {
        events.addAll(
          m.update(
            SceneSnapshot(
              atMs: t,
              glareFraction: t < 1000 ? 0.4 : 0.0,
              blurVariance: t >= 1000 ? 5 : 500,
            ),
          ),
        );
      }
      expect(events, [
        SceneEvent.glareStarted,
        SceneEvent.glareEnded,
        SceneEvent.blurStarted,
      ]);
    });

    test('a stale snapshot counts as unknown', () {
      final m = SceneMonitor()..update(const SceneSnapshot(atMs: 0));
      expect(m.fresh(500), isNotNull);
      expect(m.fresh(5000), isNull);
    });
  });

  group('pre-check (Section 7 step 3, script step 10)', () {
    late FakeModelClient client;
    late ConversationEngine engine;
    final classifier = classifierFor('en');
    setUp(() {
      client = FakeModelClient([modelFixture('labelled_jar_read.json')]);
      engine = ConversationEngine(
        TurnPipeline(
          client: client,
          prompts: PromptBuilder(FilePromptAssets()),
        ),
      );
    });

    Future<EngineReply> ask(String text, SceneSnapshot? scene) => engine.handle(
      transcript: text,
      settings: testSettings,
      classifier: classifier,
      capture: () async => CapturedFrame('AAAA', ocrOf(['CUMIN'])),
      scene: () => scene,
    );

    final jar = TrackedObject(1, const NormBox(0.3, 0.3, 0.4, 0.4));

    test(
      'glare fixture: "Glare. Tilt it away…" before any model call',
      () async {
        final g = gridWithGlare(const NormBox(0.3, 0.3, 0.4, 0.4));
        final scene = SceneSnapshot(
          atMs: 0,
          objects: [jar],
          glareFraction: LumaMetrics.glareFraction(g, jar.box),
        );
        final r = await ask("What's this?", scene);
        expect(r.preCheck, PreCheck.glare);
        expect(r.text, 'Glare. Tilt it away from the light.');
        expect(client.requests, isEmpty);
      },
    );

    test('nothing detected: aiming hint instead of a model call', () async {
      final r = await ask("What's this?", const SceneSnapshot(atMs: 0));
      expect(r.preCheck, PreCheck.nothingInView);
      expect(r.text, 'Nothing in view. Sweep slowly.');
      expect(client.requests, isEmpty);
    });

    test('START_TASK and search tasks skip the pre-check', () async {
      final r = await ask('Help me sort these', const SceneSnapshot(atMs: 0));
      expect(r.preCheck, isNull);
      expect(client.requests, hasLength(1));
    });

    test(
      'a clear view goes to the model; no stream means no pre-check',
      () async {
        expect(
          (await ask(
            "What's this?",
            SceneSnapshot(atMs: 0, objects: [jar]),
          )).usedModel,
          isTrue,
        );
        client.replies.add(modelFixture('labelled_jar_read.json'));
        expect((await ask("What's this?", null)).usedModel, isTrue);
      },
    );
  });

  group('watch offer after CANT_SEE (script steps 2–3)', () {
    test(
      'offers watch mode, "yes" starts it, trigger asks again as ASK',
      () async {
        final client = FakeModelClient([
          modelFixture('label_away_clean.json'),
          modelFixture('labelled_jar_read.json'),
        ]);
        final engine = ConversationEngine(
          TurnPipeline(
            client: client,
            prompts: PromptBuilder(FilePromptAssets()),
          ),
        );
        final classifier = classifierFor('en');
        Future<CapturedFrame> capture() async =>
            CapturedFrame('AAAA', ocrOf(['CUMIN']));

        final away = await engine.handle(
          transcript: "What's this?",
          settings: testSettings,
          classifier: classifier,
          capture: capture,
        );
        expect(away.offeredWatch, isTrue);
        expect(away.text, endsWith('Want me to tell you when I can read it?'));

        final yes = await engine.handle(
          transcript: 'Yes please',
          settings: testSettings,
          classifier: classifier,
          capture: capture,
        );
        expect(yes.startWatch, isTrue);
        expect(client.requests, hasLength(1), reason: '"yes" is local');

        final read = await engine.handleWatchTrigger(
          settings: testSettings,
          classifier: classifier,
          capture: capture,
        );
        expect(read.text, contains('I read this directly.'));
        final userText =
            (client.requests.last[1]['content'] as List).first['text']
                as String;
        expect(userText, contains('INTENT: ASK'));
        expect(userText, contains("USER_SAID: What's this?"));
      },
    );

    test('"no" declines, anything else is handled normally', () async {
      final engine = ConversationEngine(
        TurnPipeline(
          client: FakeModelClient([modelFixture('label_away_clean.json')]),
          prompts: PromptBuilder(FilePromptAssets()),
        ),
      );
      final c = classifierFor('fr');
      final fr = testSettings.copyWith(language: AppLanguage.fr);
      await engine.handle(
        transcript: "C'est quoi ?",
        settings: fr,
        classifier: c,
        capture: () async => CapturedFrame('A'),
      );
      final no = await engine.handle(
        transcript: 'Non merci',
        settings: fr,
        classifier: c,
        capture: () async => null,
      );
      expect(no.text, "D'accord.");
      expect(no.startWatch, isFalse);
    });
  });

  test('WATCH intent starts watch mode locally', () async {
    final engine = ConversationEngine(
      TurnPipeline(
        client: FakeModelClient([]),
        prompts: PromptBuilder(FilePromptAssets()),
      ),
    );
    final r = await engine.handle(
      transcript: 'tell me when you can read it',
      settings: testSettings,
      classifier: classifierFor('en'),
      capture: () async => null,
    );
    expect(r.intent.type, IntentType.watch);
    expect(r.startWatch, isTrue);
    expect(r.text, 'Watching. Turn it slowly.');
  });

  group('camera frame helpers', () {
    test('Android NV21 frame in sensor orientation is turned upright', () {
      // Raw landscape 4x2 frame; rotating 90° clockwise makes it 2x4.
      // Raw row 0: 10 20 30 40, row 1: 50 60 70 80.
      final raw = Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]);
      final g = LumaGrid.fromPlane(
        bytes: raw,
        rawWidth: 4,
        rawHeight: 2,
        bytesPerRow: 4,
        format: FrameFormat.nv21,
        rotationDegrees: 90,
        targetLong: 4,
      );
      expect([g.width, g.height], [2, 4]);
      // Upright top-left is the raw bottom-left pixel.
      expect(g.at(0, 0), 50);
      expect(g.at(1, 0), 10);
      expect(g.at(0, 3), 80);
    });

    test('iOS BGRA pixels become luma', () {
      final white = Uint8List.fromList([255, 255, 255, 255]);
      final g = LumaGrid.fromPlane(
        bytes: white,
        rawWidth: 1,
        rawHeight: 1,
        bytesPerRow: 4,
        format: FrameFormat.bgra8888,
        rotationDegrees: 0,
      );
      expect(g.at(0, 0), greaterThanOrEqualTo(254));
    });

    test('IoU and full-view margin', () {
      const a = NormBox(0, 0, 0.5, 0.5);
      expect(a.iou(a), 1);
      expect(a.iou(const NormBox(0.5, 0.5, 0.5, 0.5)), 0);
      expect(const NormBox(0.1, 0.1, 0.8, 0.8).insideWithMargin(0.05), isTrue);
      expect(const NormBox(0.0, 0.1, 0.8, 0.8).insideWithMargin(0.05), isFalse);
    });

    test('270° detections are mirrored horizontally', () {
      final b = normalizeDetection(
        left: 0,
        top: 0,
        width: 100,
        height: 100,
        imageWidth: 1000,
        imageHeight: 1000,
        rotationDegrees: 270,
        isIOS: false,
      );
      expect(b.left, closeTo(0.9, 1e-9));
    });
  });
}
