import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/waste_result.dart';
import '../../services/storage_service.dart';
import '../../services/gamification_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/eco_button.dart';

/// Screen showing waste classification results
class WasteResultScreen extends StatefulWidget {
  final WasteResult result;
  final XFile imageFile;

  const WasteResultScreen({
    super.key,
    required this.result,
    required this.imageFile,
  });

  @override
  State<WasteResultScreen> createState() => _WasteResultScreenState();
}

class _WasteResultScreenState extends State<WasteResultScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final GamificationService _gamification = GamificationService();

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  List<String> _newBadges = [];

  @override
  void initState() {
    super.initState();

    // Setup animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    // Award points and save progress
    _awardPoints();
  }

  Future<void> _awardPoints() async {
    final progress = await _storage.loadUserProgress();
    _newBadges = _gamification.awardWasteScanPoints(
      progress,
      widget.result.category,
    );
    await _storage.saveUserProgress(progress);

    // Show badge dialog if new badges earned
    if (_newBadges.isNotEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 800), () {
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
    final wasteColor = AppTheme.getWasteColor(widget.result.category);
    final wasteIcon = AppTheme.getWasteIcon(widget.result.category);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Container(
                height: 250,
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
                  child: Image.file(
                    File(widget.imageFile.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Category Result
              ScaleTransition(
                scale: _scaleAnimation,
                child: Card(
                  elevation: 6,
                  color: wasteColor,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(wasteIcon, size: 60, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          widget.result.category,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(widget.result.confidence * 100).toStringAsFixed(1)}% confident',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Disposal Instructions
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: wasteColor),
                          const SizedBox(width: 8),
                          Text(
                            'How to Dispose',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.result.disposalInstructions,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Environmental Tip
              Card(
                elevation: 3,
                color: AppTheme.secondaryGreen.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            color: AppTheme.accentOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Eco Tip',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.result.environmentalTip,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
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
                      '+${widget.result.pointsAwarded} Points!',
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
                text: 'Scan Another',
                icon: Icons.camera_alt,
                isLarge: true,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              EcoButton(
                text: 'Back to Home',
                icon: Icons.home,
                backgroundColor: AppTheme.secondaryGreen,
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
