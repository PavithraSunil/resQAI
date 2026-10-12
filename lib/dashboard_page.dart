import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:resqai/login_page.dart';
import 'safety_tips_page.dart';
import 'report_incidents_page.dart';
import 'sos_emergency_page.dart';
import 'screens/flood_prediction_screen.dart';
import 'services/flood_api.dart';
import 'services/live_data_api.dart';

class DashboardPage extends StatefulWidget {
  final String userName;

  const DashboardPage({super.key, this.userName = 'User'});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loadingRisk = true;
  String? _riskError;
  Position? _position;
  Map<String, dynamic>? _inputs;
  Map<String, dynamic>? _prediction;

  @override
  void initState() {
    super.initState();
    _loadRisk();
  }

  // GPS -> live weather inputs -> flood model prediction.
  Future<void> _loadRisk() async {
    setState(() {
      _loadingRisk = true;
      _riskError = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Please turn on location services.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final inputs = await LiveDataApi.fetchInputs(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Send only the values that are available.
      final cleaned = <String, dynamic>{
        for (final e in inputs.entries)
          if (e.value != null) e.key: e.value,
      };

      final prediction = await FloodApi.predict(cleaned);

      if (!mounted) return;
      setState(() {
        _position = position;
        _inputs = inputs;
        _prediction = prediction;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _riskError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingRisk = false);
    }
  }

  // ---------------- values derived from the live prediction ----------------
  String get _level {
    final p = _prediction;
    if (p == null) return 'unknown';
    final level = p['risk_level']?.toString();
    if (level != null && level.isNotEmpty) return level;
    return p['flood_prediction'] == 1 ? 'elevated' : 'low';
  }

  MaterialColor get _levelColor {
    switch (_level) {
      case 'high':
        return Colors.red;
      case 'elevated':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get _levelLabel {
    switch (_level) {
      case 'high':
        return 'HIGH RISK';
      case 'elevated':
        return 'ELEVATED RISK';
      case 'low':
        return 'LOW RISK';
      default:
        return 'UNKNOWN';
    }
  }

  String get _levelMessage {
    switch (_level) {
      case 'high':
      case 'elevated':
        return 'Model predicts flood conditions in your area';
      case 'low':
        return 'No flood conditions predicted by the model';
      default:
        return 'No prediction available';
    }
  }

  double? get _probability {
    final v = _prediction?['flood_probability'];
    return v == null ? null : double.tryParse(v.toString());
  }

  double? _input(String key) {
    final v = _inputs?[key];
    return v == null ? null : double.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final probability = _probability;
    final statusColor = (_loadingRisk || _riskError != null)
        ? Colors.grey
        : _levelColor;

    final String statusLabel;
    final String statusMessage;
    if (_loadingRisk) {
      statusLabel = 'CHECKING...';
      statusMessage = 'Fetching live weather for your location';
    } else if (_riskError != null) {
      statusLabel = 'UNAVAILABLE';
      statusMessage = 'Could not get the live risk. Tap refresh to retry.';
    } else {
      statusLabel = _levelLabel;
      statusMessage = _levelMessage;
    }

    final rain24 = _input('rainfall_24h_mm');
    final rain3d = _input('rainfall_3d_mm');

    return Scaffold(
      // ---------------- DRAWER ----------------
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'ResQAI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'User Dashboard',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Personal Details'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('My Location'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                // 1. (Optional) If using FirebaseAuth:
                // await FirebaseAuth.instance.signOut();

                // 2. (Optional) Clear saved tokens / SharedPreferences / local storage:
                // final prefs = await SharedPreferences.getInstance();
                // await prefs.clear();

                if (!context.mounted) return;

                // 3. Clear the navigation history and send user to Login screen:
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ), // Replace LoginPage with your login widget
                  (Route<dynamic> route) =>
                      false, // Removes all prior screens from stack
                );
              },
            ),
          ],
        ),
      ),

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        title: const Text(
          'ResQAI Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh live risk',
            icon: const Icon(Icons.refresh),
            onPressed: _loadingRisk ? null : _loadRisk,
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              'Welcome, ${widget.userName}',
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            const Text(
              'Stay Safe. Stay Alert.',
              style: TextStyle(fontSize: 17, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // ---------------- SAFETY STATUS (live) ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: statusColor.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                    child: _loadingRisk
                        ? const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.shield,
                            color: Colors.white,
                            size: 30,
                          ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Safety Status',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          statusMessage,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- LIVE ALERT (live rainfall) ----------------
            const Text(
              'Live Alerts',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 35,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weather Alert',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),

                        const SizedBox(height: 5),

                        if (_loadingRisk)
                          const Text(
                            'Loading rainfall for your location...',
                            style: TextStyle(fontSize: 14),
                          )
                        else if (_riskError != null)
                          Text(
                            'Live data unavailable: $_riskError',
                            style: const TextStyle(fontSize: 14),
                          )
                        else if (rain24 != null)
                          Text(
                            (rain24 >= 64.5
                                    ? 'Heavy rainfall in the last 24 hours: '
                                    : 'Rainfall in the last 24 hours: ') +
                                '${rain24.toStringAsFixed(1)} mm'
                                    '${rain3d != null ? ' (${rain3d.toStringAsFixed(1)} mm in 3 days)' : ''}.',
                            style: const TextStyle(fontSize: 14),
                          )
                        else
                          const Text(
                            'No rainfall data available.',
                            style: TextStyle(fontSize: 14),
                          ),

                        const SizedBox(height: 5),

                        const Text(
                          'Source: Open-Meteo, for your current location',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- LOCATION (live) ----------------
            const Text(
              'My Location',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 45),

                  const SizedBox(height: 8),

                  const Text(
                    'Current Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _position == null
                        ? 'Location not available yet'
                        : 'Lat ${_position!.latitude.toStringAsFixed(4)}, '
                              'Lon ${_position!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- DISASTER PREDICTION ----------------
            const Text(
              'Disaster Prediction',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: predictionCard(
                    icon: Icons.water,
                    title: 'Flood Risk',
                    value: _loadingRisk
                        ? '...'
                        : (probability == null
                              ? 'N/A'
                              : '${(probability * 100).toStringAsFixed(1)}%'),
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: predictionCard(
                    icon: Icons.terrain,
                    title: 'Landslide',
                    value: 'Coming soon',
                    color: Colors.brown,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Button to open the trained flood prediction model
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.water),
                label: const Text('Predict Flood Risk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FloodPredictionScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Experimental model trained on synthetic data. '
              'Not an official flood warning.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 20),
            // ---------------- MAIN ACTIONS ----------------
            const Text(
              'Emergency Actions',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: actionCard(
                    icon: Icons.sos,
                    title: 'SOS Emergency',
                    color: Colors.red,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('SOS Emergency'),
                            content: const Text(
                              'Are you sure you want to send an emergency alert?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SosScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('SEND SOS'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: actionCard(
                    icon: Icons.report,
                    title: 'Report Incident',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportIncidentPage(),
                        ),
                      );
                      // Navigate to Report Incident page
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ---------------- OTHER SERVICES ----------------
            const Text(
              'Safety & Emergency Services',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: actionCard(
                    icon: Icons.health_and_safety,
                    title: 'Safety Tips',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SafetyTipsPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: actionCard(
                    icon: Icons.local_hospital,
                    title: 'Emergency Services',
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to Emergency Services
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // ---------------- PREDICTION CARD ----------------
  Widget predictionCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 35),

            const SizedBox(height: 8),

            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 5),

            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ACTION CARD ----------------
  Widget actionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, size: 42, color: color),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
