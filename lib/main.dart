import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
<<<<<<< HEAD
import 'dashboard_page.dart';
import 'login_page.dart';
=======
import 'login_page.dart';
import 'admin_login_page.dart';
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

<<<<<<< HEAD
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
=======
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0

  runApp(const ResQAIApp());
}

class ResQAIApp extends StatelessWidget {
  const ResQAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResQAI',
<<<<<<< HEAD
      theme: ThemeData(primarySwatch: Colors.red),
=======
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
<<<<<<< HEAD
        MaterialPageRoute(builder: (context) => const LoginPage()),
=======
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade700,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.health_and_safety,
                size: 100,
                color: Colors.white,
              ),

              const SizedBox(height: 25),

              const Text(
                "ResQAI",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "AI Powered Disaster Management System",
                textAlign: TextAlign.center,
<<<<<<< HEAD
                style: TextStyle(fontSize: 18, color: Colors.white70),
=======
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: 220,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
<<<<<<< HEAD
                        builder: (context) => const DashboardPage(),
=======
                        builder: (context) => const LoginPage(),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
                      ),
                    );
                  },
                  child: const Text(
                    "Get Started",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
<<<<<<< HEAD
=======

              const SizedBox(height: 14),

              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminLoginPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Admin access'),
              ),
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
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
