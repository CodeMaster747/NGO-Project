import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/waste_result.dart';
import '../../utils/constants.dart';
import '../gamification_service.dart';
import 'tflite_service.dart';
import 'image_preprocessor.dart';
import 'texture_feature_extractor.dart';
import 'remote_inference_service.dart';

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
  final TextureFeatureExtractor _textureExtractor = TextureFeatureExtractor();
  final RemoteInferenceService _remoteInference = RemoteInferenceService();
  List<String>? _modelLabels;

  /// Classify waste from image bytes
  /// Returns WasteResult with category, confidence, and instructions
  Future<WasteResult> classifyWaste(Uint8List imageBytes) async {
    final shouldUseRemote = kIsWeb || AppConstants.preferRemoteInferenceOnMobile;

    if (shouldUseRemote) {
      try {
        final remote = await _remoteInference.predictWaste(imageBytes);
        final category = _mapModelLabelToWasteCategory(remote.label);
        String instructions = AppConstants.disposalInstructions[category] ??
            'Please dispose of this waste properly.';
        String tip = _gamification.getRandomTip(category);
        return WasteResult(
          category: category,
          confidence: remote.confidence,
          disposalInstructions: instructions,
          environmentalTip: tip,
          pointsAwarded: AppConstants.pointsPerWasteScan,
        );
      } catch (_) {
        if (kIsWeb) rethrow;
      }
    }

    bool modelLoaded = _tfliteService.isWasteModelLoaded;
    if (!modelLoaded) {
      modelLoaded = await _tfliteService.loadWasteModel();
    }

    if (!modelLoaded) {
      throw Exception('Waste model could not be loaded');
    }

    return await _classifyWithModel(imageBytes);
  }

  /// Classify using actual TFLite model
  Future<WasteResult> _classifyWithModel(Uint8List imageBytes) async {
    final labels = await _loadModelLabels();

    final input = await _preprocessor.preprocessImage(
      imageBytes,
      AppConstants.modelInputSize,
    );

    final texture = await _textureExtractor.extractFeatures(
      imageBytes,
      AppConstants.modelInputSize,
    );

    final output =
        await _tfliteService.runWasteInference(input, textureInput: texture);

    // Find category with highest confidence
    int maxIndex = 0;
    double maxConfidence = output[0];
    for (int i = 1; i < output.length; i++) {
      if (output[i] > maxConfidence) {
        maxConfidence = output[i];
        maxIndex = i;
      }
    }

    final modelLabel =
        maxIndex < labels.length ? labels[maxIndex] : labels.first;
    final category = _mapModelLabelToWasteCategory(modelLabel);

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

  Future<List<String>> _loadModelLabels() async {
    final cached = _modelLabels;
    if (cached != null && cached.isNotEmpty) return cached;

    final jsonString = await rootBundle
        .loadString('assets/models/waste_classifier_classes.json');
    final decoded = json.decode(jsonString);
    if (decoded is! Map) {
      throw Exception('Invalid waste classes JSON');
    }

    final entries = decoded.entries
        .map((e) => MapEntry(int.parse(e.key.toString()), e.value.toString()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    _modelLabels = entries.map((e) => e.value).toList();
    return _modelLabels!;
  }

  String _mapModelLabelToWasteCategory(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized == 'r' || normalized.contains('recycl')) {
      return AppConstants.wasteRecyclable;
    }
    if (normalized == 'o' ||
        normalized.contains('organic') ||
        normalized.contains('wet')) {
      return AppConstants.wasteWet;
    }
    return AppConstants.wasteDry;
  }
}
