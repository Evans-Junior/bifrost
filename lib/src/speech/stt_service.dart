import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'locale_picker.dart';

/// Hold-to-talk speech recognition. [start] on press, [stop] on release
/// returns the final transcript.
class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  String _words = '';
  Completer<String>? _final;
  final Map<String, String> _resolved = {};

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

  /// Starts listening in [localeId] (for example `fr_CA`), or the closest
  /// locale the device supports.
  Future<bool> start(String localeId) async {
    if (!await init()) return false;
    final locale = await _resolve(localeId);
    _words = '';
    _final = Completer<String>();
    await _stt.listen(
      onResult: (r) {
        _words = r.recognizedWords;
        if (r.finalResult) _complete();
      },
      listenOptions: SpeechListenOptions(
        localeId: locale,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        listenMode: ListenMode.confirmation,
      ),
    );
    return true;
  }

  /// Maps the wanted locale to one the recognizer has, once per locale.
  Future<String> _resolve(String wanted) async {
    final cached = _resolved[wanted];
    if (cached != null) return cached;
    final available = (await _stt.locales()).map((l) => l.localeId);
    final picked = LocalePicker.pick(wanted, available) ?? wanted;
    if (picked != wanted) debugPrint('[stt] $wanted unavailable, using $picked');
    return _resolved[wanted] = picked;
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
