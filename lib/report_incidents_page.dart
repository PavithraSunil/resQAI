import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'services/api_services.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController(
    text: 'Detecting location...',
  );
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedIncidentType = "Flood";
  String _selectedSeverity = "Moderate";
  bool _isSubmitting = false;
  bool _detectingLocation = false;

  Position? _position; // GPS fix that is saved with the report
  static const int _maxPhotos = 4;
  final List<Uint8List> _photos = []; // optional camera photos (up to 4)

  final List<Map<String, dynamic>> _incidentTypes = [
    {"name": "Flood", "icon": Icons.waves},
    {"name": "Landslide", "icon": Icons.landscape},
    {"name": "Road Block", "icon": Icons.warning_rounded},
    {"name": "Medical", "icon": Icons.medical_services_rounded},
  ];

  final List<String> _severityLevels = ["Low", "Moderate", "Critical"];

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Color _getSeverityColor(String level) {
    switch (level) {
      case "Low":
        return Colors.green;
      case "Moderate":
        return Colors.orange;
      case "Critical":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showMessage(String text, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ---------------- GPS ----------------
  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);

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

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _position = pos;
        _locationController.text =
            '${pos.latitude.toStringAsFixed(5)}, '
            '${pos.longitude.toStringAsFixed(5)} (Auto-detected)';
      });
    } catch (e) {
      if (mounted && _position == null) {
        _locationController.text = '';
      }
      _showMessage('Could not get your location: $e');
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  // ---------------- PHOTOS (camera only, one at a time, up to 4) ----------------
  Future<void> _takePhoto() async {
    if (_photos.length >= _maxPhotos) {
      _showMessage(
        'You can attach up to $_maxPhotos photos. Remove one to take another.',
        color: Colors.orange,
      );
      return;
    }

    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (shot == null) return; // user closed the camera

      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      setState(() => _photos.add(bytes));
    } catch (e) {
      _showMessage('Could not open the camera: $e');
    }
  }

  Widget _photoTile(int index) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(_photos[index], fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: _isSubmitting
                  ? null
                  : () => setState(() => _photos.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPhotoTile() {
    return InkWell(
      onTap: _isSubmitting ? null : _takePhoto,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 28, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Take photo',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Upload one photo and return its URL, or null if it failed.
  // To use your own backend instead of Firebase Storage, replace the body
  // of this function only.
  Future<String?> _uploadPhoto(String uid, Uint8List bytes, int index) async {
    try {
      final ref = FirebaseStorage.instance.ref(
        'incident_photos/$uid/'
        '${DateTime.now().millisecondsSinceEpoch}_$index.jpg',
      );
      await ref
          .putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
          .timeout(const Duration(seconds: 30));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // ---------------- SUBMIT ----------------
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    var firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      try {
        firebaseUser = (await FirebaseAuth.instance.signInAnonymously()).user;
      } catch (_) {}
    }
    if (firebaseUser == null) {
      _showMessage('Please log in to submit a report.');
      return;
    }
    final user = firebaseUser;

    final pos = _position;
    if (pos == null) {
      _showMessage(
        'Your location has not been detected yet. '
        'Tap the location button and try again.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    var failedPhotos = 0;

    try {
      // 1. Upload the optional photos (in parallel). If some fail, the report
      //    is still sent without them.
      final results = await Future.wait([
        for (var i = 0; i < _photos.length; i++)
          _uploadPhoto(user.uid, _photos[i], i),
      ]);
      final photoUrls = results.whereType<String>().toList();
      failedPhotos = _photos.length - photoUrls.length;

      final firebaseIdToken = await user.getIdToken();
      if (firebaseIdToken == null) {
        throw StateError('Could not get a Firebase authentication token.');
      }

      final response = await ApiService.submitIncidentReport(
        firebaseIdToken: firebaseIdToken,
        type: _selectedIncidentType,
        severity: _selectedSeverity,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyM: pos.accuracy,
        locationText: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        photoUrls: photoUrls,
      );
      if (response.statusCode != 201) {
        final responseBody = jsonDecode(response.body);
        final message = responseBody is Map<String, dynamic>
            ? responseBody['message'] as String?
            : null;
        throw StateError(
          message ?? 'Server returned HTTP ${response.statusCode}.',
        );
      }

      if (!mounted) return;

      if (failedPhotos > 0) {
        _showMessage(
          'Report submitted, but $failedPhotos of ${_photos.length} '
          'photos could not be uploaded.',
          color: Colors.orange,
        );
      } else {
        _showMessage(
          'Incident report submitted successfully.',
          color: Colors.green,
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showMessage('Could not submit the report: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Incident"),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Incident Type Picker
              const Text(
                "Incident Type",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _incidentTypes.map((type) {
                  final isSelected = _selectedIncidentType == type["name"];
                  return ChoiceChip(
                    avatar: Icon(
                      type["icon"],
                      size: 18,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    label: Text(type["name"]),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE53935),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedIncidentType = type["name"]);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 2. Severity Level Selector
              const Text(
                "Severity Level",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: _severityLevels.map((level) {
                  final isSelected = _selectedSeverity == level;
                  final color = _getSeverityColor(level);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected
                              ? color.withValues(alpha: 0.15)
                              : null,
                          side: BorderSide(
                            color: isSelected ? color : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () =>
                            setState(() => _selectedSeverity = level),
                        child: Text(
                          level,
                          style: TextStyle(
                            color: isSelected ? color : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 3. Location Input
              const Text(
                "Location",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: Color(0xFFE53935),
                  ),
                  suffixIcon: _detectingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Use my current location',
                          icon: const Icon(Icons.my_location),
                          onPressed: _detectLocation,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  helperText:
                      'GPS position is saved with the report. You can add a '
                      'landmark to this text.',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Location is required"
                    : null,
              ),

              const SizedBox(height: 24),

              // 4. Photos (up to 4)
              Text(
                "Take Photos / Proof (Optional, ${_photos.length}/$_maxPhotos)",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < _photos.length; i++) _photoTile(i),
                  if (_photos.length < _maxPhotos) _addPhotoTile(),
                ],
              ),

              const SizedBox(height: 24),

              // 5. Description Field
              const Text(
                "Description",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      "Provide details (e.g., number of trapped people, depth of water, blocked landmark)...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value == null || value.trim().length < 5
                    ? "Please enter at least a short description"
                    : null,
              ),

              const SizedBox(height: 32),

              // 6. Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SUBMIT REPORT",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'In a life-threatening emergency, call 112 first.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
