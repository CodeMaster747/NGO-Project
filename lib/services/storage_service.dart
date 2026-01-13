import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';

/// Service for persisting user data locally using SharedPreferences
/// Handles saving and loading user progress, points, badges, etc.
class StorageService {
  static const String _keyUserProgress = 'user_progress';
  
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure preferences are initialized
  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }

  /// Save user progress
  Future<bool> saveUserProgress(UserProgress progress) async {
    try {
      final prefs = await _preferences;
      final jsonString = jsonEncode(progress.toJson());
      return await prefs.setString(_keyUserProgress, jsonString);
    } catch (e) {
      print('Error saving user progress: $e');
      return false;
    }
  }

  /// Load user progress
  Future<UserProgress> loadUserProgress() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_keyUserProgress);
      
      if (jsonString == null) {
        // Return new progress if none exists
        return UserProgress();
      }
      
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProgress.fromJson(jsonMap);
    } catch (e) {
      print('Error loading user progress: $e');
      // Return new progress on error
      return UserProgress();
    }
  }

  /// Clear all user data
  Future<bool> clearAllData() async {
    try {
      final prefs = await _preferences;
      return await prefs.clear();
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  /// Check if user data exists
  Future<bool> hasUserData() async {
    try {
      final prefs = await _preferences;
      return prefs.containsKey(_keyUserProgress);
    } catch (e) {
      print('Error checking user data: $e');
      return false;
    }
  }
}
