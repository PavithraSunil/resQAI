import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/flood_api.dart';
import '../services/live_data_api.dart';

class FloodPredictionScreen extends StatefulWidget {
  const FloodPredictionScreen({super.key});

  @override
  State<FloodPredictionScreen> createState() => _FloodPredictionScreenState();
}

class _FloodPredictionScreenState extends State<FloodPredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _fetchingLiveData = false;

  String? _error;
  Map<String, dynamic>? _result;

  final Map<String, TextEditingController> _controllers = {
    'rainfall_24h_mm': TextEditingController(text: '50'),
    'rainfall_3d_mm': TextEditingController(text: '120'),
    'rainfall_7d_mm': TextEditingController(text: '200'),
    'rainfall_14d_mm': TextEditingController(text: '300'),
    'max_rainfall_3day_mm': TextEditingController(text: '150'),
    'soil_moisture_pct': TextEditingController(text: '60'),
    'river_level_m': TextEditingController(text: '3'),
    'river_distance_km': TextEditingController(text: '2'),
    'elevation_m': TextEditingController(text: '20'),
    'slope_deg': TextEditingController(text: '5'),
    'wind_speed_kmph': TextEditingController(text: '10'),
    'temperature_c': TextEditingController(text: '28'),
    'humidity_pct': TextEditingController(text: '80'),
    'rainfall_change_24h_pct': TextEditingController(text: '20'),
    'previous_event_7d': TextEditingController(text: '0'),
    'days_since_previous_event': TextEditingController(text: '30'),
    'latitude': TextEditingController(text: '9.9312'),
    'longitude': TextEditingController(text: '76.2673'),
  };

  final Map<String, String> _labels = {
    'rainfall_24h_mm': 'Rainfall in last 24 hours (mm)',
    'rainfall_3d_mm': 'Rainfall in last 3 days (mm)',
    'rainfall_7d_mm': 'Rainfall in last 7 days (mm)',
    'rainfall_14d_mm': 'Rainfall in last 14 days (mm)',
    'max_rainfall_3day_mm': 'Maximum 3-day rainfall (mm)',
    'soil_moisture_pct': 'Soil moisture (%)',
    'river_level_m': 'River level (m)',
    'river_distance_km': 'Distance from river (km)',
    'elevation_m': 'Elevation (m)',
    'slope_deg': 'Slope (degrees)',
    'wind_speed_kmph': 'Wind speed (km/h)',
    'temperature_c': 'Temperature (°C)',
    'humidity_pct': 'Humidity (%)',
    'rainfall_change_24h_pct': 'Rainfall change (%)',
    'previous_event_7d': 'Flood event in previous 7 days? (0 or 1)',
    'days_since_previous_event': 'Days since previous event',
    'latitude': 'Latitude',
    'longitude': 'Longitude',
  };

  // Get the current GPS position and fetch weather inputs.
  Future<Map<String, dynamic>> fetchLiveWeather() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Please enable location services on your device.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is required. Allow location access '
        'in your device settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final inputs = await LiveDataApi.fetchInputs(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    // Show the GPS position that was actually used in the form fields.
    return {
      ...inputs,
      'latitude': position.latitude.toStringAsFixed(6),
      'longitude': position.longitude.toStringAsFixed(6),
    };
  }

  // Fetch live data and fill the form with available values.
  Future<void> _fetchAndFillLiveWeather() async {
    setState(() {
      _fetchingLiveData = true;
      _error = null;
    });

    try {
      final inputs = await fetchLiveWeather();

      if (!mounted) return;

      for (final entry in inputs.entries) {
        final controller = _controllers[entry.key];
        final value = entry.value;

        if (controller != null && value != null) {
          controller.text = value.toString();
        }
      }

      final missingFields = inputs.entries
          .where((entry) => entry.value == null)
          .map((entry) => _labels[entry.key] ?? entry.key)
          .toList();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missingFields.isEmpty
                ? 'Weather inputs loaded successfully.'
                : 'Available weather loaded. Some values still '
                      'need real data: ${missingFields.join(', ')}.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not fetch live weather: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _fetchingLiveData = false);
      }
    }
  }

  // Send all form values to the flood prediction API.
  Future<void> _predict() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final input = <String, dynamic>{};

      for (final entry in _controllers.entries) {
        final value = double.parse(entry.value.text.trim());

        if (!value.isFinite) {
          throw FormatException(
            'Invalid value for ${_labels[entry.key] ?? entry.key}',
          );
        }

        input[entry.key] = value;
      }

      input['previous_event_7d'] = int.parse(
        _controllers['previous_event_7d']!.text.trim(),
      );

      final result = await FloodApi.predict(input);

      if (!mounted) return;

      setState(() {
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Prediction failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final probabilityValue = _result?['flood_probability'];
    final prediction = _result?['flood_prediction'];

    final probability = probabilityValue == null
        ? null
        : double.tryParse(probabilityValue.toString());

    final isFlood = prediction == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kerala Flood Prediction'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Weather and Location Details',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use your GPS location to retrieve available weather '
            'inputs, or enter values manually.',
          ),
          const SizedBox(height: 16),

          // Fetch Live Weather button.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_fetchingLiveData || _loading)
                  ? null
                  : _fetchAndFillLiveWeather,
              icon: _fetchingLiveData
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _fetchingLiveData
                    ? 'Fetching Live Weather...'
                    : 'Fetch Live Weather Using GPS',
              ),
            ),
          ),

          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              children: _controllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: entry.value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: _labels[entry.key],
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.edit_note),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a value';
                      }

                      final number = double.tryParse(value.trim());

                      if (number == null || !number.isFinite) {
                        return 'Enter a valid number';
                      }

                      if (entry.key == 'previous_event_7d' &&
                          number != 0 &&
                          number != 1) {
                        return 'Enter 0 or 1';
                      }

                      if (entry.key == 'latitude' &&
                          (number < -90 || number > 90)) {
                        return 'Latitude must be between -90 and 90';
                      }

                      if (entry.key == 'longitude' &&
                          (number < -180 || number > 180)) {
                        return 'Longitude must be between -180 and 180';
                      }

                      return null;
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Predict Flood Risk button.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_loading || _fetchingLiveData) ? null : _predict,
              icon: const Icon(Icons.analytics),
              label: Text(_loading ? 'Predicting...' : 'Predict Flood Risk'),
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ],

          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Flood Prediction Result',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          isFlood
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          color: isFlood ? Colors.red : Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isFlood
                                ? 'Model predicts flood conditions'
                                : 'Model does not predict flood conditions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isFlood ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (probability != null)
                      Text(
                        'Model flood probability: '
                        '${(probability * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 8),
                    if (_result!['note'] != null) Text('${_result!['note']}'),
                    const SizedBox(height: 8),
                    const Text(
                      'This is an experimental model result, not '
                      'an official flood warning.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
