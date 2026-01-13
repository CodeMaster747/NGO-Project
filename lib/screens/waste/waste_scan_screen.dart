import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/theme.dart';
import '../../widgets/eco_button.dart';
import '../../services/ml/waste_classifier.dart';
import '../../models/waste_result.dart';
import 'waste_result_screen.dart';

/// Screen for capturing/selecting waste images
class WasteScanScreen extends StatefulWidget {
  const WasteScanScreen({super.key});

  @override
  State<WasteScanScreen> createState() => _WasteScanScreenState();
}

class _WasteScanScreenState extends State<WasteScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final WasteClassifier _classifier = WasteClassifier();
  
  XFile? _imageFile;
  bool _isAnalyzing = false;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  Future<void> _analyzeWaste() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Read image bytes
      final bytes = await _imageFile!.readAsBytes();

      // Classify waste
      final result = await _classifier.classifyWaste(bytes);

      if (mounted) {
        // Navigate to result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WasteResultScreen(
              result: result,
              imageFile: _imageFile!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing waste: $e')),
        );
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
      appBar: AppBar(
        title: const Text('Scan Waste'),
      ),
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
                        Icons.info_outline,
                        size: 40,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Take a clear photo of your waste item',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Our AI will help you sort it correctly!',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

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
                        Icons.camera_alt,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No image selected',
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
                      onPressed: () => _captureImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: EcoButton(
                      text: 'Gallery',
                      icon: Icons.photo_library,
                      backgroundColor: AppTheme.secondaryGreen,
                      onPressed: () => _captureImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Analyze Button
              if (_imageFile != null)
                EcoButton(
                  text: _isAnalyzing ? 'Analyzing...' : 'Analyze Waste',
                  icon: _isAnalyzing ? null : Icons.search,
                  isLarge: true,
                  backgroundColor: AppTheme.accentOrange,
                  onPressed: _isAnalyzing ? () {} : _analyzeWaste,
                ),

              if (_isAnalyzing)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
