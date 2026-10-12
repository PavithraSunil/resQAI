import 'dart:convert';
import 'package:http/http.dart' as http;

class LiveDataApi {
  // Flutter Web in Chrome:
  static const String baseUrl = 'http://127.0.0.1:8000';

  // For an Android emulator, use this instead:
  // static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<Map<String, dynamic>> fetchInputs({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/live-inputs').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 40));

    if (response.statusCode != 200) {
      throw Exception('Live data request failed: ${response.body}');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;

    return Map<String, dynamic>.from(result['inputs'] as Map);
  }
}
