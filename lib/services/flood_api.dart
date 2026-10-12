import 'dart:convert';
import 'package:http/http.dart' as http;

class FloodApi {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> predict(
    Map<String, dynamic> input,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Prediction failed (${response.statusCode}): ${response.body}',
    );
  }
}
