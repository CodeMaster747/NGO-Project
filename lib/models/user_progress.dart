/// Model representing user progress and gamification data
/// Tracks points, level, badges, and activity history
class UserProgress {
  int totalPoints;
  int currentLevel;
  List<String> badgesEarned;
  int totalWasteScans;
  int totalPlantScans;
  Map<String, int> wasteTypeCount; // Count of each waste type scanned
  DateTime lastUpdated;

  UserProgress({
    this.totalPoints = 0,
    this.currentLevel = 1,
    List<String>? badgesEarned,
    this.totalWasteScans = 0,
    this.totalPlantScans = 0,
    Map<String, int>? wasteTypeCount,
    DateTime? lastUpdated,
  })  : badgesEarned = badgesEarned ?? [],
        wasteTypeCount = wasteTypeCount ?? {'Wet': 0, 'Dry': 0, 'Recyclable': 0},
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Add points and update level
  void addPoints(int points) {
    totalPoints += points;
    currentLevel = (totalPoints ~/ 100) + 1; // Level up every 100 points
    lastUpdated = DateTime.now();
  }

  /// Record a waste scan
  void recordWasteScan(String wasteType) {
    totalWasteScans++;
    wasteTypeCount[wasteType] = (wasteTypeCount[wasteType] ?? 0) + 1;
    lastUpdated = DateTime.now();
  }

  /// Record a plant scan
  void recordPlantScan() {
    totalPlantScans++;
    lastUpdated = DateTime.now();
  }

  /// Add a badge if not already earned
  void addBadge(String badge) {
    if (!badgesEarned.contains(badge)) {
      badgesEarned.add(badge);
      lastUpdated = DateTime.now();
    }
  }

  /// Get total scans
  int get totalScans => totalWasteScans + totalPlantScans;

  /// Get points needed for next level
  int get pointsToNextLevel {
    int nextLevelThreshold = currentLevel * 100;
    return nextLevelThreshold - totalPoints;
  }

  /// Get progress to next level (0.0 to 1.0)
  double get progressToNextLevel {
    int currentLevelThreshold = (currentLevel - 1) * 100;
    int nextLevelThreshold = currentLevel * 100;
    int pointsInCurrentLevel = totalPoints - currentLevelThreshold;
    int pointsNeededForLevel = nextLevelThreshold - currentLevelThreshold;
    return pointsInCurrentLevel / pointsNeededForLevel;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'totalPoints': totalPoints,
      'currentLevel': currentLevel,
      'badgesEarned': badgesEarned,
      'totalWasteScans': totalWasteScans,
      'totalPlantScans': totalPlantScans,
      'wasteTypeCount': wasteTypeCount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalPoints: json['totalPoints'] ?? 0,
      currentLevel: json['currentLevel'] ?? 1,
      badgesEarned: List<String>.from(json['badgesEarned'] ?? []),
      totalWasteScans: json['totalWasteScans'] ?? 0,
      totalPlantScans: json['totalPlantScans'] ?? 0,
      wasteTypeCount: Map<String, int>.from(json['wasteTypeCount'] ?? {}),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  /// Reset all progress
  void reset() {
    totalPoints = 0;
    currentLevel = 1;
    badgesEarned.clear();
    totalWasteScans = 0;
    totalPlantScans = 0;
    wasteTypeCount = {'Wet': 0, 'Dry': 0, 'Recyclable': 0};
    lastUpdated = DateTime.now();
  }
}
