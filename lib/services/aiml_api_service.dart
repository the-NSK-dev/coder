import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AimlApiService {
  String _apiKey = '';

  void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  Future<String> complete(String prompt, {String model = 'meta-llama/Meta-Llama-3.1-8B-Instruct', String systemPrompt = ''}) async {
    if (_apiKey.isEmpty) {
      throw Exception('AIML API key not configured. Add it in Settings or use Band.ai.');
    }

    final url = Uri.parse(AppConfig.featherlessBaseUrl);
    final messages = [];
    if (systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'max_tokens': 4000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('AIML API Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyProject(String path) async {
    if (_apiKey.isEmpty) {
      throw Exception('AIML API key not configured.');
    }
    return true;
  }
}
