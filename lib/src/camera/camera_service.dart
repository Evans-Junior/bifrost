import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Owns the rear camera (Section 5). The camera points at objects on the
/// table, never at people; the front camera is never opened.
class CameraService {
  CameraController? _controller;
  int _sensorOrientation = 90;
  void Function(CameraImage)? _onFrame;

  /// How far the sensor image is rotated from upright (usually 90).
  int get sensorOrientation => _sensorOrientation;

  bool get isStreaming => _controller?.value.isStreamingImages ?? false;

  /// Starts delivering preview frames to [onFrame]. The caller drops
  /// frames it is too busy for.
  Future<void> startStream(void Function(CameraImage) onFrame) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isStreamingImages) {
      return;
    }
    _onFrame = onFrame;
    try {
      await c.startImageStream(onFrame);
    } on CameraException {
      _onFrame = null;
    }
  }

  Future<void> stopStream() async {
    final c = _controller;
    _onFrame = null;
    if (c != null && c.value.isStreamingImages) {
      try {
        await c.stopImageStream();
      } on CameraException {
        // Already stopped.
      }
    }
  }

  CameraController? get controller => _controller;

  bool get isReady => _controller?.value.isInitialized ?? false;

  /// Opens the rear camera. Returns false if there is none or access is
  /// denied.
  Future<bool> start() async {
    if (isReady) return true;
    try {
      final cameras = await availableCameras();
      final rear = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .firstOrNull;
      if (rear == null) return false;
      final controller = CameraController(
        rear,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        // The formats ML Kit accepts from a camera stream.
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      _controller = controller;
      _sensorOrientation = rear.sensorOrientation;
      return true;
    } on CameraException {
      return false;
    }
  }

  /// Captures a full-resolution still as JPEG bytes, or null on failure.
  /// The image is kept in memory only and never stored.
  Future<Uint8List?> captureStill() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) {
      return null;
    }
    try {
      return await _take(c);
    } on CameraException {
      // Some devices cannot take a still while streaming: pause the stream.
      final resume = _onFrame;
      if (resume == null) return null;
      await stopStream();
      try {
        return await _take(c);
      } on CameraException {
        return null;
      } finally {
        await startStream(resume);
      }
    }
  }

  Future<Uint8List> _take(CameraController c) async {
    final file = await c.takePicture();
    final bytes = await file.readAsBytes();
    await _deleteQuietly(file.path);
    return bytes;
  }

  /// The plugin writes stills to a temp file; delete it so no image is kept.
  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone.
    }
  }

  /// Releases the camera, for example when the app goes to the background.
  Future<void> stop() async {
    await stopStream();
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }
}
