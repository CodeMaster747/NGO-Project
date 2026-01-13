/// Model representing soil classification results
/// Contains soil type, confidence, and location data
class SoilResult {
  final String soilType; // e.g., 'Sandy', 'Clay', 'Loamy', 'Silty'
  final double confidence; // 0.0 to 1.0
  final String? location; // GPS-based location (city/region)
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  SoilResult({
    required this.soilType,
    required this.confidence,
    this.location,
    this.latitude,
    this.longitude,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'soilType': soilType,
      'confidence': confidence,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory SoilResult.fromJson(Map<String, dynamic> json) {
    return SoilResult(
      soilType: json['soilType'],
      confidence: json['confidence'],
      location: json['location'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
