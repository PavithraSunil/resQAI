import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/api_services.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // =========================================================
  // TEXT CONTROLLERS
  // =========================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  // =========================================================
  // FIREBASE AUTHENTICATION
  // =========================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================================================
  // UI VARIABLES
  // =========================================================

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // =========================================================
  // REGISTER USER
  // =========================================================

  Future<void> registerUser() async {
    // ---------------------------------------------------------
    // CHECK EMPTY FIELDS
    // ---------------------------------------------------------

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    // ---------------------------------------------------------
    // GET VALUES
    // ---------------------------------------------------------

    final String name = nameController.text.trim();
    final String email =
        emailController.text.trim().toLowerCase();
    final String phone = phoneController.text.trim();
    final String password = passwordController.text;
    final String confirmPassword =
        confirmPasswordController.text;

    // ---------------------------------------------------------
    // CHECK EMAIL
    // ---------------------------------------------------------

    if (!isValidEmail(email)) {
      showMessage("Please enter a valid email address");
      return;
    }

    // ---------------------------------------------------------
    // CHECK PASSWORD
    // ---------------------------------------------------------

    if (password != confirmPassword) {
      showMessage("Passwords do not match");
      return;
    }

    if (password.length < 6) {
      showMessage(
        "Password must contain at least 6 characters",
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
      // =======================================================
      // STEP 1
      // CREATE FIREBASE ACCOUNT
      // =======================================================

      debugPrint("Creating Firebase account...");

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception(
          "Firebase could not create the user account.",
        );
      }

      debugPrint(
        "Firebase account created: ${user.uid}",
      );

      // =======================================================
      // STEP 2
      // SEND EMAIL VERIFICATION
      // =======================================================

      await user.sendEmailVerification();

      debugPrint(
        "Verification email sent to $email",
      );

      // =======================================================
      // STEP 3
      // SAVE USER TO POSTGRESQL
      // =======================================================

      debugPrint(
        "Saving user information to PostgreSQL...",
      );

      final response = await ApiService.register(
        name,
        email,
        password,
        phone,
      );

      debugPrint(
        "Backend response: ${response.statusCode}",
      );

      // -------------------------------------------------------
      // CHECK RESPONSE
      // -------------------------------------------------------

      Map<String, dynamic> data = {};

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        debugPrint(
          "Backend did not return JSON.",
        );
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // =======================================================
      // SUCCESS
      // =======================================================

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        await showRegistrationSuccessDialog();

        if (!mounted) return;

        Navigator.pop(context);
        return;
      }

      // =======================================================
      // POSTGRESQL ERROR
      // =======================================================

      showMessage(
        data["message"] ??
            "Firebase account created, but saving user information failed.",
      );
    }

    // =========================================================
    // FIREBASE ERRORS
    // =========================================================

    on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint(
        "Firebase error code: ${e.code}",
      );

      debugPrint(
        "Firebase error message: ${e.message}",
      );

      showMessage(
        getFirebaseErrorMessage(e),
      );
    }

    // =========================================================
    // OTHER ERRORS
    // =========================================================

    catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint(
        "Registration error: $e",
      );

      showMessage(
        "Registration failed.\n$e",
      );
    }
  }

  // =========================================================
  // EMAIL VALIDATION
  // =========================================================

  bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // =========================================================
  // REGISTRATION SUCCESS DIALOG
  // =========================================================

  Future<void> showRegistrationSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 30,
              ),
              SizedBox(width: 10),
              Text("Registration Successful"),
            ],
          ),
          content: const Text(
            "Your account has been created successfully.\n\n"
            "A verification email has been sent to your email address.\n\n"
            "Please verify your email before logging in.",
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // FIREBASE ERROR MESSAGES
  // =========================================================

  String getFirebaseErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case "email-already-in-use":
        return "An account already exists with this email.";

      case "invalid-email":
        return "The email address is invalid.";

      case "weak-password":
        return "The password is too weak.";

      case "operation-not-allowed":
        return "Email/Password authentication is not enabled in Firebase.";

      case "network-request-failed":
        return "Network error. Please check your internet connection.";

      case "too-many-requests":
        return "Too many attempts. Please try again later.";

      default:
        return e.message ??
            "Firebase authentication failed.";
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
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // =========================================================
  // USER INTERFACE
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // -------------------------------------------------------
      // APP BAR
      // -------------------------------------------------------

      appBar: AppBar(
        title: const Text(
          "Create Account",
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      // -------------------------------------------------------
      // BODY
      // -------------------------------------------------------

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [
              const SizedBox(height: 20),

              // ------------------------------------------------
              // ICON
              // ------------------------------------------------

              const Icon(
                Icons.health_and_safety,
                color: Colors.red,
                size: 80,
              ),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Join ResQAI",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // FULL NAME
              // ------------------------------------------------

              TextField(
                controller: nameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: const Icon(
                    Icons.person,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // EMAIL
              // ------------------------------------------------

              TextField(
                controller: emailController,
                keyboardType:
                    TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
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
              // PHONE
              // ------------------------------------------------

              TextField(
                controller: phoneController,
                keyboardType:
                    TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  hintText: "+919876543210",
                  prefixIcon: const Icon(
                    Icons.phone,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // PASSWORD
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

              const SizedBox(height: 20),

              // ------------------------------------------------
              // CONFIRM PASSWORD
              // ------------------------------------------------

              TextField(
                controller:
                    confirmPasswordController,
                obscureText:
                    _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // REGISTER BUTTON
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  onPressed:
                      _isLoading
                          ? null
                          : registerUser,

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
                          "Register",
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // ------------------------------------------------
              // LOGIN
              // ------------------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  const Text(
                    "Already have an account?",
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    child: const Text(
                      "Login",
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