import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {
  final TextEditingController emailController =
      TextEditingController();

  bool isLoading = false;

  // =========================================================
  // SEND PASSWORD RESET EMAIL
  // =========================================================

  Future<void> sendResetEmail() async {
    final email =
        emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      showMessage("Please enter your email address.");
      return;
    }

    if (!email.contains("@") ||
        !email.contains(".")) {
      showMessage("Please enter a valid email address.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          "http://localhost:5000/forgot-password",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
        }),
      );

      print(
        "Forgot password response: ${response.statusCode}",
      );

      print(
        "Forgot password body: ${response.body}",
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200 &&
          data["success"] == true) {
        showMessage(
          "Password reset link has been sent to your email.",
        );
      } else {
        showMessage(
          data["message"] ??
              "Unable to send reset email.",
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      print("Forgot password error: $e");

      showMessage(
        "Connection error.\nMake sure the Node.js backend is running.",
      );
    }
  }

  // =========================================================
  // SHOW MESSAGE
  // =========================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Forgot Password",
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [

              const SizedBox(height: 50),

              // =================================================
              // ICON
              // =================================================

              const Icon(
                Icons.lock_reset,
                color: Colors.red,
                size: 90,
              ),

              const SizedBox(height: 25),

              // =================================================
              // TITLE
              // =================================================

              const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Enter your registered email address",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 40),

              // =================================================
              // EMAIL
              // =================================================

              TextField(
                controller: emailController,
                keyboardType:
                    TextInputType.emailAddress,

                decoration: InputDecoration(
                  labelText: "Email Address",
                  hintText: "example@gmail.com",

                  prefixIcon: const Icon(
                    Icons.email,
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // SEND RESET LINK BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  onPressed:
                      isLoading
                          ? null
                          : sendResetEmail,

                  child: isLoading
                      ? const SizedBox(
                          height: 25,
                          width: 25,

                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Send Reset Link",
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // INFORMATION
              // =================================================

              const Text(
                "A password reset link will be sent to your "
                "registered email address.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // BACK TO LOGIN
              // =================================================

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text(
                  "Back to Login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}