import 'dart:math';
import '../models/user_progress.dart';
import '../utils/constants.dart';

/// Service managing gamification logic: points, levels, badges
/// Handles awarding points, checking badge requirements, and level progression
class GamificationService {
  // Singleton pattern
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  /// Award points for waste scan and check for new badges
  List<String> awardWasteScanPoints(UserProgress progress, String wasteType) {
    List<String> newBadges = [];
    
    // Add points
    progress.addPoints(AppConstants.pointsPerWasteScan);
    progress.recordWasteScan(wasteType);
    
    // Check for badges
    newBadges.addAll(_checkBadges(progress));
    
    return newBadges;
  }

  /// Award points for plant recommendation and check for new badges
  List<String> awardPlantRecommendationPoints(UserProgress progress) {
    List<String> newBadges = [];
    
    // Add points
    progress.addPoints(AppConstants.pointsPerPlantRecommendation);
    progress.recordPlantScan();
    
    // Check for badges
    newBadges.addAll(_checkBadges(progress));
    
    return newBadges;
  }

  /// Check if user has earned any new badges
  List<String> _checkBadges(UserProgress progress) {
    List<String> newBadges = [];
    
    // Eco Starter - First waste scan
    if (progress.totalWasteScans >= 1 && 
        !progress.badgesEarned.contains('eco_starter')) {
      progress.addBadge('eco_starter');
      newBadges.add('eco_starter');
    }
    
    // Green Hero - 10 waste scans
    if (progress.totalWasteScans >= 10 && 
        !progress.badgesEarned.contains('green_hero')) {
      progress.addBadge('green_hero');
      newBadges.add('green_hero');
    }
    
    // Plant Master - 5 plant recommendations
    if (progress.totalPlantScans >= 5 && 
        !progress.badgesEarned.contains('plant_master')) {
      progress.addBadge('plant_master');
      newBadges.add('plant_master');
    }
    
    // Recycling Champion - 20 recyclable items
    if ((progress.wasteTypeCount[AppConstants.wasteRecyclable] ?? 0) >= 20 && 
        !progress.badgesEarned.contains('recycling_champion')) {
      progress.addBadge('recycling_champion');
      newBadges.add('recycling_champion');
    }
    
    // Eco Warrior - Level 5
    if (progress.currentLevel >= 5 && 
        !progress.badgesEarned.contains('eco_warrior')) {
      progress.addBadge('eco_warrior');
      newBadges.add('eco_warrior');
    }
    
    // Earth Guardian - Level 10
    if (progress.currentLevel >= 10 && 
        !progress.badgesEarned.contains('earth_guardian')) {
      progress.addBadge('earth_guardian');
      newBadges.add('earth_guardian');
    }
    
    return newBadges;
  }

  /// Get a random environmental tip for a waste category
  String getRandomTip(String wasteCategory) {
    final tips = AppConstants.environmentalTips[wasteCategory] ?? [];
    if (tips.isEmpty) return 'Keep up the great work protecting our planet!';
    
    final random = Random();
    return tips[random.nextInt(tips.length)];
  }

  /// Get level name based on level number
  String getLevelName(int level) {
    if (level == 1) return 'Eco Beginner';
    if (level <= 3) return 'Green Learner';
    if (level <= 5) return 'Eco Warrior';
    if (level <= 8) return 'Earth Hero';
    if (level <= 10) return 'Planet Guardian';
    return 'Eco Master';
  }

  /// Get motivational message based on progress
  String getMotivationalMessage(UserProgress progress) {
    if (progress.totalScans == 0) {
      return 'Start your eco journey today! 🌱';
    } else if (progress.totalScans < 5) {
      return 'Great start! Keep going! 🌟';
    } else if (progress.totalScans < 10) {
      return 'You\'re doing amazing! 🎉';
    } else if (progress.totalScans < 20) {
      return 'Wow! You\'re an eco champion! 🏆';
    } else {
      return 'Incredible! You\'re saving the planet! 🌍';
    }
  }
}
