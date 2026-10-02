import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_settings.dart';

/// Loads and saves [AppSettings] in `flutter_secure_storage`, so the API key
/// and server address never live in source code.
class SettingsRepository {
  SettingsRepository([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _baseUrl = 'MODEL_BASE_URL';
  static const _modelName = 'MODEL_NAME';
  static const _apiKey = 'API_KEY';
  static const _reasoning = 'REASONING_EFFORT';
  static const _timeout = 'TIMEOUT_S';
  static const _language = 'LANGUAGE';
  static const _speechRate = 'SPEECH_RATE';
  static const _profile = 'PROFILE';
  static const _positionStyle = 'POSITION_STYLE';

  Future<AppSettings> load() async {
    final all = await _storage.readAll();
    const d = AppSettings();
    return AppSettings(
      modelBaseUrl: all[_baseUrl] ?? d.modelBaseUrl,
      modelName: all[_modelName] ?? d.modelName,
      apiKey: all[_apiKey] ?? d.apiKey,
      reasoningEffort: ReasoningEffort.fromName(all[_reasoning]),
      timeoutS: int.tryParse(all[_timeout] ?? '') ?? d.timeoutS,
      language: AppLanguage.fromCode(all[_language]),
      speechRate: double.tryParse(all[_speechRate] ?? '') ?? d.speechRate,
      profile: VisionProfile.fromKey(all[_profile]),
      positionStyle: PositionStyle.fromKey(all[_positionStyle]),
    );
  }

  Future<void> save(AppSettings s) async {
    final values = <String, String>{
      _baseUrl: s.modelBaseUrl.trim(),
      _modelName: s.modelName.trim(),
      _apiKey: s.apiKey,
      _reasoning: s.reasoningEffort.name,
      _timeout: '${s.timeoutS}',
      _language: s.language.code,
      _speechRate: '${s.speechRate}',
      _profile: s.profile.assetKey,
      _positionStyle: s.positionStyle.assetKey,
    };
    for (final e in values.entries) {
      await _storage.write(key: e.key, value: e.value);
    }
  }
}

/// Provides the [SettingsRepository].
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

/// Holds the current [AppSettings] and persists changes.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.read(settingsRepositoryProvider).load();

  /// Saves [settings] and makes them current immediately.
  Future<void> save(AppSettings settings) async {
    state = AsyncData(settings);
    await ref.read(settingsRepositoryProvider).save(settings);
  }
}

/// The app-wide settings provider.
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
