import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class TextureFeatureExtractor {
  static final TextureFeatureExtractor _instance =
      TextureFeatureExtractor._internal();
  factory TextureFeatureExtractor() => _instance;
  TextureFeatureExtractor._internal();

  static const List<int> _glcmDistances = [1, 2, 3];
  static const List<double> _glcmAngles = [0, pi / 4, pi / 2, 3 * pi / 4];
  static const int _lbpRadius = 3;
  static const int _lbpPoints = 24;

  Future<List<double>> extractFeatures(
    Uint8List imageBytes,
    int inputSize,
  ) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    final grayscale = _toGrayscale(resized, inputSize);

    final glcmFeatures = _extractGlcmFeatures(grayscale, inputSize);
    final lbpFeatures = _extractLbpHistogram(grayscale, inputSize);
    return <double>[...glcmFeatures, ...lbpFeatures];
  }

  List<int> _toGrayscale(img.Image image, int size) {
    final gray = List<int>.filled(size * size, 0);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final p = image.getPixel(x, y);
        final v =
            (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
        gray[y * size + x] = v;
      }
    }
    return gray;
  }

  List<double> _extractGlcmFeatures(List<int> gray, int size) {
    final results = <double>[];

    for (final prop in const [
      _GlcmProp.contrast,
      _GlcmProp.dissimilarity,
      _GlcmProp.homogeneity,
      _GlcmProp.energy,
      _GlcmProp.correlation,
      _GlcmProp.asm,
    ]) {
      for (final distance in _glcmDistances) {
        for (final angle in _glcmAngles) {
          final offset = _glcmOffset(distance, angle);
          final features = _glcmForOffset(gray, size, offset.$1, offset.$2);
          results.add(_selectProp(features, prop));
        }
      }
    }

    return results;
  }

  (int, int) _glcmOffset(int d, double angle) {
    if (angle == 0) return (d, 0);
    if (angle == pi / 4) return (d, -d);
    if (angle == pi / 2) return (0, -d);
    return (-d, -d);
  }

  _GlcmStats _glcmForOffset(List<int> gray, int size, int dx, int dy) {
    final counts = Float64List(256 * 256);
    double total = 0.0;

    for (int y = 0; y < size; y++) {
      final ny = y + dy;
      if (ny < 0 || ny >= size) continue;
      for (int x = 0; x < size; x++) {
        final nx = x + dx;
        if (nx < 0 || nx >= size) continue;
        final i = gray[y * size + x];
        final j = gray[ny * size + nx];
        counts[i * 256 + j] += 1.0;
        counts[j * 256 + i] += 1.0;
        total += 2.0;
      }
    }

    if (total == 0.0) {
      return const _GlcmStats(
        contrast: 0.0,
        dissimilarity: 0.0,
        homogeneity: 0.0,
        asm: 0.0,
        energy: 0.0,
        correlation: 0.0,
      );
    }

    final rowSums = Float64List(256);
    final colSums = Float64List(256);

    double contrast = 0.0;
    double dissimilarity = 0.0;
    double homogeneity = 0.0;
    double asm = 0.0;

    for (int i = 0; i < 256; i++) {
      final base = i * 256;
      for (int j = 0; j < 256; j++) {
        final p = counts[base + j] / total;
        if (p == 0.0) continue;

        rowSums[i] += p;
        colSums[j] += p;

        final diff = i - j;
        final diffAbs = diff.abs().toDouble();
        final diffSq = (diff * diff).toDouble();

        contrast += p * diffSq;
        dissimilarity += p * diffAbs;
        homogeneity += p / (1.0 + diffSq);
        asm += p * p;
      }
    }

    double muI = 0.0;
    double muJ = 0.0;
    for (int i = 0; i < 256; i++) {
      muI += i * rowSums[i];
      muJ += i * colSums[i];
    }

    double sigmaI = 0.0;
    double sigmaJ = 0.0;
    for (int i = 0; i < 256; i++) {
      final di = i - muI;
      final dj = i - muJ;
      sigmaI += di * di * rowSums[i];
      sigmaJ += dj * dj * colSums[i];
    }
    sigmaI = sqrt(sigmaI);
    sigmaJ = sqrt(sigmaJ);

    double correlation = 0.0;
    if (sigmaI != 0.0 && sigmaJ != 0.0) {
      for (int i = 0; i < 256; i++) {
        final base = i * 256;
        final di = i - muI;
        for (int j = 0; j < 256; j++) {
          final p = counts[base + j] / total;
          if (p == 0.0) continue;
          correlation += p * di * (j - muJ);
        }
      }
      correlation /= (sigmaI * sigmaJ);
    }

    final energy = sqrt(asm);

    return _GlcmStats(
      contrast: contrast,
      dissimilarity: dissimilarity,
      homogeneity: homogeneity,
      asm: asm,
      energy: energy,
      correlation: correlation,
    );
  }

  double _selectProp(_GlcmStats stats, _GlcmProp prop) {
    return switch (prop) {
      _GlcmProp.contrast => stats.contrast,
      _GlcmProp.dissimilarity => stats.dissimilarity,
      _GlcmProp.homogeneity => stats.homogeneity,
      _GlcmProp.energy => stats.energy,
      _GlcmProp.correlation => stats.correlation,
      _GlcmProp.asm => stats.asm,
    };
  }

  List<double> _extractLbpHistogram(List<int> gray, int size) {
    final bins = List<double>.filled(_lbpPoints + 2, 0.0);
    final radius = _lbpRadius;
    int count = 0;

    for (int y = radius; y < size - radius; y++) {
      for (int x = radius; x < size - radius; x++) {
        final center = gray[y * size + x].toDouble();
        final bits = List<int>.filled(_lbpPoints, 0);
        for (int p = 0; p < _lbpPoints; p++) {
          final theta = 2.0 * pi * p / _lbpPoints;
          final fx = x + radius * cos(theta);
          final fy = y - radius * sin(theta);
          final v = _bilinear(gray, size, fx, fy);
          bits[p] = v >= center ? 1 : 0;
        }

        final transitions = _countTransitions(bits);
        final code = transitions <= 2 ? bits.reduce((a, b) => a + b) : _lbpPoints + 1;
        bins[code] += 1.0;
        count++;
      }
    }

    if (count == 0) {
      return bins;
    }
    for (int i = 0; i < bins.length; i++) {
      bins[i] /= count;
    }
    return bins;
  }

  double _bilinear(List<int> gray, int size, double x, double y) {
    final x0 = x.floor();
    final y0 = y.floor();
    final x1 = min(x0 + 1, size - 1);
    final y1 = min(y0 + 1, size - 1);

    final dx = x - x0;
    final dy = y - y0;

    final v00 = gray[y0 * size + x0].toDouble();
    final v10 = gray[y0 * size + x1].toDouble();
    final v01 = gray[y1 * size + x0].toDouble();
    final v11 = gray[y1 * size + x1].toDouble();

    final v0 = v00 * (1 - dx) + v10 * dx;
    final v1 = v01 * (1 - dx) + v11 * dx;
    return v0 * (1 - dy) + v1 * dy;
  }

  int _countTransitions(List<int> bits) {
    int transitions = 0;
    for (int i = 0; i < bits.length; i++) {
      final a = bits[i];
      final b = bits[(i + 1) % bits.length];
      if (a != b) transitions++;
    }
    return transitions;
  }
}

enum _GlcmProp {
  contrast,
  dissimilarity,
  homogeneity,
  energy,
  correlation,
  asm,
}

class _GlcmStats {
  final double contrast;
  final double dissimilarity;
  final double homogeneity;
  final double energy;
  final double correlation;
  final double asm;

  const _GlcmStats({
    required this.contrast,
    required this.dissimilarity,
    required this.homogeneity,
    required this.energy,
    required this.correlation,
    required this.asm,
  });
}

