import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../services/storage_service.dart';
import '../widgets/points_display.dart';
import '../widgets/level_badge.dart';
import '../widgets/eco_button.dart';
import '../utils/theme.dart';
import 'gamification_screen.dart';
import 'learning_screen.dart';
import 'settings_screen.dart';

/// Main dashboard/home screen
/// Shows points, level, and main action buttons
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  UserProgress _progress = UserProgress();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await _storage.loadUserProgress();
    setState(() {
      _progress = progress;
    });
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Different screens for bottom navigation
    final screens = [
      _buildHomeContent(),
      GamificationScreen(progress: _progress, onProgressUpdated: _loadProgress),
      LearningScreen(),
      SettingsScreen(onProgressReset: _loadProgress),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoKids'),
        centerTitle: true,
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadProgress,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Points and Level Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  PointsDisplay(points: _progress.totalPoints),
                  LevelBadge(
                    level: _progress.currentLevel,
                    progress: _progress.progressToNextLevel,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Welcome Message
              Text(
                'What would you like to do today?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Main Action Cards
              _buildActionCard(
                context,
                title: 'Scan Waste',
                subtitle: 'Learn how to sort your trash',
                icon: Icons.delete_outline,
                color: AppTheme.primaryGreen,
                onTap: () async {
                  await Navigator.pushNamed(context, '/waste-scan');
                  _loadProgress(); // Refresh after returning
                },
              ),
              const SizedBox(height: 20),
              _buildActionCard(
                context,
                title: 'Plant Recommendation',
                subtitle: 'Find the perfect plants for your soil',
                icon: Icons.local_florist,
                color: AppTheme.secondaryGreen,
                onTap: () async {
                  await Navigator.pushNamed(context, '/soil-capture');
                  _loadProgress(); // Refresh after returning
                },
              ),
              const SizedBox(height: 30),

              // Quick Stats
              _buildQuickStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Impact',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.recycling,
                  '${_progress.totalWasteScans}',
                  'Waste Scans',
                ),
                _buildStatItem(
                  Icons.local_florist,
                  '${_progress.totalPlantScans}',
                  'Plant Scans',
                ),
                _buildStatItem(
                  Icons.emoji_events,
                  '${_progress.badgesEarned.length}',
                  'Badges',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primaryGreen),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
