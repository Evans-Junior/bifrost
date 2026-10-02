import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bifrost/l10n/gen/app_localizations.dart';
import 'package:bifrost/src/conversation/object_registry.dart';
import 'package:bifrost/src/guards/guards.dart';
import 'package:bifrost/src/intent/intent_classifier.dart';
import 'package:bifrost/src/model/model_client.dart';
import 'package:bifrost/src/model/prompt_builder.dart';
import 'package:bifrost/src/model/response_parser.dart';
import 'package:bifrost/src/model/vlm_response.dart';
import 'package:bifrost/src/settings/app_settings.dart';
import 'package:bifrost/src/turn/turn_pipeline.dart';
import 'package:bifrost/src/vision/ocr_result.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

/// Reads a model-output fixture from `test/fixtures/model/`.
String modelFixture(String name) =>
    File('test/fixtures/model/$name').readAsStringSync();

/// Parses a model-output fixture.
VlmResponse responseFixture(String name) =>
    const ResponseParser().parse(modelFixture(name));

AppLocalizations l10nFor(String code) => lookupAppLocalizations(Locale(code));

/// Settings that pass `isServerConfigured`.
const testSettings = AppSettings(
  modelBaseUrl: 'http://localhost:8000/v1',
  modelName: 'Qwen/Qwen3.8-27B',
  timeoutS: 2,
);

/// Reads prompt assets from disk instead of the asset bundle.
class FilePromptAssets implements PromptAssets {
  @override
  Future<String> load(String fileName) =>
      File('assets/prompts/$fileName').readAsString();
}

/// A [ModelClient] that replays scripted replies, one per call. Each reply
/// is either a String (streamed in small chunks) or an Exception (thrown).
class FakeModelClient implements ModelClient {
  FakeModelClient(this.replies, {this.delay = Duration.zero});

  final List<Object> replies;
  final Duration delay;
  final List<List<Map<String, dynamic>>> requests = [];

  @override
  Stream<String> streamChat(
    AppSettings settings,
    List<Map<String, dynamic>> messages, {
    CancelToken? cancel,
  }) async* {
    requests.add(messages);
    final reply = replies[requests.length - 1];
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (reply is Exception) throw reply;
    final text = reply as String;
    for (var i = 0; i < text.length; i += 16) {
      yield text.substring(i, i + 16 > text.length ? text.length : i + 16);
    }
  }
}

/// A turn context with a dummy image.
const testContext = TurnContext(
  transcript: 'What is this?',
  intent: 'ASK',
  imageBase64Jpeg: 'AAAA',
);

/// Guards 1 then 4, the response-level guards that need no context.
VlmResponse basicGuards(Guards g, VlmResponse r, List<GuardEvent> log) =>
    g.noGuessFilling(g.confidenceConsistency(r, log), log);

/// OCR that read exactly [lines].
OcrResult ocrOf(List<String> lines) => OcrResult([
  for (final l in lines)
    OcrLine(l, left: 0.4, top: 0.4, width: 0.2, height: 0.1),
]);

/// A pipeline input for an ASK turn with a fresh registry.
TurnInput askInput({
  OcrResult ocr = OcrResult.empty,
  TurnContext context = testContext,
}) => TurnInput(
  context: context,
  intent: IntentType.ask,
  registry: ObjectRegistry(),
  ocr: ocr,
);

/// Reads an intents file from disk.
IntentClassifier classifierFor(String code) => IntentClassifier.fromJson(
  jsonDecode(File('assets/intents/$code.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// Reads a JSON fixture (OCR, scripts) from `test/fixtures/`.
dynamic jsonFixture(String path) =>
    jsonDecode(File('test/fixtures/$path').readAsStringSync());

/// Reads a fixture file from `test/fixtures/` as text.
String jsonFixtureText(String path) =>
    File('test/fixtures/$path').readAsStringSync();
