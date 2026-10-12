import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  final Battery _battery = Battery();

  bool _isTriggered = false;
  bool _isSending = false;
  String _statusMessage = "Press and hold for 3 seconds";

  // Replace with your backend endpoint and fallback emergency contact
  final String _backendUrl = "https://your-api-endpoint.com/api/sos";
  final String _emergencyNumber = "112";

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onHoldCompleted();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    if (_isTriggered || _isSending) return;
    HapticFeedback.mediumImpact();
    _progressController.forward();
    setState(() {
      _statusMessage = "Hold to activate SOS...";
    });
  }

  void _onHoldEnd() {
    if (_isTriggered || _isSending) return;
    if (_progressController.status != AnimationStatus.completed) {
      _progressController.reset();
      setState(() {
        _statusMessage = "Press and hold for 3 seconds";
      });
    }
  }

  Future<void> _onHoldCompleted() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSending = true;
      _statusMessage = "Acquiring GPS and dispatching alert...";
    });

    try {
      // 1. Fetch High Accuracy GPS Position
      Position position = await _determinePosition();

      // 2. Fetch Battery Status
      int batteryLevel = await _battery.batteryLevel;

      // 3. Dispatch to Server with Offline Fallback
      await _dispatchEmergencyAlert(
        lat: position.latitude,
        lng: position.longitude,
        battery: batteryLevel,
      );
    } catch (e) {
      setState(() {
        _statusMessage = "GPS Error: $e. Reverting to emergency call/SMS.";
      });
      _fallbackToNativeSms(lat: 0.0, lng: 0.0);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
  }

  Future<void> _dispatchEmergencyAlert({
    required double lat,
    required double lng,
    required int battery,
  }) async {
    final payload = {
      "userId": "user_1029",
      "userName": "Kerala Resident",
      "latitude": lat,
      "longitude": lng,
      "batteryLevel": battery,
      "timestamp": DateTime.now().toIso8601String(),
    };

    try {
      // Try HTTP POST with a short 6-second timeout for rapid offline fallback
      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isTriggered = true;
          _isSending = false;
          _statusMessage = "SOS ACTIVE: Rescue teams alerted via network!";
        });
      } else {
        throw Exception('Server rejected request');
      }
    } catch (_) {
      // Network failure / No internet -> Fallback to Native SMS immediately
      await _fallbackToNativeSms(lat: lat, lng: lng);
      setState(() {
        _isTriggered = true;
        _isSending = false;
        _statusMessage = "Network failed. Opened SMS beacome fallback.";
      });
    }
  }

  Future<void> _fallbackToNativeSms({
    required double lat,
    required double lng,
  }) async {
    final String body = (lat != 0.0 && lng != 0.0)
        ? "EMERGENCY FLOOD RESCUE NEEDED! My location: https://maps.google.com/?q=$lat,$lng"
        : "EMERGENCY FLOOD RESCUE NEEDED! Please send help immediately.";

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: _emergencyNumber,
      queryParameters: <String, String>{'body': body},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Emergency Dispatch"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isTriggered ? "DISTRESS BEACOME SENT" : "HOLD FOR 3 SECONDS",
              style: TextStyle(
                color: _isTriggered ? Colors.redAccent : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTapDown: (_) => _onHoldStart(),
                onTapUp: (_) => _onHoldEnd(),
                onTapCancel: () => _onHoldEnd(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular Progress Indicator for the 3-second hold
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: _progressController.value,
                            strokeWidth: 8,
                            color: Colors.redAccent,
                            backgroundColor: Colors.white12,
                          );
                        },
                      ),
                    ),
                    // Inner SOS Button Circle
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isTriggered
                            ? Colors.red.shade900
                            : Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isTriggered
                                ? Icons.warning_amber_rounded
                                : Icons.sensors,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSending
                                ? "SENDING..."
                                : _isTriggered
                                ? "ACTIVE"
                                : "SOS",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
