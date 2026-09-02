import 'dart:convert';

import 'package:flutter/material.dart';

import 'registration_page.dart';
import 'dashboard_page.dart';
import 'forgot_password_page.dart';
import 'services/api_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // =========================================================
  // UI VARIABLES
  // =========================================================

  bool _obscurePassword = true;
  bool _isLoading = false;

  // =========================================================
  // TEXT CONTROLLERS
  // =========================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // =========================================================
  // LOGIN USER
  // =========================================================

  Future<void> loginUser() async {
    // ---------------------------------------------------------
    // CHECK EMPTY FIELDS
    // ---------------------------------------------------------

    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter email and password",
          ),
        ),
      );

      return;
    }

    // ---------------------------------------------------------
    // START LOADING
    // ---------------------------------------------------------

    setState(() {
      _isLoading = true;
    });

    try {
      // -------------------------------------------------------
      // CALL BACKEND LOGIN API
      // -------------------------------------------------------

      final response = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      // -------------------------------------------------------
      // DECODE RESPONSE
      // -------------------------------------------------------

      final data = jsonDecode(response.body);

      if (!mounted) return;

      // -------------------------------------------------------
      // LOGIN SUCCESS
      // -------------------------------------------------------

      if (response.statusCode == 200 &&
          data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? "Login successful",
            ),
          ),
        );

        // -----------------------------------------------------
        // GO TO DASHBOARD
        // -----------------------------------------------------

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardPage(),
          ),
        );
      }

      // -------------------------------------------------------
      // LOGIN FAILED
      // -------------------------------------------------------

      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? "Login Failed",
            ),
          ),
        );
      }
    } catch (e) {
      // -------------------------------------------------------
      // CONNECTION ERROR
      // -------------------------------------------------------

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Connection Error\n$e",
          ),
        ),
      );
    }

    // ---------------------------------------------------------
    // STOP LOADING
    // ---------------------------------------------------------

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // =======================================================
      // BODY
      // =======================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
          ),

          child: Column(
            children: [

              const SizedBox(height: 50),

              // ------------------------------------------------
              // APP ICON
              // ------------------------------------------------

              const Icon(
                Icons.health_and_safety,
                color: Colors.red,
                size: 90,
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // APP NAME
              // ------------------------------------------------

              const Text(
                "ResQAI",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 8),

              // ------------------------------------------------
              // WELCOME MESSAGE
              // ------------------------------------------------

              const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 40),

              // ------------------------------------------------
              // EMAIL FIELD
              // ------------------------------------------------

              TextField(
                controller: emailController,

                keyboardType:
                    TextInputType.emailAddress,

                decoration: InputDecoration(
                  labelText: "Email",

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

              const SizedBox(height: 20),

              // ------------------------------------------------
              // PASSWORD FIELD
              // ------------------------------------------------

              TextField(
                controller: passwordController,

                obscureText: _obscurePassword,

                decoration: InputDecoration(
                  labelText: "Password",

                  prefixIcon: const Icon(
                    Icons.lock,
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // =================================================
              // FORGOT PASSWORD
              // =================================================

              Align(
                alignment: Alignment.centerRight,

                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (context) =>
                            const ForgotPasswordPage(),
                      ),
                    );
                  },

                  child: const Text(
                    "Forgot Password?",
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // LOGIN BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  onPressed:
                      _isLoading ? null : loginUser,

                  child: _isLoading
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
                          "Login",

                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // REGISTER
              // =================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const Text(
                    "Don't have an account?",
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) =>
                              const RegistrationPage(),
                        ),
                      );
                    },

                    child: const Text(
                      "Register",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}