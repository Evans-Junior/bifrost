import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Development-only server defaults read from `assets/env/.env`
/// (git-ignored; see `.env.example`). Values set here override Settings.
/// Participant builds must be made without this file.
///
/// The file is bundled into the app, so builds made with a key in it must
/// not be shared outside the team.
class EnvDefaults {
  static const fileName = 'assets/env/.env';

  /// Keys read from the file; same names as the Settings fields.
  static const keys = [
    'MODEL_BASE_URL',
    'MODEL_NAME',
    'API_KEY',
    'REASONING_EFFORT',
    'TIMEOUT_S',
  ];

  /// Loads the file if present. Returns an empty map when it is missing.
  static Future<Map<String, String>> load() async {
    final env = DotEnv();
    await env.load(fileName: fileName, isOptional: true);
    return {
      for (final k in keys)
        if ((env.maybeGet(k) ?? '').trim().isNotEmpty) k: env.get(k).trim(),
    };
  }
}
