import 'dart:convert';
<<<<<<< HEAD
import 'dart:developer' as developer;
=======
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

<<<<<<< HEAD
import 'services/api_services.dart';

=======
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
<<<<<<< HEAD
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
=======
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {
  final TextEditingController emailController =
      TextEditingController();
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

  bool isLoading = false;

  // =========================================================
  // SEND PASSWORD RESET EMAIL
  // =========================================================

  Future<void> sendResetEmail() async {
<<<<<<< HEAD
    final email = emailController.text.trim().toLowerCase();
=======
    final email =
        emailController.text.trim().toLowerCase();
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

    if (email.isEmpty) {
      showMessage("Please enter your email address.");
      return;
    }

<<<<<<< HEAD
    if (!email.contains("@") || !email.contains(".")) {
=======
    if (!email.contains("@") ||
        !email.contains(".")) {
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
      showMessage("Please enter a valid email address.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
<<<<<<< HEAD
        Uri.parse("${ApiService.baseUrl}/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      developer.log("Forgot password response: ${response.statusCode}");

      developer.log("Forgot password body: ${response.body}");
=======
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
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

<<<<<<< HEAD
      if (response.statusCode == 200 && data["success"] == true) {
        showMessage("Password reset link has been sent to your email.");
      } else {
        showMessage(data["message"] ?? "Unable to send reset email.");
=======
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
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

<<<<<<< HEAD
      developer.log("Forgot password error: $e");
=======
      print("Forgot password error: $e");
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

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

<<<<<<< HEAD
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
=======
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
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
<<<<<<< HEAD
        title: const Text("Forgot Password"),
=======
        title: const Text(
          "Forgot Password",
        ),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [
<<<<<<< HEAD
=======

>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
              const SizedBox(height: 50),

              // =================================================
              // ICON
              // =================================================
<<<<<<< HEAD
              const Icon(Icons.lock_reset, color: Colors.red, size: 90),
=======

              const Icon(
                Icons.lock_reset,
                color: Colors.red,
                size: 90,
              ),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

              const SizedBox(height: 25),

              // =================================================
              // TITLE
              // =================================================
<<<<<<< HEAD
=======

>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
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
<<<<<<< HEAD
                style: TextStyle(fontSize: 17, color: Colors.black87),
=======
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black87,
                ),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
              ),

              const SizedBox(height: 40),

              // =================================================
              // EMAIL
              // =================================================
<<<<<<< HEAD
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
=======

              TextField(
                controller: emailController,
                keyboardType:
                    TextInputType.emailAddress,
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

                decoration: InputDecoration(
                  labelText: "Email Address",
                  hintText: "example@gmail.com",

<<<<<<< HEAD
                  prefixIcon: const Icon(Icons.email),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
=======
                  prefixIcon: const Icon(
                    Icons.email,
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // SEND RESET LINK BUTTON
              // =================================================
<<<<<<< HEAD
=======

>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,

<<<<<<< HEAD
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: isLoading ? null : sendResetEmail,
=======
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
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

                  child: isLoading
                      ? const SizedBox(
                          height: 25,
                          width: 25,

<<<<<<< HEAD
                          child: CircularProgressIndicator(
=======
                          child:
                              CircularProgressIndicator(
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Send Reset Link",
<<<<<<< HEAD
                          style: TextStyle(fontSize: 18),
=======
                          style: TextStyle(
                            fontSize: 18,
                          ),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
                        ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // INFORMATION
              // =================================================
<<<<<<< HEAD
=======

>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
              const Text(
                "A password reset link will be sent to your "
                "registered email address.",
                textAlign: TextAlign.center,
<<<<<<< HEAD
                style: TextStyle(color: Colors.black54, fontSize: 14),
=======
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
              ),

              const SizedBox(height: 30),

              // =================================================
              // BACK TO LOGIN
              // =================================================
<<<<<<< HEAD
=======

>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },

<<<<<<< HEAD
                child: const Text("Back to Login"),
=======
                child: const Text(
                  "Back to Login",
                ),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
              ),
            ],
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
