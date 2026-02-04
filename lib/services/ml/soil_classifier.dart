import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/soil_result.dart';
import '../../utils/constants.dart';
import 'tflite_service.dart';
import 'image_preprocessor.dart';
import 'texture_feature_extractor.dart';
import 'remote_inference_service.dart';

/// Service for classifying soil using MobileNetV2 CNN model
/// Handles image preprocessing, inference, and result interpretation
class SoilClassifier {
  // Singleton pattern
  static final SoilClassifier _instance = SoilClassifier._internal();
  factory SoilClassifier() => _instance;
  SoilClassifier._internal();

  final TFLiteService _tfliteService = TFLiteService();
  final ImagePreprocessor _preprocessor = ImagePreprocessor();
  final TextureFeatureExtractor _textureExtractor = TextureFeatureExtractor();
  final RemoteInferenceService _remoteInference = RemoteInferenceService();
  List<String>? _modelLabels;

  /// Classify soil from image bytes with optional location data
  /// Returns SoilResult with soil type and confidence
  Future<SoilResult> classifySoil(
    Uint8List imageBytes, {
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    if (kIsWeb) {
      final remote = await _remoteInference.predictSoil(imageBytes);
      return SoilResult(
        soilType: remote.label.isNotEmpty ? remote.label : 'Unknown',
        confidence: remote.confidence,
        location: location,
        latitude: latitude,
        longitude: longitude,
      );
    }

    bool modelLoaded = _tfliteService.isSoilModelLoaded;
    if (!modelLoaded) {
      modelLoaded = await _tfliteService.loadSoilModel();
    }

    if (!modelLoaded) {
      throw Exception('Soil model could not be loaded');
    }

    return await _classifyWithModel(
      imageBytes,
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Classify using actual TFLite model
  Future<SoilResult> _classifyWithModel(
    Uint8List imageBytes, {
    String? location,
    double? latitude,
    double? longitude,
  }) async {
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
        await _tfliteService.runSoilInference(input, textureInput: texture);

    // Find category with highest confidence
    int maxIndex = 0;
    double maxConfidence = output[0];
    for (int i = 1; i < output.length; i++) {
      if (output[i] > maxConfidence) {
        maxConfidence = output[i];
        maxIndex = i;
      }
    }

    final soilType = maxIndex < labels.length ? labels[maxIndex] : labels.first;

    return SoilResult(
      soilType: soilType,
      confidence: maxConfidence,
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<SoilResult> _classifyWithPlaceholder(
    Uint8List imageBytes, {
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    final labels = await _loadModelLabels();
    final random = Random();
    final soilType = labels[random.nextInt(labels.length)];

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

  Future<List<String>> _loadModelLabels() async {
    final cached = _modelLabels;
    if (cached != null && cached.isNotEmpty) return cached;

    final jsonString = await rootBundle
        .loadString('assets/models/soil_classifier_classes.json');
    final decoded = json.decode(jsonString);
    if (decoded is! Map) {
      throw Exception('Invalid soil classes JSON');
    }

    final entries = decoded.entries
        .map((e) => MapEntry(int.parse(e.key.toString()), e.value.toString()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    _modelLabels = entries.map((e) => e.value).toList();
    return _modelLabels!;
  }
}
