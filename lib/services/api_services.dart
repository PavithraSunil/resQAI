import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // =========================================================
  // BACKEND URL
  // =========================================================

  static String get baseUrl {
  return "https://resqai-production-a6af.up.railway.app";
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
      headers: {"Content-Type": "application/json"},
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

  static Future<http.Response> login(String email, String password) async {
    return await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
  }

  // =========================================================
  // CHECK PHONE
  // =========================================================

  static Future<http.Response> checkPhone(String phone) async {
    return await http.post(
      Uri.parse("$baseUrl/check-phone"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone}),
    );
  }

  // =========================================================
  // FORGOT PASSWORD
  // =========================================================

  static Future<http.Response> forgotPassword(String email) async {
    return await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
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
