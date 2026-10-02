import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Owns the rear camera (Section 5). The camera points at objects on the
/// table, never at people; the front camera is never opened.
class CameraService {
  CameraController? _controller;

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
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      _controller = controller;
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
      final file = await c.takePicture();
      final bytes = await file.readAsBytes();
      await _deleteQuietly(file.path);
      return bytes;
    } on CameraException {
      return null;
    }
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
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }
}
