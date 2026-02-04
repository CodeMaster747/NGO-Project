import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../utils/constants.dart';

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  Interpreter? _wasteInterpreter;
  Interpreter? _soilInterpreter;

  bool get isWasteModelLoaded => _wasteInterpreter != null;
  bool get isSoilModelLoaded => _soilInterpreter != null;

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Interpreter> _loadInterpreter(String assetPath) async {
    try {
      return await Interpreter.fromAsset(assetPath);
    } catch (_) {
      final normalized = assetPath.startsWith('assets/')
          ? assetPath.substring('assets/'.length)
          : assetPath;
      return await Interpreter.fromAsset(normalized);
    }
  }

  Future<bool> loadWasteModel() async {
    try {
      if (_soilInterpreter != null) {
        await unloadSoilModel();
      }

      final exists = await _assetExists(AppConstants.wasteModelPath);
      if (!exists) {
        _wasteInterpreter = null;
        return false;
      }

      _wasteInterpreter?.close();
      _wasteInterpreter = await _loadInterpreter(AppConstants.wasteModelPath);
      return true;
    } catch (_) {
      _wasteInterpreter = null;
      return false;
    }
  }

  Future<bool> loadSoilModel() async {
    try {
      if (_wasteInterpreter != null) {
        await unloadWasteModel();
      }

      final exists = await _assetExists(AppConstants.soilModelPath);
      if (!exists) {
        _soilInterpreter = null;
        return false;
      }

      _soilInterpreter?.close();
      _soilInterpreter = await _loadInterpreter(AppConstants.soilModelPath);
      return true;
    } catch (_) {
      _soilInterpreter = null;
      return false;
    }
  }

  Future<void> unloadWasteModel() async {
    _wasteInterpreter?.close();
    _wasteInterpreter = null;
  }

  Future<void> unloadSoilModel() async {
    _soilInterpreter?.close();
    _soilInterpreter = null;
  }

  Future<List<double>> runWasteInference(
    List<List<List<List<double>>>> input, {
    List<double>? textureInput,
  }) async {
    final interpreter = _wasteInterpreter;
    if (interpreter == null) {
      throw Exception('Waste model not loaded');
    }

    return _runInference(interpreter, input, textureInput: textureInput);
  }

  Future<List<double>> runSoilInference(
    List<List<List<List<double>>>> input, {
    List<double>? textureInput,
  }) async {
    final interpreter = _soilInterpreter;
    if (interpreter == null) {
      throw Exception('Soil model not loaded');
    }

    return _runInference(interpreter, input, textureInput: textureInput);
  }

  List<double> _zerosTexture(Interpreter interpreter) {
    final tensors = interpreter.getInputTensors();
    if (tensors.length < 2) {
      return const <double>[];
    }

    final shape = tensors[1].shape;
    final featureSize = shape.isNotEmpty ? shape.last : 0;
    return List<double>.filled(featureSize, 0.0);
  }

  List<double> _runInference(
    Interpreter interpreter,
    List<List<List<List<double>>>> imageInput, {
    List<double>? textureInput,
  }) {
    final outputTensor = interpreter.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final outputSize = outputShape.isNotEmpty ? outputShape.last : 0;
    final output = List.generate(1, (_) => List.filled(outputSize, 0.0));

    final inputCount = interpreter.getInputTensors().length;
    if (inputCount == 1) {
      interpreter.run(imageInput, output);
      return List<double>.from(output[0]);
    }

    final features = textureInput ?? _zerosTexture(interpreter);
    final texture = <List<double>>[features];
    interpreter.runForMultipleInputs([imageInput, texture], {0: output});
    return List<double>.from(output[0]);
  }
}
