import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenRouterModel {
  final String id;
  final String name;
  final String description;
  final bool supportsVision;
  final bool goodForRoleplay;
  final bool supportsReasoning;

  const OpenRouterModel({
    required this.id,
    required this.name,
    required this.description,
    this.supportsVision = false,
    this.goodForRoleplay = false,
    this.supportsReasoning = false,
  });
}

class OpenRouterClient {
  static const String defaultModelId = 'google/gemma-4-26b-a4b-it:free';
  static const List<OpenRouterModel> models = [
    OpenRouterModel(
      id: 'google/gemma-4-26b-a4b-it:free',
      name: 'google/gemma-4-26b-a4b-it:free',
      description: 'Reasoning-heavy model for complex analytical tasks.',
      supportsVision: true,
      supportsReasoning: true,
    ),
    OpenRouterModel(
      id: 'nvidia/nemotron-nano-12b-v2-vl:free',
      name: 'Nemotron Nano VL',
      description: 'Universal daily model with image support (multimodal).',
      supportsVision: true,
    ),
    OpenRouterModel(
      id: 'z-ai/glm-4.5-air:free',
      name: 'GLM 4.5 Air',
      description: 'Great for creative dialog and role-playing scenarios.',
      goodForRoleplay: true,
    ),
  ];

  final String apiKey;
  final String model;
  final bool enableReasoning;
  final http.Client _httpClient;

  OpenRouterClient(
    this.enableReasoning,
    this.apiKey, {
    this.model = defaultModelId,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Stream<String> streamChatCompletion(
    List<Map<String, dynamic>> messages, {
    void Function(String)? onReasoningChunk,
  }) async* {
    final request = http.Request(
      'POST',
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'http://localhost', // можно любое
      'X-Title': 'AI Chat Bot',
    });

    final payload = <String, dynamic>{
      'model': model,
      'stream': true,
      'messages': messages,
    };
    if (enableReasoning) {
      payload['reasoning'] = {'enabled': true};
    }

    request.body = jsonEncode(payload);

    final response = await _httpClient.send(request);
    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
        'Failed to get response from OpenRouter '
        '(status ${response.statusCode}): $errorBody',
      );
    }

    final stream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (!line.startsWith('data:')) continue;

      final data = line.substring(5).trimLeft();
      if (data.isEmpty) continue;

      if (data == '[DONE]') break;

      dynamic json;
      try {
        json = jsonDecode(data);
      } on FormatException {
        continue;
      }

      if (json is! Map<String, dynamic>) continue;
      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) continue;
      final firstChoice = choices.first;
      if (firstChoice is! Map<String, dynamic>) continue;
      final delta = firstChoice['delta'];

      if (delta is! Map<String, dynamic>) continue;
      final reasoningChunk = _extractReasoningChunk(delta);
      if (reasoningChunk.isNotEmpty) {
        onReasoningChunk?.call(reasoningChunk);
      }

      final content = delta['content'];
      if (content is String && content.isNotEmpty) {
        yield content;
        continue;
      }
      if (content is List) {
        for (final part in content) {
          if (part is Map<String, dynamic> && part['text'] is String) {
            final text = part['text'] as String;
            if (text.isNotEmpty) {
              yield text;
            }
          }
        }
      }
    }
  }

  String _extractReasoningChunk(Map<String, dynamic> delta) {
    final parts = <String>[];

    void addPart(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        parts.add(value);
      }
    }

    addPart(delta['reasoning']);
    addPart(delta['reasoning_content']);

    final details = delta['reasoning_details'];
    if (details is List) {
      for (final item in details) {
        if (item is! Map<String, dynamic>) continue;
        addPart(item['text']);
        addPart(item['content']);
        final content = item['content'];
        if (content is List) {
          for (final part in content) {
            if (part is Map<String, dynamic>) {
              addPart(part['text']);
            }
          }
        }
      }
    }

    return parts.join();
  }
}
