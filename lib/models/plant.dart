/// Model representing a plant recommendation
/// Contains plant details, growing requirements, and tips
class Plant {
  final String name;
  final String description;
  final String plantingTips;
  final List<String> suitableSoilTypes;
  final List<String> suitableRegions;
  final String? imageAsset; // Optional image path

  Plant({
    required this.name,
    required this.description,
    required this.plantingTips,
    required this.suitableSoilTypes,
    required this.suitableRegions,
    this.imageAsset,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'plantingTips': plantingTips,
      'suitableSoilTypes': suitableSoilTypes,
      'suitableRegions': suitableRegions,
      'imageAsset': imageAsset,
    };
  }

  /// Create from JSON
  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      name: json['name'],
      description: json['description'],
      plantingTips: json['plantingTips'],
      suitableSoilTypes: List<String>.from(json['suitableSoilTypes']),
      suitableRegions: List<String>.from(json['suitableRegions']),
      imageAsset: json['imageAsset'],
    );
  }
}
