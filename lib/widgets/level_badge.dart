import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/gamification_service.dart';

/// Widget to display user level with badge
class LevelBadge extends StatelessWidget {
  final int level;
  final double progress; // 0.0 to 1.0

  const LevelBadge({
    super.key,
    required this.level,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final gamification = GamificationService();
    final levelName = gamification.getLevelName(level);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Progress circle
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.secondaryGreen,
                ),
              ),
            ),
            // Level badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          levelName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
