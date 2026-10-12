import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Railway backend URL
  static const String baseUrl =
      'https://resqai-production-a6af.up.railway.app';

  // Register User
  static Future<http.Response> register(
    String fullname,
    String email,
    String password,
    String phone,
  ) async {
    final url = Uri.parse('$baseUrl/register');

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullname': fullname,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );
  }

  // Login User
  static Future<http.Response> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/login');

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
  }
}