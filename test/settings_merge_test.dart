import 'package:bifrost/src/settings/app_settings.dart';
import 'package:bifrost/src/settings/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const env = {
    'MODEL_BASE_URL': 'https://openrouter.ai/api/v1',
    'MODEL_NAME': 'qwen/qwen3.8-27b:free',
    'API_KEY': 'sk-env',
    'TIMEOUT_S': '30',
  };

  test('.env values override stored Settings', () {
    final s = SettingsRepository.merge({
      'MODEL_BASE_URL': 'http://lab:8000/v1',
      'API_KEY': 'sk-stored',
      'TIMEOUT_S': '15',
    }, env);
    expect(s.modelBaseUrl, 'https://openrouter.ai/api/v1');
    expect(s.apiKey, 'sk-env');
    expect(s.timeoutS, 30);
  });

  test('fields missing from .env come from Settings', () {
    final s = SettingsRepository.merge(
      {'API_KEY': 'sk-stored', 'REASONING_EFFORT': 'low'},
      {'MODEL_BASE_URL': 'https://openrouter.ai/api/v1'},
    );
    expect(s.apiKey, 'sk-stored');
    expect(s.reasoningEffort, ReasoningEffort.low);
  });

  test('no .env and nothing stored gives the built-in defaults', () {
    final s = SettingsRepository.merge({}, {});
    expect(s.modelBaseUrl, isEmpty);
    expect(s.modelName, 'Qwen/Qwen3.8-27B');
    expect(s.timeoutS, 15);
    expect(s.isServerConfigured, isFalse);
  });

  test('empty stored values do not hide defaults', () {
    final s = SettingsRepository.merge({'MODEL_NAME': ''}, {});
    expect(s.modelName, 'Qwen/Qwen3.8-27B');
  });

  test('user preferences are never taken from .env', () {
    final s = SettingsRepository.merge(
        {'LANGUAGE': 'fr'}, {...env, 'LANGUAGE': 'en'});
    expect(s.language, AppLanguage.fr);
  });
}
