# EcoKids - NGO Waste Segregation & Plant Recommendation App

EcoKids is a Flutter-based environmental awareness app built for NGOs, schools, and community programs. It uses machine learning to classify waste, suggest plants based on soil type, and motivate users with points, badges, and progress tracking.

## Features

- Waste classification into Wet, Dry, and Recyclable categories.
- Soil classification with plant recommendations for Sandy, Clay, Loamy, and Silty soil.
- Gamification with points, levels, badges, and scan history.
- Child-friendly learning content on recycling, composting, planting, and water saving.
- Local persistence with SharedPreferences.
- Web support through a small Python inference server for TensorFlow Lite predictions.

## Tech Stack

- Flutter
- Dart
- TensorFlow Lite
- MobileNetV2 CNN
- Python
- SharedPreferences
- geolocator
- image_picker
- permission_handler
- fl_chart

## Project Structure

```text
lib/
├── main.dart
├── models/
├── screens/
├── services/
│   └── ml/
├── utils/
└── widgets/
server/
└── inference_server.py
training/
└── train_*.py
assets/models/
```

## Setup

### Flutter app

```bash
flutter pub get
flutter run
```

### Web inference server

```bash
python -m pip install -r server/requirements.txt
python -m uvicorn server.inference_server:app --host 127.0.0.1 --port 8000
```

If you run the app on web, update the inference base URL in `lib/utils/constants.dart` to point to your local server.

## ML Models

- Waste model: `assets/models/waste_classifier_model.tflite`
- Soil model: `assets/models/soil_classifier_model.tflite`

The app uses MobileNetV2-based classifiers with 224x224 RGB input.

## Gamification

- Waste scan: 10 points
- Plant recommendation: 15 points
- Level up every 100 points
- Badges for milestones like first scan, 10 waste scans, and 5 plant recommendations

## Notes

- Camera and location permissions are required for the full experience.
- The app is intended for academic and NGO use.
