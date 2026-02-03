import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../models/soil_result.dart';
import '../../models/plant.dart';
import '../../services/storage_service.dart';
import '../../services/gamification_service.dart';
import '../../services/recommendation_engine.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/eco_button.dart';

/// Screen showing plant recommendations based on soil analysis
class PlantRecommendationScreen extends StatefulWidget {
  final SoilResult soilResult;
  final XFile imageFile;

  const PlantRecommendationScreen({
    super.key,
    required this.soilResult,
    required this.imageFile,
  });

  @override
  State<PlantRecommendationScreen> createState() =>
      _PlantRecommendationScreenState();
}

class _PlantRecommendationScreenState extends State<PlantRecommendationScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final GamificationService _gamification = GamificationService();
  final RecommendationEngine _recommendationEngine = RecommendationEngine();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  List<Plant> _recommendations = [];
  List<String> _newBadges = [];

  @override
  void initState() {
    super.initState();

    // Setup animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();

    // Get recommendations and award points
    _getRecommendations();
    _awardPoints();
  }

  void _getRecommendations() {
    _recommendations = _recommendationEngine.getRecommendations(
      widget.soilResult,
    );
  }

  Future<void> _awardPoints() async {
    final progress = await _storage.loadUserProgress();
    _newBadges = _gamification.awardPlantRecommendationPoints(progress);
    await _storage.saveUserProgress(progress);

    if (_newBadges.isNotEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _showBadgeDialog();
      });
    }
  }

  void _showBadgeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 New Badge!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _newBadges.map((badge) {
            final badgeInfo = AppConstants.badges[badge];
            return ListTile(
              leading: Icon(
                badgeInfo?['icon'] ?? Icons.star,
                color: AppTheme.accentOrange,
                size: 40,
              ),
              title: Text(badgeInfo?['name'] ?? badge),
              subtitle: Text(badgeInfo?['description'] ?? ''),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Recommendations')),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Soil Image
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: kIsWeb
                        ? Image.network(
                            widget.imageFile.path,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(widget.imageFile.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Soil Type Result
                Card(
                  elevation: 6,
                  color: AppTheme.secondaryGreen,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.terrain,
                          size: 50,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${widget.soilResult.soilType} Soil',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.soilResult.location != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.soilResult.location!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Recommended Plants Header
                Text(
                  'Recommended Plants',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Plant Recommendations
                ..._recommendations.map((plant) => _buildPlantCard(plant)),

                const SizedBox(height: 20),

                // Points Earned
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentOrange, Colors.orange.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        '+${AppConstants.pointsPerPlantRecommendation} Points!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Action Buttons
                EcoButton(
                  text: 'Analyze Another',
                  icon: Icons.camera_alt,
                  isLarge: true,
                  backgroundColor: AppTheme.secondaryGreen,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
                EcoButton(
                  text: 'Back to Home',
                  icon: Icons.home,
                  backgroundColor: AppTheme.primaryGreen,
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlantCard(Plant plant) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_florist,
                    size: 32,
                    color: AppTheme.secondaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    plant.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plant.description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    size: 20,
                    color: AppTheme.accentOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plant.plantingTips,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
