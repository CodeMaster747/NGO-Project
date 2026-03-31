import 'package:flutter/material.dart';

/// App-wide constants for waste categories, disposal instructions, points, etc.
class AppConstants {
  // App Info
  static const String appName = 'EcoKids';
  static const String appVersion = '1.0.0';
  static const String ngoMission =
      'Empowering communities and children to protect our environment through smart waste management and sustainable planting.';

  // Waste Categories
  static const String wasteWet = 'Wet';
  static const String wasteDry = 'Dry';
  static const String wasteRecyclable = 'Recyclable';

  static const List<String> wasteCategories = [
    wasteWet,
    wasteDry,
    wasteRecyclable,
  ];

  // Disposal Instructions
  static const Map<String, String> disposalInstructions = {
    wasteWet: 'Put in the GREEN bin. This waste will decompose naturally and can be used as compost for plants!',
    wasteDry: 'Put in the BLACK bin. This waste cannot be recycled and will go to landfills.',
    wasteRecyclable: 'Put in the BLUE bin. This can be recycled into new products - you\'re saving resources!',
  };

  // Environmental Tips
  static const Map<String, List<String>> environmentalTips = {
    wasteWet: [
      '🌱 Wet waste makes great compost for gardens!',
      '🍃 Food scraps can feed the soil and help plants grow.',
      '♻️ Composting reduces landfill waste by up to 30%!',
      '🌍 Wet waste breaks down naturally in just a few weeks.',
    ],
    wasteDry: [
      '🗑️ Reduce dry waste by avoiding single-use items.',
      '🎨 Get creative! Some dry waste can be reused for crafts.',
      '📦 Try to buy products with less packaging.',
      '🌟 Every small action to reduce waste helps our planet!',
    ],
    wasteRecyclable: [
      '♻️ Recycling one aluminum can saves enough energy to run a TV for 3 hours!',
      '📰 Recycled paper saves trees and water.',
      '🔄 Plastic bottles can become clothing, bags, and more!',
      '🌈 Clean recyclables work best - rinse before recycling!',
    ],
  };

  // Soil Types
  static const String soilSandy = 'Sandy';
  static const String soilClay = 'Clay';
  static const String soilLoamy = 'Loamy';
  static const String soilSilty = 'Silty';

  static const List<String> soilTypes = [
    soilSandy,
    soilClay,
    soilLoamy,
    soilSilty,
  ];

  // Points System
  static const int pointsPerWasteScan = 10;
  static const int pointsPerPlantRecommendation = 15;
  static const int pointsPerLevel = 100;

  // Badge Definitions
  static const Map<String, Map<String, dynamic>> badges = {
    'eco_starter': {
      'name': 'Eco Starter',
      'description': 'Complete your first waste scan',
      'icon': Icons.eco,
      'requirement': 1, // 1 waste scan
    },
    'green_hero': {
      'name': 'Green Hero',
      'description': 'Scan 10 waste items',
      'icon': Icons.star,
      'requirement': 10,
    },
    'plant_master': {
      'name': 'Plant Master',
      'description': 'Get 5 plant recommendations',
      'icon': Icons.local_florist,
      'requirement': 5,
    },
    'recycling_champion': {
      'name': 'Recycling Champion',
      'description': 'Scan 20 recyclable items',
      'icon': Icons.recycling,
      'requirement': 20,
    },
    'eco_warrior': {
      'name': 'Eco Warrior',
      'description': 'Reach level 5',
      'icon': Icons.military_tech,
      'requirement': 5,
    },
    'earth_guardian': {
      'name': 'Earth Guardian',
      'description': 'Reach level 10',
      'icon': Icons.public,
      'requirement': 10,
    },
  };

  // Learning Tips for Children
  static const List<Map<String, String>> learningTips = [
    {
      'title': '♻️ Why Recycle?',
      'content': 'Recycling turns old things into new things! It saves energy, reduces pollution, and protects animals.',
    },
    {
      'title': '🌱 Composting is Magic',
      'content': 'Food scraps and plant waste can turn into rich soil that helps new plants grow big and strong!',
    },
    {
      'title': '🌳 Plant a Tree',
      'content': 'Trees give us oxygen to breathe, homes for animals, and shade on hot days. One tree can make a big difference!',
    },
    {
      'title': '💧 Save Water',
      'content': 'Turn off the tap while brushing teeth. Every drop counts! Water is precious for all living things.',
    },
    {
      'title': '🎒 Reduce Plastic',
      'content': 'Use reusable bags and bottles. Plastic takes hundreds of years to break down and can hurt ocean animals.',
    },
    {
      'title': '🌍 Be an Earth Hero',
      'content': 'Small actions add up! Pick up litter, save energy, and teach others. You can make the world better!',
    },
  ];

  // Model Configuration
  static const String wasteModelPath = 'assets/models/waste_classifier_model.tflite';
  static const String soilModelPath = 'assets/models/soil_classifier_model.tflite';
  static const int modelInputSize = 224; // MobileNetV2 standard input size
  static const String webInferenceBaseUrl = 'http://10.57.106.156:8000';
  static const bool preferRemoteInferenceOnMobile = true;

  // Colors (defined in theme.dart but referenced here)
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color secondaryGreen = Color(0xFF8BC34A);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color wetWasteColor = Color(0xFF4CAF50);
  static const Color dryWasteColor = Color(0xFF757575);
  static const Color recyclableColor = Color(0xFF2196F3);
}
