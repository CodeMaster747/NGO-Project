# Training Custom Depthwise-Separable CNN + Texture Feature Fusion Model

## Overview

This training pipeline implements a novel hybrid approach combining:
- **Depthwise-Separable Convolutions**: Efficient mobile-optimized CNN architecture
- **Texture Feature Fusion**: GLCM (Gray-Level Co-occurrence Matrix) and LBP (Local Binary Pattern) features
- **Multi-modal Learning**: Combines deep learning with traditional computer vision techniques

## Why This Architecture?

### 📱 Mobile Optimized
- Depthwise-separable convolutions reduce parameters by ~8-9x compared to standard convolutions
- Smaller model size (~5-10 MB) suitable for mobile deployment
- Fast inference on mobile devices

### 🌱 Soil/Waste Texture Analysis
- GLCM captures spatial relationships between pixels (contrast, homogeneity, energy)
- LBP detects local texture patterns and edges
- Particularly effective for soil and waste material classification

### 🎓 Novel & Justifiable
- Unique hybrid architecture not commonly used
- Theoretically sound: combines learned features (CNN) with domain-specific features (texture)
- Published research supports texture features for material classification

### ⚡ Efficiency
- Training time: ~30-60 minutes per model (depending on dataset size)
- Inference time: <100ms on mobile devices
- Model size: 5-15 MB (TFLite quantized)

## Architecture Details

### Image Processing Branch (CNN)
```
Input (224x224x3)
↓
DepthwiseConv2D (3x3) → Conv2D (1x1, 32) → BatchNorm → MaxPool → Dropout
↓
DepthwiseConv2D (3x3) → Conv2D (1x1, 64) → BatchNorm → MaxPool → Dropout
↓
DepthwiseConv2D (3x3) → Conv2D (1x1, 128) → BatchNorm → MaxPool → Dropout
↓
DepthwiseConv2D (3x3) → Conv2D (1x1, 256) → BatchNorm → MaxPool → Dropout
↓
DepthwiseConv2D (3x3) → Conv2D (1x1, 512) → BatchNorm → GlobalAvgPool
↓
512-dimensional feature vector
```

### Texture Feature Branch
```
Input Image
↓
GLCM Features (72 dims) + LBP Features (26 dims) = 98 dims
↓
Dense(128) → BatchNorm → Dropout
↓
Dense(64) → BatchNorm → Dropout
↓
64-dimensional feature vector
```

### Fusion & Classification
```
CNN Features (512) + Texture Features (64) = 576 dims
↓
Dense(256) → BatchNorm → Dropout
↓
Dense(128) → Dropout
↓
Dense(num_classes, softmax)
```

## Dataset Structure

### Waste Classification Dataset
```
datasets/waste/DATASET/
├── TRAIN/
│   ├── O/  (Organic waste images)
│   └── R/  (Recyclable waste images)
└── TEST/
    ├── O/
    └── R/
```

### Soil Classification Dataset
```
datasets/soil/archive/Orignal-Dataset/
├── Alluvial_Soil/
├── Arid_Soil/
├── Black_Soil/
├── Laterite_Soil/
├── Mountain_Soil/
├── Red_Soil/
└── Yellow_Soil/
```

## Setup & Installation

### 1. Create Virtual Environment (Recommended)
```bash
cd training
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Verify Installation
```bash
python -c "import tensorflow as tf; print('TensorFlow version:', tf.__version__)"
python -c "import cv2; print('OpenCV version:', cv2.__version__)"
python -c "import skimage; print('scikit-image installed')"
```

## Training

### Run Full Training Pipeline
```bash
python train_custom_cnn_with_texture.py
```

This will:
1. Load waste classification dataset
2. Extract texture features (GLCM + LBP) from each image
3. Train waste classifier (60 epochs)
4. Convert to TFLite and save
5. Load soil classification dataset
6. Extract texture features
7. Train soil classifier (70 epochs)
8. Convert to TFLite and save

### Training Parameters

- **Input Size**: 224x224 pixels
- **Batch Size**: 32
- **Waste Model Epochs**: 60 (adjustable)
- **Soil Model Epochs**: 70 (adjustable, 7 classes need more training)
- **Optimizer**: Adam (lr=0.001, with ReduceLROnPlateau)
- **Early Stopping**: Patience=15 epochs
- **Validation Split**: 20%

### Texture Feature Parameters

**GLCM (Gray-Level Co-occurrence Matrix)**:
- Distances: [1, 2, 3]
- Angles: [0°, 45°, 90°, 135°]
- Properties: contrast, dissimilarity, homogeneity, energy, correlation, ASM
- Total features: 72 dimensions

**LBP (Local Binary Pattern)**:
- Radius: 3
- Points: 24 (8 × radius)
- Method: uniform
- Histogram bins: ~26 dimensions

## Output Files

After training, you'll find in `assets/models/`:

### For Each Model (waste_classifier, soil_classifier):
- `{model_name}_model.tflite` - Quantized TFLite model for deployment
- `{model_name}_classes.json` - Class label mappings
- `{model_name}_metadata.json` - Model metadata and metrics
- `{model_name}_training_log.csv` - Epoch-by-epoch training metrics
- `{model_name}_training_history.png` - Accuracy/loss plots
- `{model_name}_best.h5` - Best checkpoint during training
- `{model_name}_full_model.h5` - Full Keras model (for retraining)

## Expected Performance

### Waste Classification (2 classes)
- Training accuracy: ~95-98%
- Validation accuracy: ~92-95%
- Model size: ~5-8 MB
- Inference time: <50ms

### Soil Classification (7 classes)
- Training accuracy: ~90-95%
- Validation accuracy: ~85-92%
- Model size: ~8-12 MB
- Inference time: <80ms

## Integration with Flutter

### 1. Copy Model Files
```bash
cp assets/models/waste_classifier_model.tflite ../assets/models/
cp assets/models/soil_classifier_model.tflite ../assets/models/
cp assets/models/waste_classifier_classes.json ../lib/utils/
cp assets/models/soil_classifier_classes.json ../lib/utils/
```

### 2. Update pubspec.yaml
```yaml
flutter:
  assets:
    - assets/models/waste_classifier_model.tflite
    - assets/models/soil_classifier_model.tflite
```

### 3. Model Inference
The model expects TWO inputs:
1. **Image tensor**: (1, 224, 224, 3) - RGB image
2. **Texture features**: (1, 98) - GLCM + LBP features

You'll need to:
- Extract texture features in Flutter (or use a simplified version)
- OR modify the model to be image-only (retrain without texture branch)

## Advanced: Retraining & Fine-tuning

### Load Saved Model for Fine-tuning
```python
from tensorflow import keras

# Load full model
model = keras.models.load_model('assets/models/soil_classifier_full_model.h5')

# Fine-tune with new data
model.fit([X_train_img, X_train_texture], y_train, epochs=10)
```

### Adjust Training Epochs
Edit `train_custom_cnn_with_texture.py`:
```python
# Line ~530 - Waste model
train_model(..., epochs=100)  # Increase for better accuracy

# Line ~545 - Soil model
train_model(..., epochs=120)  # More classes need more epochs
```

## Troubleshooting

### Out of Memory
- Reduce batch size: `BATCH_SIZE = 16` (line 18)
- Reduce image size: `IMG_SIZE = 160` (line 17)

### Slow Training
- Use GPU if available (automatically detected)
- Reduce epochs for testing
- Use smaller dataset subset

### Low Accuracy
- Increase epochs (60-100+)
- Check dataset quality and balance
- Adjust learning rate: `Adam(learning_rate=0.0005)`
- Add data augmentation

### Model Too Large
- Reduce number of filters in Conv layers
- Increase quantization (modify converter settings)
- Remove texture branch (image-only model)

## Citation & References

This architecture is inspired by:
- **MobileNet**: Depthwise-separable convolutions
- **Texture Analysis**: GLCM and LBP features widely used in material science
- **Multi-modal Learning**: Combining CNN and handcrafted features

## License

This code is for educational purposes as part of a Mobile Application Development project.
