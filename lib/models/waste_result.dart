/// Model representing waste classification results
/// Contains the predicted category, confidence, disposal instructions, and points
class WasteResult {
  final String category; // 'Wet', 'Dry', or 'Recyclable'
  final double confidence; // 0.0 to 1.0
  final String disposalInstructions;
  final String environmentalTip;
  final int pointsAwarded;
  final DateTime timestamp;

  WasteResult({
    required this.category,
    required this.confidence,
    required this.disposalInstructions,
    required this.environmentalTip,
    required this.pointsAwarded,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'confidence': confidence,
      'disposalInstructions': disposalInstructions,
      'environmentalTip': environmentalTip,
      'pointsAwarded': pointsAwarded,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory WasteResult.fromJson(Map<String, dynamic> json) {
    return WasteResult(
      category: json['category'],
      confidence: json['confidence'],
      disposalInstructions: json['disposalInstructions'],
      environmentalTip: json['environmentalTip'],
      pointsAwarded: json['pointsAwarded'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
