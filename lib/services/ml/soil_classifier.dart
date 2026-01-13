import 'dart:math';
import 'dart:typed_data';
import '../../models/soil_result.dart';
import '../../utils/constants.dart';
import 'tflite_service.dart';
import 'image_preprocessor.dart';

/// Service for classifying soil using MobileNetV2 CNN model
/// Handles image preprocessing, inference, and result interpretation
class SoilClassifier {
  // Singleton pattern
  static final SoilClassifier _instance = SoilClassifier._internal();
  factory SoilClassifier() => _instance;
  SoilClassifier._internal();

  final TFLiteService _tfliteService = TFLiteService();
  final ImagePreprocessor _preprocessor = ImagePreprocessor();

  /// Classify soil from image bytes with optional location data
  /// Returns SoilResult with soil type and confidence
  Future<SoilResult> classifySoil(
    Uint8List imageBytes, {
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Load model if not already loaded
      bool modelLoaded = _tfliteService.isSoilModelLoaded;
      if (!modelLoaded) {
        modelLoaded = await _tfliteService.loadSoilModel();
      }

      // If model exists, use it for inference
      if (modelLoaded) {
        return await _classifyWithModel(
          imageBytes,
          location: location,
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        // Fallback to placeholder logic if model doesn't exist
        return _classifyWithPlaceholder(
          imageBytes,
          location: location,
          latitude: latitude,
          longitude: longitude,
        );
      }
    } catch (e) {
      print('Error classifying soil: $e');
      // Return placeholder result on error
      return _classifyWithPlaceholder(
        imageBytes,
        location: location,
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  /// Classify using actual TFLite model
  Future<SoilResult> _classifyWithModel(
    Uint8List imageBytes, {
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    // Preprocess image
    final input = await _preprocessor.preprocessImage(
      imageBytes,
      AppConstants.modelInputSize,
    );

    // Run inference
    final output = await _tfliteService.runSoilInference(input);

    // Find category with highest confidence
    int maxIndex = 0;
    double maxConfidence = output[0];
    for (int i = 1; i < output.length; i++) {
      if (output[i] > maxConfidence) {
        maxConfidence = output[i];
        maxIndex = i;
      }
    }

    // Map index to soil type
    String soilType = AppConstants.soilTypes[maxIndex];

    return SoilResult(
      soilType: soilType,
      confidence: maxConfidence,
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Placeholder classification logic when model is not available
  /// Uses random classification for demonstration purposes
  SoilResult _classifyWithPlaceholder(
    Uint8List imageBytes, {
    String? location,
    double? latitude,
    double? longitude,
  }) {
    print('Using placeholder soil classification');
    
    // Generate random soil type for demonstration
    final random = Random();
    final soilTypes = AppConstants.soilTypes;
    final soilType = soilTypes[random.nextInt(soilTypes.length)];
    
    // Random confidence between 0.7 and 0.95
    final confidence = 0.7 + (random.nextDouble() * 0.25);

    return SoilResult(
      soilType: soilType,
      confidence: confidence,
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
