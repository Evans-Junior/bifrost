import 'dart:convert';

import 'package:flutter/services.dart';

import '../settings/app_settings.dart';

/// Loads prompt text from `assets/prompts/` so the team can edit wording
/// without touching code.
abstract class PromptAssets {
  Future<String> load(String fileName);
}

/// [PromptAssets] backed by the Flutter asset bundle.
class BundlePromptAssets implements PromptAssets {
  BundlePromptAssets([AssetBundle? bundle]) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<String> load(String fileName) =>
      _bundle.loadString('assets/prompts/$fileName');
}

/// One earlier exchange, sent to the model as text only (no images).
class PastTurn {
  const PastTurn({required this.user, required this.assistant});

  final String user;
  final String assistant;
}

/// The context sent with every model call (Section 7, step 5).
class TurnContext {
  const TurnContext({
    required this.transcript,
    required this.intent,
    required this.imageBase64Jpeg,
    this.objectRegistry = const [],
    this.taskState = const {},
    this.recentTurns = const [],
    this.ocrText = const [],
    this.extras = const {},
  });

  final String transcript;
  final String intent;
  final String imageBase64Jpeg;
  final List<Map<String, dynamic>> objectRegistry;
  final Map<String, dynamic> taskState;
  final List<PastTurn> recentTurns;
  final List<Map<String, dynamic>> ocrText;

  /// Extra labelled blocks for REPAIR and CHALLENGE, e.g.
  /// `CHOSEN_REFERENT`, `CLARIFICATION_OPTIONS`, `PREVIOUS_ANSWER`.
  final Map<String, Object?> extras;
}

/// Builds OpenAI-compatible chat messages for one turn.
class PromptBuilder {
  PromptBuilder(this._assets);

  final PromptAssets _assets;
  final Map<String, String> _cache = {};

  /// Maximum number of earlier turns included as text.
  static const maxRecentTurns = 6;

  Future<String> _load(String name) async =>
      _cache[name] ??= (await _assets.load(name)).trim();

  /// The system prompt for [settings]: language- and profile-specific, with
  /// the schema appended.
  Future<String> systemPrompt(AppSettings settings) async {
    final lang = settings.language.code;
    final base = await _load('system_$lang.txt');
    final position = await _load(
      'position_${settings.positionStyle.assetKey}_$lang.txt',
    );
    final language = await _load('language_$lang.txt');
    final profile = await _load(
      'profile_${settings.profile.assetKey}_$lang.txt',
    );
    final schema = await _load('response_schema.json');
    final filled = base
        .replaceAll('{POSITION_STYLE_INSTRUCTION}', position)
        .replaceAll('{LANGUAGE}', language);
    return '$filled\n\n$profile\n\nSchema:\n$schema';
  }

  /// The retry instruction used when a clarification lacks two options.
  Future<String> clarificationRetryInstruction(AppSettings settings) =>
      _load('retry_clarification_${settings.language.code}.txt');

  /// The retry instruction used after invalid JSON.
  Future<String> retryInstruction(AppSettings settings) =>
      _load('retry_invalid_json_${settings.language.code}.txt');

  /// Builds the full message list for [ctx].
  Future<List<Map<String, dynamic>>> messages(
    AppSettings settings,
    TurnContext ctx,
  ) async {
    return [
      {'role': 'system', 'content': await systemPrompt(settings)},
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': userText(ctx)},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:image/jpeg;base64,${ctx.imageBase64Jpeg}',
            },
          },
        ],
      },
    ];
  }

  /// The labelled text block that accompanies the image.
  String userText(TurnContext ctx) {
    final recent = ctx.recentTurns.length > maxRecentTurns
        ? ctx.recentTurns.sublist(ctx.recentTurns.length - maxRecentTurns)
        : ctx.recentTurns;
    final turns = [
      for (final t in recent) {'user': t.user, 'assistant': t.assistant},
    ];
    return [
      'OBJECT_REGISTRY: ${jsonEncode(ctx.objectRegistry)}',
      'TASK_STATE: ${jsonEncode(ctx.taskState)}',
      'RECENT_TURNS: ${jsonEncode(turns)}',
      'INTENT: ${ctx.intent}',
      'OCR_TEXT: ${jsonEncode(ctx.ocrText)}',
      for (final e in ctx.extras.entries) '${e.key}: ${jsonEncode(e.value)}',
      'USER_SAID: ${ctx.transcript}',
    ].join('\n');
  }
}
