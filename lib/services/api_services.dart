import 'dart:convert';

<<<<<<< HEAD
=======
import 'package:flutter/foundation.dart';
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
import 'package:http/http.dart' as http;

class ApiService {
  // =========================================================
  // BACKEND URL
  // =========================================================

<<<<<<< HEAD
  static const String baseUrl =
      "https://resqai-production-a6af.up.railway.app";

  // =========================================================
  // INCIDENT REPORTS
  // =========================================================

  static Future<http.Response> submitIncidentReport({
    required String firebaseIdToken,
    required String type,
    required String severity,
    required double latitude,
    required double longitude,
    required double accuracyM,
    required String locationText,
    required String description,
    required List<String> photoUrls,
  }) async {
    return http.post(
      Uri.parse("$baseUrl/incident-reports"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $firebaseIdToken",
      },
      body: jsonEncode({
        "type": type,
        "severity": severity,
        "latitude": latitude,
        "longitude": longitude,
        "accuracyM": accuracyM,
        "locationText": locationText,
        "description": description,
        "photoUrls": photoUrls,
      }),
    );
=======
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000";
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:5000";
    }

    return "http://localhost:5000";
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
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

<<<<<<< HEAD
      headers: {
        "Content-Type": "application/json",
      },
=======
      headers: {"Content-Type": "application/json"},
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

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

<<<<<<< HEAD
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
=======
  static Future<http.Response> login(String email, String password) async {
    return await http.post(
      Uri.parse("$baseUrl/login"),

      headers: {"Content-Type": "application/json"},

      body: jsonEncode({"email": email, "password": password}),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
    );
  }

  // =========================================================
  // CHECK PHONE
  // =========================================================

<<<<<<< HEAD
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
=======
  static Future<http.Response> checkPhone(String phone) async {
    return await http.post(
      Uri.parse("$baseUrl/check-phone"),

      headers: {"Content-Type": "application/json"},

      body: jsonEncode({"phone": phone}),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
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
<<<<<<< HEAD
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
=======
        "Authorization": "Bearer $firebaseIdToken",
      },

      body: jsonEncode({"phone": phone, "password": newPassword}),
    );
  }

  // =========================================================
  // LANDSLIDE PREDICTION
  // =========================================================

  static Future<http.Response> predictLandslide(
    Map<String, double> features,
  ) async {
    return http
        .post(
          Uri.parse("$baseUrl/api/landslide/predict"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(features),
        )
        .timeout(const Duration(seconds: 20));
  }
}
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
