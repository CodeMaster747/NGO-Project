import 'dart:math';
import 'dart:typed_data';
import '../../models/waste_result.dart';
import '../../utils/constants.dart';
import '../gamification_service.dart';
import 'tflite_service.dart';
import 'image_preprocessor.dart';

/// Service for classifying waste using MobileNetV2 CNN model
/// Handles image preprocessing, inference, and result interpretation
class WasteClassifier {
  // Singleton pattern
  static final WasteClassifier _instance = WasteClassifier._internal();
  factory WasteClassifier() => _instance;
  WasteClassifier._internal();

  final TFLiteService _tfliteService = TFLiteService();
  final ImagePreprocessor _preprocessor = ImagePreprocessor();
  final GamificationService _gamification = GamificationService();

  /// Classify waste from image bytes
  /// Returns WasteResult with category, confidence, and instructions
  Future<WasteResult> classifyWaste(Uint8List imageBytes) async {
    try {
      // Load model if not already loaded
      bool modelLoaded = _tfliteService.isWasteModelLoaded;
      if (!modelLoaded) {
        modelLoaded = await _tfliteService.loadWasteModel();
      }

      // If model exists, use it for inference
      if (modelLoaded) {
        return await _classifyWithModel(imageBytes);
      } else {
        // Fallback to placeholder logic if model doesn't exist
        return _classifyWithPlaceholder(imageBytes);
      }
    } catch (e) {
      print('Error classifying waste: $e');
      // Return placeholder result on error
      return _classifyWithPlaceholder(imageBytes);
    }
  }

  /// Classify using actual TFLite model
  Future<WasteResult> _classifyWithModel(Uint8List imageBytes) async {
    // Preprocess image
    final input = await _preprocessor.preprocessImage(
      imageBytes,
      AppConstants.modelInputSize,
    );

    // Run inference
    final output = await _tfliteService.runWasteInference(input);

    // Find category with highest confidence
    int maxIndex = 0;
    double maxConfidence = output[0];
    for (int i = 1; i < output.length; i++) {
      if (output[i] > maxConfidence) {
        maxConfidence = output[i];
        maxIndex = i;
      }
    }

    // Map index to category
    String category = AppConstants.wasteCategories[maxIndex];

    // Get disposal instructions and tip
    String instructions = AppConstants.disposalInstructions[category] ?? 
        'Please dispose of this waste properly.';
    String tip = _gamification.getRandomTip(category);

    return WasteResult(
      category: category,
      confidence: maxConfidence,
      disposalInstructions: instructions,
      environmentalTip: tip,
      pointsAwarded: AppConstants.pointsPerWasteScan,
    );
  }

  /// Placeholder classification logic when model is not available
  /// Uses random classification for demonstration purposes
  WasteResult _classifyWithPlaceholder(Uint8List imageBytes) {
    print('Using placeholder waste classification');
    
    // Generate random category for demonstration
    final random = Random();
    final categories = AppConstants.wasteCategories;
    final category = categories[random.nextInt(categories.length)];
    
    // Random confidence between 0.7 and 0.95
    final confidence = 0.7 + (random.nextDouble() * 0.25);

    // Get disposal instructions and tip
    String instructions = AppConstants.disposalInstructions[category] ?? 
        'Please dispose of this waste properly.';
    String tip = _gamification.getRandomTip(category);

    return WasteResult(
      category: category,
      confidence: confidence,
      disposalInstructions: instructions,
      environmentalTip: tip,
      pointsAwarded: AppConstants.pointsPerWasteScan,
    );
  }
}
