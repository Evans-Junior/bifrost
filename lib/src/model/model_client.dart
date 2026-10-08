import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../settings/app_settings.dart';

/// Thrown when the model server cannot be reached or returns an error.
class ModelConnectionException implements Exception {
  ModelConnectionException(this.message);

  final String message;

  @override
  String toString() => 'ModelConnectionException: $message';
}

/// Thrown when the server is reachable but refuses for now (HTTP 429 or
/// 503), e.g. a rate-limited free tier.
class ModelBusyException implements Exception {
  ModelBusyException(this.message);

  final String message;

  @override
  String toString() => 'ModelBusyException: $message';
}

/// Thrown when the server does not offer the configured model (HTTP 404),
/// e.g. a wrong model name or a withdrawn free tier.
class ModelUnavailableException implements Exception {
  ModelUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'ModelUnavailableException: $message';
}

/// Sends chat requests to the vision-language model.
abstract class ModelClient {
  /// Streams text deltas of the model's reply. Cancelled through [cancel].
  Stream<String> streamChat(
    AppSettings settings,
    List<Map<String, dynamic>> messages, {
    CancelToken? cancel,
  });
}

/// [ModelClient] for any OpenAI-compatible `/chat/completions` endpoint
/// (vLLM on the lab GPU, or a hosted service during development).
class OpenAiCompatibleClient implements ModelClient {
  OpenAiCompatibleClient([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Request body for [messages] following the settings in Section 4.
  static Map<String, dynamic> requestBody(
    AppSettings settings,
    List<Map<String, dynamic>> messages,
  ) {
    return {
      'model': settings.modelName.trim(),
      'messages': messages,
      'temperature': 0.2,
      'stream': true,
      'response_format': {'type': 'json_object'},
      ..._reasoningFields(settings.reasoningEffort),
    };
  }

  /// vLLM disables Qwen thinking through `chat_template_kwargs`; OpenRouter
  /// uses the `reasoning` object. Both ignore the other's field.
  static Map<String, dynamic> _reasoningFields(ReasoningEffort effort) {
    if (effort == ReasoningEffort.off) {
      return {
        'chat_template_kwargs': {'enable_thinking': false},
        'reasoning': {'enabled': false},
      };
    }
    return {'reasoning_effort': effort.name};
  }

  static String _endpoint(String baseUrl) {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return trimmed.endsWith('/chat/completions')
        ? trimmed
        : '$trimmed/chat/completions';
  }

  @override
  Stream<String> streamChat(
    AppSettings settings,
    List<Map<String, dynamic>> messages, {
    CancelToken? cancel,
  }) async* {
    final Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        _endpoint(settings.modelBaseUrl),
        data: requestBody(settings, messages),
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            if (settings.apiKey.isNotEmpty)
              'Authorization': 'Bearer ${settings.apiKey}',
            'Accept': 'text/event-stream',
          },
          sendTimeout: Duration(seconds: settings.timeoutS),
          receiveTimeout: Duration(seconds: settings.timeoutS),
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      final status = e.response?.statusCode;
      if (status == 429 || status == 503) {
        throw ModelBusyException('HTTP $status');
      }
      if (status == 404) throw ModelUnavailableException('HTTP 404');
      throw ModelConnectionException(
        status != null ? 'HTTP $status' : (e.message ?? e.type.name),
      );
    }

    final lines = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    yield* SseChatDecoder.decode(lines);
  }
}

/// Decodes OpenAI-style server-sent events into content deltas. Also accepts
/// a plain (non-streamed) JSON completion, for servers that ignore `stream`.
class SseChatDecoder {
  static Stream<String> decode(Stream<String> lines) async* {
    final plain = StringBuffer();
    var sawEvent = false;
    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith(':')) continue;
      if (!trimmed.startsWith('data:')) {
        if (!sawEvent) plain.writeln(line);
        continue;
      }
      sawEvent = true;
      final data = trimmed.substring(5).trim();
      if (data == '[DONE]') break;
      final delta = _deltaContent(data);
      if (delta != null && delta.isNotEmpty) yield delta;
    }
    if (!sawEvent && plain.isNotEmpty) {
      final content = _messageContent(plain.toString());
      if (content != null) yield content;
    }
  }

  static String? _deltaContent(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final error = json['error'];
      if (error != null) {
        final code = error is Map ? error['code'] : null;
        if (code == 429 || code == 503) throw ModelBusyException('$error');
        if (code == 404) throw ModelUnavailableException('$error');
        throw ModelConnectionException('$error');
      }
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final delta = (choices.first as Map)['delta'] as Map?;
      return delta?['content'] as String?;
    } on FormatException {
      return null;
    }
  }

  static String? _messageContent(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final message = (choices.first as Map)['message'] as Map?;
      return message?['content'] as String?;
    } on FormatException {
      return null;
    }
  }
}
