import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/theme.dart';
import '../../widgets/eco_button.dart';
import '../../services/ml/soil_classifier.dart';
import 'plant_recommendation_screen.dart';

/// Screen for capturing soil images and getting GPS location
class SoilCaptureScreen extends StatefulWidget {
  const SoilCaptureScreen({super.key});

  @override
  State<SoilCaptureScreen> createState() => _SoilCaptureScreenState();
}

class _SoilCaptureScreenState extends State<SoilCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final SoilClassifier _classifier = SoilClassifier();

  XFile? _imageFile;
  Position? _position;
  String? _locationName;
  bool _isAnalyzing = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Simple location name (in production, use geocoding service)
      setState(() {
        _locationName =
            'Lat: ${_position!.latitude.toStringAsFixed(2)}, '
            'Lon: ${_position!.longitude.toStringAsFixed(2)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
      setState(() {
        _locationName = 'Location unavailable';
      });
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
      }
    }
  }

  Future<void> _analyzeSoil() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final bytes = await _imageFile!.readAsBytes();

      final result = await _classifier.classifySoil(
        bytes,
        location: _locationName,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantRecommendationScreen(
              soilResult: result,
              imageFile: _imageFile!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error analyzing soil: $e')));
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soil Analysis')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_florist,
                        size: 40,
                        color: AppTheme.secondaryGreen,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Capture your soil sample',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll recommend the best plants for your area!',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Location Info
              Card(
                elevation: 3,
                color: AppTheme.secondaryGreen.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _isFetchingLocation
                            ? Icons.location_searching
                            : Icons.location_on,
                        color: AppTheme.secondaryGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isFetchingLocation
                              ? 'Getting location...'
                              : _locationName ?? 'Location not available',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (!_isFetchingLocation)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _getCurrentLocation,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Image Preview
              if (_imageFile != null)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_imageFile!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.terrain,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No soil image selected',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),

              // Camera and Gallery Buttons
              Row(
                children: [
                  Expanded(
                    child: EcoButton(
                      text: 'Camera',
                      icon: Icons.camera_alt,
                      backgroundColor: AppTheme.secondaryGreen,
                      onPressed: () => _captureImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: EcoButton(
                      text: 'Gallery',
                      icon: Icons.photo_library,
                      backgroundColor: AppTheme.primaryGreen,
                      onPressed: () => _captureImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Analyze Button
              if (_imageFile != null)
                EcoButton(
                  text: _isAnalyzing ? 'Analyzing...' : 'Get Recommendations',
                  icon: _isAnalyzing ? null : Icons.search,
                  isLarge: true,
                  backgroundColor: AppTheme.accentOrange,
                  onPressed: _isAnalyzing ? () {} : _analyzeSoil,
                ),

              if (_isAnalyzing)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
