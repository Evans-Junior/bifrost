import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../camera/camera_service.dart';
import '../guidance/target_tracker.dart';
import 'geometry.dart';
import 'luma.dart';
import 'ocr_result.dart';
import 'scene_monitor.dart';

/// One analysed preview frame.
class FrameResult {
  const FrameResult(this.scene, [this.ocr]);

  final SceneSnapshot scene;

  /// Text found in this frame, only while watch mode is on.
  final OcrResult? ocr;
}

/// Analyses the rear-camera stream on the device (Section 5): ML Kit object
/// detection with tracking, glare and blur checks, and OCR while watch mode
/// is on. Frames arriving while the previous one is still being processed
/// are dropped, so only recent frames are analysed. Nothing leaves the phone.
class StreamAnalyzer {
  StreamAnalyzer(this._camera);

  final CameraService _camera;

  /// About 5 frames per second for detection, glare and blur.
  static const frameIntervalMs = 200;

  /// About 4 per second for OCR in watch mode.
  static const ocrIntervalMs = 250;

  final ObjectDetector _detector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: false,
      multipleObjects: true,
    ),
  );
  final TextRecognizer _ocr = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final _results = StreamController<FrameResult>.broadcast();
  _MetricsWorker? _worker;

  bool _busy = false;
  int _lastFrame = 0;
  int _lastOcr = 0;

  /// Turn on while watch mode needs OCR on the stream.
  bool ocrEnabled = false;

  /// Returns the box to measure glare in, given this frame's objects.
  NormBox? Function(List<TrackedObject>)? targetFor;

  Stream<FrameResult> get results => _results.stream;

  bool get isRunning => _camera.isStreaming;

  Future<void> start() async {
    _worker ??= await _MetricsWorker.spawn();
    await _camera.startStream(_onFrame);
  }

  Future<void> stop() => _camera.stopStream();

  void _onFrame(CameraImage image) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_busy || now - _lastFrame < frameIntervalMs) return; // frame dropping
    _busy = true;
    _lastFrame = now;
    _process(image, now).whenComplete(() => _busy = false);
  }

  Future<void> _process(CameraImage image, int now) async {
    try {
      final input = _inputImage(image);
      if (input == null) return;
      final isIOS = Platform.isIOS;
      final rotation = _camera.sensorOrientation;

      final detected = await _detector.processImage(input);
      final objects = [
        for (final o in detected)
          if (o.trackingId != null)
            TrackedObject(
              o.trackingId!,
              normalizeDetection(
                left: o.boundingBox.left,
                top: o.boundingBox.top,
                width: o.boundingBox.width,
                height: o.boundingBox.height,
                imageWidth: image.width.toDouble(),
                imageHeight: image.height.toDouble(),
                rotationDegrees: rotation,
                isIOS: isIOS,
              ),
            ),
      ];
      final target = targetFor?.call(objects);

      final plane = image.planes.first;
      final grid = LumaGrid.fromPlane(
        bytes: plane.bytes,
        rawWidth: image.width,
        rawHeight: image.height,
        bytesPerRow: plane.bytesPerRow,
        format: isIOS ? FrameFormat.bgra8888 : FrameFormat.nv21,
        // iOS frames arrive upright; Android frames are in sensor orientation.
        rotationDegrees: isIOS ? 0 : rotation,
      );
      final metrics = await _worker!.measure(grid, target);

      OcrResult? ocr;
      if (ocrEnabled && now - _lastOcr >= ocrIntervalMs) {
        _lastOcr = now;
        final text = await _ocr.processImage(input);
        ocr = OcrResult([
          for (final b in text.blocks)
            for (final l in b.lines) OcrLine(l.text),
        ]);
      }

      if (!_results.isClosed) {
        _results.add(
          FrameResult(
            SceneSnapshot(
              atMs: now,
              objects: objects,
              glareFraction: metrics.$1,
              blurVariance: metrics.$2,
              target: target,
            ),
            ocr,
          ),
        );
      }
    } catch (e) {
      debugPrint('[stream] frame failed: $e');
    }
  }

  /// Builds an ML Kit image from a camera frame, as in the official
  /// google_mlkit_commons README (nv21 on Android, bgra8888 on iOS).
  InputImage? _inputImage(CameraImage image) {
    final rotation = InputImageRotationValue.fromRawValue(
      _camera.sensorOrientation,
    );
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null || format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> dispose() async {
    await stop();
    await _detector.close();
    await _ocr.close();
    _worker?.close();
    await _results.close();
  }
}

/// A long-lived background isolate that measures glare and blur, so the
/// UI isolate never does pixel loops (Section 7, concurrency).
class _MetricsWorker {
  _MetricsWorker(this._isolate, this._send, this._replies);

  final Isolate _isolate;
  final SendPort _send;
  final Stream<dynamic> _replies;

  static Future<_MetricsWorker> spawn() async {
    final inbox = ReceivePort();
    final isolate = await Isolate.spawn(_main, inbox.sendPort);
    final replies = inbox.asBroadcastStream();
    final send = await replies.first as SendPort;
    return _MetricsWorker(isolate, send, replies);
  }

  /// Returns (glare fraction inside [box], Laplacian variance).
  Future<(double, double)> measure(LumaGrid g, NormBox? box) async {
    final reply = _replies.first;
    _send.send([
      g.width,
      g.height,
      TransferableTypedData.fromList([g.values]),
      box?.toList(),
    ]);
    final r = await reply as List;
    return (r[0] as double, r[1] as double);
  }

  void close() => _isolate.kill(priority: Isolate.immediate);

  static void _main(SendPort out) {
    final inbox = ReceivePort();
    out.send(inbox.sendPort);
    inbox.listen((msg) {
      final m = msg as List;
      final bytes = (m[2] as TransferableTypedData).materialize().asUint8List();
      final grid = LumaGrid(
        m[0] as int,
        m[1] as int,
        Uint8List.fromList(bytes),
      );
      final boxList = (m[3] as List?)?.cast<double>();
      final box = boxList == null ? null : NormBox.fromList(boxList);
      out.send([
        LumaMetrics.glareFraction(grid, box),
        LumaMetrics.laplacianVariance(grid),
      ]);
    });
  }
}
