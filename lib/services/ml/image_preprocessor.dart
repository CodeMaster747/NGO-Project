import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Service for preprocessing images before ML inference
/// Handles resizing, normalization, and tensor conversion
class ImagePreprocessor {
  // Singleton pattern
  static final ImagePreprocessor _instance = ImagePreprocessor._internal();
  factory ImagePreprocessor() => _instance;
  ImagePreprocessor._internal();

  /// Preprocess image for MobileNetV2 model
  /// Resizes to 224x224 and normalizes pixel values to 0-1 range
  Future<List<List<List<List<double>>>>> preprocessImage(
    Uint8List imageBytes,
    int inputSize,
  ) async {
    try {
      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to model input size (224x224 for MobileNetV2)
      img.Image resized = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Convert to normalized tensor format [1, 224, 224, 3]
      // MobileNetV2 expects RGB values normalized to 0-1
      List<List<List<List<double>>>> input = List.generate(
        1, // Batch size
        (b) => List.generate(
          inputSize, // Height
          (y) => List.generate(
            inputSize, // Width
            (x) {
              final pixel = resized.getPixel(x, y);
              return [
                pixel.r / 255.0, // Red channel normalized
                pixel.g / 255.0, // Green channel normalized
                pixel.b / 255.0, // Blue channel normalized
              ];
            },
          ),
        ),
      );

      return input;
    } catch (e) {
      print('Error preprocessing image: $e');
      rethrow;
    }
  }

  /// Alternative preprocessing with different normalization
  /// Some models expect values in -1 to 1 range
  Future<List<List<List<List<double>>>>> preprocessImageNormalized(
    Uint8List imageBytes,
    int inputSize,
  ) async {
    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      img.Image resized = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Normalize to -1 to 1 range
      List<List<List<List<double>>>> input = List.generate(
        1,
        (b) => List.generate(
          inputSize,
          (y) => List.generate(
            inputSize,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [
                (pixel.r / 127.5) - 1.0,
                (pixel.g / 127.5) - 1.0,
                (pixel.b / 127.5) - 1.0,
              ];
            },
          ),
        ),
      );

      return input;
    } catch (e) {
      print('Error preprocessing image: $e');
      rethrow;
    }
  }
}
