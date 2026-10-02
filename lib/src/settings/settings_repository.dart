import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_settings.dart';
import 'env_defaults.dart';

/// Loads and saves [AppSettings] in `flutter_secure_storage`, so the API key
/// and server address never live in source code. Server fields set in the
/// development `.env` file ([EnvDefaults]) take priority over Settings.
class SettingsRepository {
  SettingsRepository({
    FlutterSecureStorage? storage,
    Future<Map<String, String>> Function()? envLoader,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _envLoader = envLoader ?? EnvDefaults.load;

  final FlutterSecureStorage _storage;
  final Future<Map<String, String>> Function() _envLoader;

  static const _baseUrl = 'MODEL_BASE_URL';
  static const _modelName = 'MODEL_NAME';
  static const _apiKey = 'API_KEY';
  static const _reasoning = 'REASONING_EFFORT';
  static const _timeout = 'TIMEOUT_S';
  static const _language = 'LANGUAGE';
  static const _speechRate = 'SPEECH_RATE';
  static const _profile = 'PROFILE';
  static const _positionStyle = 'POSITION_STYLE';
  static const _logServerUrl = 'LOG_SERVER_URL';
  static const _logToken = 'LOG_TOKEN';
  static const _participant = 'PARTICIPANT';

  Future<AppSettings> load() async =>
      merge(await _storage.readAll(), await _envLoader());

  /// Builds settings from [stored] values. Any server field present in [env]
  /// overrides storage, so editing `.env` always takes effect.
  static AppSettings merge(
    Map<String, String> stored,
    Map<String, String> env,
  ) {
    const d = AppSettings();
    String? pick(String key) {
      final s = stored[key];
      return env[key] ?? ((s != null && s.trim().isNotEmpty) ? s : null);
    }

    return AppSettings(
      modelBaseUrl: pick(_baseUrl) ?? d.modelBaseUrl,
      modelName: pick(_modelName) ?? d.modelName,
      apiKey: pick(_apiKey) ?? d.apiKey,
      reasoningEffort: ReasoningEffort.fromName(pick(_reasoning)),
      timeoutS: int.tryParse(pick(_timeout) ?? '') ?? d.timeoutS,
      language: AppLanguage.fromCode(stored[_language]),
      speechRate: double.tryParse(stored[_speechRate] ?? '') ?? d.speechRate,
      profile: VisionProfile.fromKey(stored[_profile]),
      positionStyle: PositionStyle.fromKey(stored[_positionStyle]),
      logServerUrl: pick(_logServerUrl) ?? d.logServerUrl,
      logToken: pick(_logToken) ?? d.logToken,
      participant: pick(_participant) ?? d.participant,
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
      _logServerUrl: s.logServerUrl.trim(),
      _logToken: s.logToken,
      _participant: s.participant.trim(),
    };
    for (final e in values.entries) {
      await _storage.write(key: e.key, value: e.value);
    }
  }
}

/// Server values from the development `.env` file, empty when it is absent.
final envDefaultsProvider = FutureProvider<Map<String, String>>(
  (ref) => EnvDefaults.load(),
);

/// Provides the [SettingsRepository].
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) =>
      SettingsRepository(envLoader: () => ref.read(envDefaultsProvider.future)),
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
