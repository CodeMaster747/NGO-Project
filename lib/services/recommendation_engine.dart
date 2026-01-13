import '../models/plant.dart';
import '../models/soil_result.dart';
import '../utils/constants.dart';

/// Rule-based engine for recommending plants based on soil type and location
/// Combines ML soil classification with GPS location to suggest suitable plants
class RecommendationEngine {
  // Singleton pattern
  static final RecommendationEngine _instance = RecommendationEngine._internal();
  factory RecommendationEngine() => _instance;
  RecommendationEngine._internal();

  // Plant database with soil and region requirements
  static final List<Plant> _plantDatabase = [
    // Plants for Sandy Soil
    Plant(
      name: 'Cactus',
      description: 'Low-maintenance succulent that thrives in dry conditions',
      plantingTips: 'Plant in well-draining soil. Water sparingly. Loves sunlight!',
      suitableSoilTypes: [AppConstants.soilSandy],
      suitableRegions: ['All', 'Dry', 'Tropical'],
    ),
    Plant(
      name: 'Lavender',
      description: 'Fragrant herb with beautiful purple flowers',
      plantingTips: 'Needs full sun and good drainage. Water moderately.',
      suitableSoilTypes: [AppConstants.soilSandy, AppConstants.soilLoamy],
      suitableRegions: ['All', 'Temperate', 'Mediterranean'],
    ),
    Plant(
      name: 'Carrots',
      description: 'Crunchy root vegetable rich in vitamins',
      plantingTips: 'Sow seeds directly. Keep soil moist. Harvest in 60-80 days.',
      suitableSoilTypes: [AppConstants.soilSandy, AppConstants.soilLoamy],
      suitableRegions: ['All', 'Temperate', 'Cool'],
    ),
    
    // Plants for Clay Soil
    Plant(
      name: 'Sunflower',
      description: 'Tall, cheerful flower that follows the sun',
      plantingTips: 'Plant in spring. Needs full sun. Water regularly.',
      suitableSoilTypes: [AppConstants.soilClay, AppConstants.soilLoamy],
      suitableRegions: ['All', 'Temperate', 'Tropical'],
    ),
    Plant(
      name: 'Roses',
      description: 'Classic flowering plant with beautiful blooms',
      plantingTips: 'Amend clay soil with compost. Water deeply. Prune regularly.',
      suitableSoilTypes: [AppConstants.soilClay, AppConstants.soilLoamy],
      suitableRegions: ['All', 'Temperate', 'Mediterranean'],
    ),
    Plant(
      name: 'Broccoli',
      description: 'Nutritious vegetable packed with vitamins',
      plantingTips: 'Plant in cool season. Keep soil moist. Harvest before flowering.',
      suitableSoilTypes: [AppConstants.soilClay, AppConstants.soilLoamy],
      suitableRegions: ['All', 'Cool', 'Temperate'],
    ),
    
    // Plants for Loamy Soil (ideal for most plants)
    Plant(
      name: 'Tomatoes',
      description: 'Popular fruit vegetable, perfect for gardens',
      plantingTips: 'Plant after last frost. Stake plants. Water consistently.',
      suitableSoilTypes: [AppConstants.soilLoamy],
      suitableRegions: ['All', 'Temperate', 'Tropical'],
    ),
    Plant(
      name: 'Marigold',
      description: 'Bright, cheerful flowers that repel pests',
      plantingTips: 'Easy to grow. Loves sun. Deadhead for more blooms.',
      suitableSoilTypes: [AppConstants.soilLoamy, AppConstants.soilSandy],
      suitableRegions: ['All', 'Tropical', 'Temperate'],
    ),
    Plant(
      name: 'Basil',
      description: 'Aromatic herb perfect for cooking',
      plantingTips: 'Needs warm weather and sun. Pinch off flowers. Water regularly.',
      suitableSoilTypes: [AppConstants.soilLoamy],
      suitableRegions: ['All', 'Tropical', 'Temperate'],
    ),
    Plant(
      name: 'Lettuce',
      description: 'Quick-growing leafy green vegetable',
      plantingTips: 'Grows fast in cool weather. Keep soil moist. Harvest outer leaves.',
      suitableSoilTypes: [AppConstants.soilLoamy, AppConstants.soilSilty],
      suitableRegions: ['All', 'Cool', 'Temperate'],
    ),
    
    // Plants for Silty Soil
    Plant(
      name: 'Cucumber',
      description: 'Refreshing vegetable, great for salads',
      plantingTips: 'Needs warm soil. Provide support. Water regularly.',
      suitableSoilTypes: [AppConstants.soilSilty, AppConstants.soilLoamy],
      suitableRegions: ['All', 'Tropical', 'Temperate'],
    ),
    Plant(
      name: 'Mint',
      description: 'Fragrant herb that spreads easily',
      plantingTips: 'Grows in shade or sun. Keep moist. Contains in pots to control spread.',
      suitableSoilTypes: [AppConstants.soilSilty, AppConstants.soilLoamy],
      suitableRegions: ['All', 'Temperate', 'Tropical'],
    ),
    Plant(
      name: 'Spinach',
      description: 'Nutrient-rich leafy green',
      plantingTips: 'Cool season crop. Partial shade okay. Harvest young leaves.',
      suitableSoilTypes: [AppConstants.soilSilty, AppConstants.soilLoamy],
      suitableRegions: ['All', 'Cool', 'Temperate'],
    ),
  ];

  /// Get plant recommendations based on soil type and location
  /// Returns 2-4 suitable plants
  List<Plant> getRecommendations(SoilResult soilResult) {
    List<Plant> recommendations = [];
    
    // Filter plants by soil type
    final suitablePlants = _plantDatabase.where((plant) {
      return plant.suitableSoilTypes.contains(soilResult.soilType);
    }).toList();
    
    // If we have location, further filter by region
    // For now, we'll use simple region matching
    // In a real app, you'd use a geocoding service to determine climate zone
    List<Plant> filteredPlants = suitablePlants;
    
    if (soilResult.location != null && soilResult.location!.isNotEmpty) {
      // Simple region detection based on location keywords
      String region = _detectRegion(soilResult.location!);
      
      filteredPlants = suitablePlants.where((plant) {
        return plant.suitableRegions.contains('All') || 
               plant.suitableRegions.contains(region);
      }).toList();
    }
    
    // If we have plants, return 2-4 random ones
    if (filteredPlants.isNotEmpty) {
      filteredPlants.shuffle();
      recommendations = filteredPlants.take(4).toList();
    } else if (suitablePlants.isNotEmpty) {
      // Fallback to soil-only matching
      suitablePlants.shuffle();
      recommendations = suitablePlants.take(4).toList();
    } else {
      // Fallback to any plants if no match
      _plantDatabase.shuffle();
      recommendations = _plantDatabase.take(3).toList();
    }
    
    return recommendations;
  }

  /// Simple region detection based on location string
  /// In a real app, use proper geocoding and climate zone APIs
  String _detectRegion(String location) {
    String lowerLocation = location.toLowerCase();
    
    if (lowerLocation.contains('india') || 
        lowerLocation.contains('chennai') ||
        lowerLocation.contains('mumbai') ||
        lowerLocation.contains('bangalore')) {
      return 'Tropical';
    } else if (lowerLocation.contains('europe') || 
               lowerLocation.contains('uk') ||
               lowerLocation.contains('germany')) {
      return 'Temperate';
    } else if (lowerLocation.contains('mediterranean') ||
               lowerLocation.contains('spain') ||
               lowerLocation.contains('italy')) {
      return 'Mediterranean';
    } else if (lowerLocation.contains('canada') ||
               lowerLocation.contains('alaska') ||
               lowerLocation.contains('norway')) {
      return 'Cool';
    } else if (lowerLocation.contains('desert') ||
               lowerLocation.contains('arizona') ||
               lowerLocation.contains('sahara')) {
      return 'Dry';
    }
    
    return 'All'; // Default to universal plants
  }

  /// Get all plants suitable for a soil type (for reference)
  List<Plant> getPlantsBySoilType(String soilType) {
    return _plantDatabase.where((plant) {
      return plant.suitableSoilTypes.contains(soilType);
    }).toList();
  }
}
