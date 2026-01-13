# EcoKids - NGO Waste Segregation & Plant Recommendation App

An NGO-oriented mobile application for waste segregation and plant recommendation using Machine Learning (MobileNetV2 CNN via TensorFlow Lite).

## 📱 Overview

EcoKids is a child-friendly Flutter mobile app designed for NGOs, communities, and children to promote environmental awareness through:

- **AI-Powered Waste Classification**: Classify waste into Wet, Dry, and Recyclable categories using MobileNetV2 CNN
- **Soil Analysis & Plant Recommendations**: Identify soil types and get personalized plant recommendations based on soil and GPS location
- **Gamification**: Points, levels, badges, and progress tracking to encourage eco-friendly behavior
- **Educational Content**: Child-friendly tips on recycling, composting, and environmental protection

## 🎯 Features

### Waste Segregation Module
- Capture or upload waste images using camera/gallery
- On-device ML inference using TensorFlow Lite
- Classify waste into 3 categories: Wet, Dry, Recyclable
- Display disposal instructions and environmental tips
- Award points for each scan

### Plant Recommendation Module
- Capture soil images with GPS location
- Classify soil type (Sandy, Clay, Loamy, Silty)
- Rule-based plant recommendation engine
- Display 2-4 suitable plants with planting tips
- Award points for plant recommendations

### Gamification System
- Points system (10pts per waste scan, 15pts per plant scan)
- Level progression (every 100 points)
- 6 achievement badges (Eco Starter, Green Hero, Plant Master, etc.)
- Progress tracking with charts (bar and pie charts)
- Statistics dashboard

### Learning Module
- 6 child-friendly environmental tips
- Educational content on recycling, composting, and planting
- Simple, engaging language

## 🏗️ Architecture

```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models
│   ├── waste_result.dart
│   ├── soil_result.dart
│   ├── plant.dart
│   └── user_progress.dart
├── services/                      # Business logic
│   ├── ml/                        # ML services
│   │   ├── tflite_service.dart
│   │   ├── image_preprocessor.dart
│   │   ├── waste_classifier.dart
│   │   └── soil_classifier.dart
│   ├── recommendation_engine.dart
│   ├── gamification_service.dart
│   └── storage_service.dart
├── screens/                       # UI screens (9 screens)
├── widgets/                       # Reusable widgets
└── utils/                         # Constants and theme
```

## 🛠️ Technology Stack

- **Framework**: Flutter 3.10.4+
- **ML**: TensorFlow Lite (MobileNetV2 CNN)
- **State Management**: StatefulWidget
- **Local Storage**: SharedPreferences
- **Charts**: fl_chart
- **Camera**: image_picker
- **Location**: geolocator
- **Permissions**: permission_handler

## 📦 Dependencies

```yaml
dependencies:
  tflite_flutter: ^0.10.4      # ML inference
  image_picker: ^1.0.7          # Camera/gallery
  geolocator: ^11.0.0           # GPS location
  permission_handler: ^11.3.0   # Runtime permissions
  shared_preferences: ^2.2.2    # Local storage
  fl_chart: ^0.66.2             # Charts
  image: ^4.1.7                 # Image processing
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.4 or higher
- Android Studio / Xcode
- Android device/emulator (API 21+) or iOS device/simulator (iOS 12+)

### Installation

1. **Clone or navigate to the project**:
   ```bash
   cd /path/to/ngoapp
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## 🤖 Machine Learning Models

### Model Integration

The app is designed to work with TensorFlow Lite models:

- **Waste Classifier**: `assets/models/waste_classifier.tflite`
- **Soil Classifier**: `assets/models/soil_classifier.tflite`

### Model Specifications

- **Architecture**: MobileNetV2 (CNN)
- **Input Size**: 224x224x3 (RGB images)
- **Output**: Probability distribution over classes
- **Inference**: On-device (no internet required)

### Using Your Own Models

1. Train your MobileNetV2 models for waste and soil classification
2. Convert models to TensorFlow Lite format (.tflite)
3. Place models in `assets/models/` directory
4. Update class labels in `lib/utils/constants.dart` if needed

### Placeholder Mode

Currently, the app uses **placeholder classification logic** for demonstration purposes when TFLite models are not available. This generates random classifications with realistic confidence scores.

To enable actual ML inference:
1. Add your trained `.tflite` models to `assets/models/`
2. The app will automatically detect and use them
3. See `lib/services/ml/tflite_service.dart` for integration details

## 📱 Screens

1. **Splash Screen**: Animated welcome screen with app branding
2. **Home Screen**: Dashboard with points, level, and main actions
3. **Waste Scan Screen**: Camera/gallery interface for waste images
4. **Waste Result Screen**: Classification results with disposal instructions
5. **Soil Capture Screen**: Camera interface with GPS location
6. **Plant Recommendation Screen**: Soil type and plant suggestions
7. **Gamification Screen**: Progress, badges, and charts
8. **Learning Screen**: Environmental tips and education
9. **Settings Screen**: App info, mission, and progress reset

## 🎮 Gamification

### Points System
- Waste scan: **10 points**
- Plant recommendation: **15 points**

### Levels
- Level up every **100 points**
- Level names: Eco Beginner → Green Learner → Eco Warrior → Earth Hero → Planet Guardian → Eco Master

### Badges
- **Eco Starter**: Complete first waste scan
- **Green Hero**: Scan 10 waste items
- **Plant Master**: Get 5 plant recommendations
- **Recycling Champion**: Scan 20 recyclable items
- **Eco Warrior**: Reach level 5
- **Earth Guardian**: Reach level 10

## 🌱 Plant Database

The app includes 13 plants with soil and region requirements:
- Cactus, Lavender, Carrots (Sandy soil)
- Sunflower, Roses, Broccoli (Clay soil)
- Tomatoes, Marigold, Basil, Lettuce (Loamy soil)
- Cucumber, Mint, Spinach (Silty soil)

## 🎨 Design

- **Child-Friendly UI**: Large buttons, vibrant colors, simple language
- **Color Scheme**: Eco-friendly greens with orange accents
- **Animations**: Smooth transitions and engaging feedback
- **Accessibility**: High contrast, readable fonts

## 📊 Data Persistence

User progress is saved locally using SharedPreferences:
- Total points and current level
- Badges earned
- Scan history (waste and plant counts)
- Waste type breakdown

## 🔒 Permissions

### Android
- `CAMERA`: Capture waste/soil images
- `ACCESS_FINE_LOCATION`: GPS for plant recommendations
- `READ_EXTERNAL_STORAGE`: Gallery access

### iOS
- `NSCameraUsageDescription`: Camera access
- `NSPhotoLibraryUsageDescription`: Photo library access
- `NSLocationWhenInUseUsageDescription`: Location access

## 🧪 Testing

### Run the app
```bash
flutter run
```

### Test features
1. **Waste Scanning**: Tap "Scan Waste" → Capture/select image → View results
2. **Plant Recommendations**: Tap "Plant Recommendation" → Capture soil → View plants
3. **Gamification**: Check "Progress" tab for points, badges, and charts
4. **Learning**: Explore "Learn" tab for environmental tips
5. **Settings**: View app info and reset progress if needed

### Build for release
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 📝 Code Structure

- **Models**: Data classes with JSON serialization
- **Services**: Business logic separated from UI
- **Screens**: Full-screen pages with navigation
- **Widgets**: Reusable UI components
- **Utils**: Constants, theme, and helpers

## 🌍 NGO Mission

*"Empowering communities and children to protect our environment through smart waste management and sustainable planting."*

## 🤝 Contributing

This app is designed for educational and NGO purposes. Feel free to:
- Add more plants to the database
- Improve ML models
- Enhance UI/UX
- Add more languages
- Implement additional features

## 📄 License

This project is created for academic and NGO purposes.

## 👥 Target Audience

- NGOs promoting environmental awareness
- Schools and educational institutions
- Community groups
- Children (primary target users)
- Families interested in eco-friendly practices

## 🎓 Academic Context

This app demonstrates:
- **Advanced Machine Learning**: Deep Learning with CNN (MobileNetV2)
- **Mobile Development**: Flutter cross-platform development
- **On-Device ML**: TensorFlow Lite inference
- **Gamification**: User engagement through game mechanics
- **Social Impact**: Technology for environmental awareness

## 📞 Support

For questions or issues:
1. Check the code comments for detailed explanations
2. Review the implementation plan in the artifacts directory
3. Examine the modular architecture for specific features

---

**Built with ❤️ for a greener planet 🌍**
