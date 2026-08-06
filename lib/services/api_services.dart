import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000";
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:5000";
    }
    return "http://localhost:5000";
  }

  // Register User
  static Future<http.Response> register(
      String fullname,
      String email,
      String password,
      String phone) async {

    return await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "fullname": fullname,
        "email": email,
        "password": password,
        "phone": phone,
      }),
    );
  }

  // Login User
  static Future<http.Response> login(
      String email,
      String password) async {
    return await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
  }
}
