import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/waste/waste_scan_screen.dart';
import 'screens/plant/soil_capture_screen.dart';

/// Main entry point for the NGO EcoKids app
/// Initializes services and sets up navigation
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage service
  await StorageService().initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const EcoKidsApp());
}

/// Root application widget
class EcoKidsApp extends StatelessWidget {
  const EcoKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Routes
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/waste-scan': (context) => const WasteScanScreen(),
        '/soil-capture': (context) => const SoilCaptureScreen(),
      },
    );
  }
}
