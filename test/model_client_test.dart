import 'dart:convert';

import 'package:bifrost/src/model/model_client.dart';
import 'package:bifrost/src/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

String _chunk(String content) =>
    'data: ${jsonEncode({
      'choices': [
        {
          'delta': {'content': content},
        },
      ],
    })}';

void main() {
  group('SseChatDecoder', () {
    test('joins streamed deltas and stops at [DONE]', () async {
      final lines = Stream.fromIterable([
        ': keep-alive',
        _chunk('{"needs_'),
        '',
        _chunk('clarification": false}'),
        'data: [DONE]',
        _chunk('ignored'),
      ]);
      final text = await SseChatDecoder.decode(lines).join();
      expect(text, '{"needs_clarification": false}');
    });

    test('accepts a non-streamed completion body', () async {
      final body = jsonEncode({
        'choices': [
          {
            'message': {'content': '{"a": 1}'},
          },
        ],
      });
      final text = await SseChatDecoder.decode(Stream.value(body)).join();
      expect(text, '{"a": 1}');
    });

    test('rate-limit error event throws busy', () async {
      final lines = Stream.value(
        'data: {"error": {"code": 429, "message": "rate-limited upstream"}}',
      );
      expect(
        SseChatDecoder.decode(lines).join(),
        throwsA(isA<ModelBusyException>()),
      );
    });

    test('model-not-found error event throws unavailable', () async {
      final lines = Stream.value(
        'data: {"error": {"code": 404, "message": "unavailable for free"}}',
      );
      expect(
        SseChatDecoder.decode(lines).join(),
        throwsA(isA<ModelUnavailableException>()),
      );
    });

    test('server error event throws a connection error', () async {
      final lines = Stream.value('data: {"error": {"message": "overloaded"}}');
      expect(
        SseChatDecoder.decode(lines).join(),
        throwsA(isA<ModelConnectionException>()),
      );
    });
  });

  group('request body', () {
    test('uses Section 4 settings', () {
      final body = OpenAiCompatibleClient.requestBody(testSettings, []);
      expect(body['model'], 'Qwen/Qwen3.8-27B');
      expect(body['temperature'], 0.2);
      expect(body['stream'], isTrue);
      expect(body['response_format'], {'type': 'json_object'});
    });

    test('reasoning off disables Qwen thinking', () {
      final body = OpenAiCompatibleClient.requestBody(testSettings, []);
      expect(body['chat_template_kwargs'], {'enable_thinking': false});
      expect(body.containsKey('reasoning_effort'), isFalse);
    });

    test('reasoning low sends reasoning_effort', () {
      final body = OpenAiCompatibleClient.requestBody(
        testSettings.copyWith(reasoningEffort: ReasoningEffort.low),
        [],
      );
      expect(body['reasoning_effort'], 'low');
      expect(body.containsKey('chat_template_kwargs'), isFalse);
    });
  });
}
