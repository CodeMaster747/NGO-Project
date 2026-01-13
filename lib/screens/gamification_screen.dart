import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_progress.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

/// Gamification screen showing progress, badges, and statistics
class GamificationScreen extends StatelessWidget {
  final UserProgress progress;
  final VoidCallback onProgressUpdated;

  const GamificationScreen({
    super.key,
    required this.progress,
    required this.onProgressUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Level Progress Card
            Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Level ${progress.currentLevel}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${progress.totalPoints} Points',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress.progressToNextLevel,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.secondaryGreen,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${progress.pointsToNextLevel} points to Level ${progress.currentLevel + 1}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Badges Section
            Text(
              'Badges Earned',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            _buildBadgesGrid(),
            const SizedBox(height: 20),

            // Statistics Section
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            _buildStatisticsCard(),
            const SizedBox(height: 20),

            // Activity Chart
            Text(
              'Activity Breakdown',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            _buildActivityChart(),
            const SizedBox(height: 20),

            // Waste Type Chart
            if (progress.totalWasteScans > 0) ...[
              Text(
                'Waste Types Scanned',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              _buildWasteTypeChart(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesGrid() {
    final allBadges = AppConstants.badges.keys.toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badgeKey = allBadges[index];
        final badgeInfo = AppConstants.badges[badgeKey]!;
        final isEarned = progress.badgesEarned.contains(badgeKey);

        return Card(
          elevation: isEarned ? 4 : 1,
          color: isEarned ? AppTheme.accentOrange.withOpacity(0.1) : null,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  badgeInfo['icon'],
                  size: 36,
                  color: isEarned ? AppTheme.accentOrange : Colors.grey,
                ),
                const SizedBox(height: 4),
                Text(
                  badgeInfo['name'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                    color: isEarned ? AppTheme.textPrimary : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildStatRow('Total Scans', '${progress.totalScans}'),
            const Divider(),
            _buildStatRow('Waste Scans', '${progress.totalWasteScans}'),
            const Divider(),
            _buildStatRow('Plant Scans', '${progress.totalPlantScans}'),
            const Divider(),
            _buildStatRow('Badges Earned', '${progress.badgesEarned.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (progress.totalScans > 0 ? progress.totalScans : 10).toDouble(),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: progress.totalWasteScans.toDouble(),
                      color: AppTheme.primaryGreen,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: progress.totalPlantScans.toDouble(),
                      color: AppTheme.secondaryGreen,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('Waste');
                        case 1:
                          return const Text('Plant');
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWasteTypeChart() {
    final wasteData = progress.wasteTypeCount;
    final total = wasteData.values.fold(0, (sum, count) => sum + count);
    
    if (total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: (wasteData['Wet'] ?? 0).toDouble(),
                  title: 'Wet\n${wasteData['Wet']}',
                  color: AppConstants.wetWasteColor,
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: (wasteData['Dry'] ?? 0).toDouble(),
                  title: 'Dry\n${wasteData['Dry']}',
                  color: AppConstants.dryWasteColor,
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: (wasteData['Recyclable'] ?? 0).toDouble(),
                  title: 'Recyclable\n${wasteData['Recyclable']}',
                  color: AppConstants.recyclableColor,
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ),
    );
  }
}
