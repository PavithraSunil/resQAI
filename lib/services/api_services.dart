import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // =========================================================
  // BACKEND URL
  // =========================================================

  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000";
    }

    if (defaultTargetPlatform ==
        TargetPlatform.android) {
      return "http://10.0.2.2:5000";
    }

    return "http://localhost:5000";
  }

  // =========================================================
  // REGISTER
  // =========================================================

  static Future<http.Response> register(
    String fullname,
    String email,
    String password,
    String phone,
  ) async {
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

  // =========================================================
  // LOGIN
  // =========================================================

  static Future<http.Response> login(
    String email,
    String password,
  ) async {
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

  // =========================================================
  // CHECK PHONE
  // =========================================================

  static Future<http.Response> checkPhone(
    String phone,
  ) async {
    return await http.post(
      Uri.parse("$baseUrl/check-phone"),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "phone": phone,
      }),
    );
  }

  // =========================================================
  // RESET PASSWORD
  // =========================================================

  static Future<http.Response> resetPassword(
    String phone,
    String newPassword,
    String firebaseIdToken,
  ) async {
    return await http.post(
      Uri.parse("$baseUrl/reset-password"),

      headers: {
        "Content-Type": "application/json",

        // Firebase authentication proof
        "Authorization":
            "Bearer $firebaseIdToken",
      },

      body: jsonEncode({
        "phone": phone,
        "password": newPassword,
      }),
    );
  }
}