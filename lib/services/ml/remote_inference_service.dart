import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class RemoteInferenceResult {
  final String label;
  final double confidence;
  final List<double> probabilities;

  RemoteInferenceResult({
    required this.label,
    required this.confidence,
    required this.probabilities,
  });
}

class RemoteInferenceService {
  static final RemoteInferenceService _instance = RemoteInferenceService._internal();
  factory RemoteInferenceService() => _instance;
  RemoteInferenceService._internal();

  Future<RemoteInferenceResult> predictSoil(Uint8List imageBytes) async {
    return _predict('${AppConstants.webInferenceBaseUrl}/predict/soil', imageBytes);
  }

  Future<RemoteInferenceResult> predictWaste(Uint8List imageBytes) async {
    return _predict('${AppConstants.webInferenceBaseUrl}/predict/waste', imageBytes);
  }

  Future<RemoteInferenceResult> _predict(String url, Uint8List imageBytes) async {
    final body = jsonEncode({'image_base64': base64Encode(imageBytes)});
    final response = await http
        .post(Uri.parse(url), headers: {'content-type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Inference server error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Invalid inference response');
    }

    final label = (decoded['label'] ?? '').toString();
    final confidence = (decoded['confidence'] is num) ? (decoded['confidence'] as num).toDouble() : 0.0;
    final probsRaw = decoded['probabilities'];
    final probabilities = (probsRaw is List)
        ? probsRaw.map((e) => (e is num) ? e.toDouble() : 0.0).toList()
        : <double>[];

    return RemoteInferenceResult(
      label: label,
      confidence: confidence,
      probabilities: probabilities,
    );
  }
}

