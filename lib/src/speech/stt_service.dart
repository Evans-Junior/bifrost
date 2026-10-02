import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

/// Hold-to-talk speech recognition. [start] on press, [stop] on release
/// returns the final transcript.
class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  String _words = '';
  Completer<String>? _final;

  /// How long to wait for the recognizer's final result after release.
  static const finalWait = Duration(seconds: 2);

  /// Initializes the recognizer and asks for microphone and speech access.
  Future<bool> init() async {
    if (_ready) return true;
    _ready = await _stt.initialize(
      onError: (_) => _complete(),
      onStatus: (status) {
        if (status == SpeechToText.doneStatus) _complete();
      },
    );
    return _ready;
  }

  /// Starts listening in [localeId] (for example `en_CA`).
  Future<bool> start(String localeId) async {
    if (!await init()) return false;
    _words = '';
    _final = Completer<String>();
    await _stt.listen(
      onResult: (r) {
        _words = r.recognizedWords;
        if (r.finalResult) _complete();
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        listenMode: ListenMode.confirmation,
      ),
    );
    return true;
  }

  /// Stops listening and returns the transcript (possibly empty).
  Future<String> stop() async {
    final pending = _final;
    if (pending == null) return '';
    await _stt.stop();
    return pending.future.timeout(finalWait, onTimeout: () => _words);
  }

  /// Stops listening and discards the transcript.
  Future<void> cancel() async {
    _complete();
    await _stt.cancel();
  }

  void _complete() {
    final pending = _final;
    if (pending != null && !pending.isCompleted) pending.complete(_words);
  }
}
