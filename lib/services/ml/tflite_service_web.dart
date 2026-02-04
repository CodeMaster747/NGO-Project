import '../../utils/constants.dart';

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  bool get isWasteModelLoaded => false;
  bool get isSoilModelLoaded => false;

  Future<bool> loadWasteModel() async => false;
  Future<bool> loadSoilModel() async => false;
  Future<void> unloadWasteModel() async {}
  Future<void> unloadSoilModel() async {}

  Future<List<double>> runWasteInference(
    List<List<List<List<double>>>> input, {
    List<double>? textureInput,
  }) async {
    return List<double>.filled(AppConstants.wasteCategories.length, 0.0);
  }

  Future<List<double>> runSoilInference(
    List<List<List<List<double>>>> input, {
    List<double>? textureInput,
  }) async {
    return List<double>.filled(AppConstants.soilTypes.length, 0.0);
  }
}

