import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../settings/app_settings.dart';
import 'locale_picker.dart';

/// Text-to-speech output. Every [speak] completes when speech ends or is
/// interrupted by [stop].
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _configured = false;
  AppLanguage? _language;
  double? _rate;

  /// Applies language and rate from Settings. Cheap to call every turn.
  Future<void> configure(AppLanguage language, double rate) async {
    if (!_configured) {
      await _tts.awaitSpeakCompletion(true);
      if (Platform.isIOS) {
        // Speak through the loudspeaker even after the microphone was used.
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playAndRecord,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          ],
        );
      }
      _configured = true;
    }
    if (language != _language) {
      await _tts.setLanguage(await _resolve(language.localeTag));
      _language = language;
    }
    if (rate != _rate) {
      await _tts.setSpeechRate(rate);
      _rate = rate;
    }
  }

  /// Picks the closest voice language the device has (fr-CA, then fr-FR...).
  Future<String> _resolve(String wanted) async {
    final langs = await _tts.getLanguages;
    final available = langs is List ? langs.map((l) => '$l') : <String>[];
    final picked = LocalePicker.pick(wanted, available);
    if (picked == null) {
      debugPrint('[tts] no voice for $wanted on this device');
      return wanted;
    }
    if (picked != wanted) debugPrint('[tts] $wanted unavailable, using $picked');
    return picked;
  }

  /// Speaks [text] and waits until it finishes.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  /// Interrupts any speech immediately.
  Future<void> stop() async => _tts.stop();
}
