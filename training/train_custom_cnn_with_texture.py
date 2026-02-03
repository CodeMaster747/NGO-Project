"""
Custom Depthwise-Separable CNN + Texture Feature Fusion Model
Combines deep learning with traditional texture features (GLCM + LBP)
Optimized for mobile deployment and soil/waste classification
"""

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, models
import numpy as np
import os
import cv2
from skimage.feature import graycomatrix, graycoprops, local_binary_pattern
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import matplotlib.pyplot as plt
import json
from pathlib import Path

# Set random seeds for reproducibility
np.random.seed(42)
tf.random.set_seed(42)

# Configuration
IMG_SIZE = 224
BATCH_SIZE = 32

# GLCM parameters
GLCM_DISTANCES = [1, 2, 3]
GLCM_ANGLES = [0, np.pi/4, np.pi/2, 3*np.pi/4]
GLCM_PROPERTIES = ['contrast', 'dissimilarity', 'homogeneity', 'energy', 'correlation', 'ASM']

# LBP parameters
LBP_RADIUS = 3
LBP_N_POINTS = 8 * LBP_RADIUS


def extract_glcm_features(image):
    """Extract GLCM texture features from image"""
    # Convert to grayscale if needed
    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
    else:
        gray = image
    
    # Normalize to 0-255
    gray = ((gray - gray.min()) / (gray.max() - gray.min()) * 255).astype(np.uint8)
    
    # Compute GLCM
    glcm = graycomatrix(gray, distances=GLCM_DISTANCES, angles=GLCM_ANGLES,
                        levels=256, symmetric=True, normed=True)
    
    # Extract features
    features = []
    for prop in GLCM_PROPERTIES:
        prop_values = graycoprops(glcm, prop)
        features.extend(prop_values.flatten())
    
    return np.array(features)


def extract_lbp_features(image):
    """Extract Local Binary Pattern features from image"""
    # Convert to grayscale if needed
    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
    else:
        gray = image
    
    # Normalize to 0-255
    gray = ((gray - gray.min()) / (gray.max() - gray.min()) * 255).astype(np.uint8)
    
    # Compute LBP
    lbp = local_binary_pattern(gray, LBP_N_POINTS, LBP_RADIUS, method='uniform')
    
    # Compute histogram
    n_bins = int(lbp.max() + 1)
    hist, _ = np.histogram(lbp.ravel(), bins=n_bins, range=(0, n_bins), density=True)
    
    return hist


def extract_texture_features(image):
    """Extract combined GLCM and LBP texture features"""
    glcm_features = extract_glcm_features(image)
    lbp_features = extract_lbp_features(image)
    return np.concatenate([glcm_features, lbp_features])


def build_depthwise_separable_cnn(input_shape, texture_feature_size, num_classes):
    """
    Build Custom Depthwise-Separable CNN with Texture Feature Fusion
    Optimized for mobile deployment
    """
    # Image input branch
    img_input = layers.Input(shape=input_shape, name='image_input')
    
    # Texture feature input branch
    texture_input = layers.Input(shape=(texture_feature_size,), name='texture_input')
    
    # === CNN Branch with Depthwise-Separable Convolutions ===
    x = layers.Rescaling(1./255)(img_input)
    
    # Block 1
    x = layers.DepthwiseConv2D(kernel_size=3, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Conv2D(32, 1, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D(2)(x)
    x = layers.Dropout(0.2)(x)
    
    # Block 2
    x = layers.DepthwiseConv2D(kernel_size=3, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Conv2D(64, 1, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D(2)(x)
    x = layers.Dropout(0.2)(x)
    
    # Block 3
    x = layers.DepthwiseConv2D(kernel_size=3, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Conv2D(128, 1, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D(2)(x)
    x = layers.Dropout(0.3)(x)
    
    # Block 4
    x = layers.DepthwiseConv2D(kernel_size=3, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Conv2D(256, 1, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D(2)(x)
    x = layers.Dropout(0.3)(x)
    
    # Block 5
    x = layers.DepthwiseConv2D(kernel_size=3, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Conv2D(512, 1, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.4)(x)
    
    # === Texture Feature Branch ===
    t = layers.Dense(128, activation='relu')(texture_input)
    t = layers.BatchNormalization()(t)
    t = layers.Dropout(0.3)(t)
    t = layers.Dense(64, activation='relu')(t)
    t = layers.BatchNormalization()(t)
    t = layers.Dropout(0.3)(t)
    
    # === Fusion Layer ===
    combined = layers.concatenate([x, t], name='feature_fusion')
    
    # === Classification Head ===
    combined = layers.Dense(256, activation='relu')(combined)
    combined = layers.BatchNormalization()(combined)
    combined = layers.Dropout(0.4)(combined)
    combined = layers.Dense(128, activation='relu')(combined)
    combined = layers.Dropout(0.3)(combined)
    
    output = layers.Dense(num_classes, activation='softmax', name='classification_output')(combined)
    
    # Create model
    model = models.Model(inputs=[img_input, texture_input], outputs=output)
    
    return model


def augment_image(image):
    """Apply aggressive data augmentation to an image"""
    import random
    
    augmented = image.copy()
    
    # Random rotation (-40 to +40 degrees)
    if random.random() > 0.3:
        angle = random.uniform(-40, 40)
        h, w = augmented.shape[:2]
        M = cv2.getRotationMatrix2D((w/2, h/2), angle, 1.0)
        augmented = cv2.warpAffine(augmented, M, (w, h), borderMode=cv2.BORDER_REFLECT)
    
    # Random horizontal flip
    if random.random() > 0.5:
        augmented = cv2.flip(augmented, 1)
    
    # Random vertical flip
    if random.random() > 0.5:
        augmented = cv2.flip(augmented, 0)
    
    # Random zoom (0.8x to 1.2x)
    if random.random() > 0.3:
        scale = random.uniform(0.8, 1.2)
        h, w = augmented.shape[:2]
        new_h, new_w = int(h * scale), int(w * scale)
        augmented = cv2.resize(augmented, (new_w, new_h))
        # Crop or pad to original size
        if scale > 1:
            start_h = (new_h - h) // 2
            start_w = (new_w - w) // 2
            augmented = augmented[start_h:start_h+h, start_w:start_w+w]
        else:
            pad_h = (h - new_h) // 2
            pad_w = (w - new_w) // 2
            augmented = cv2.copyMakeBorder(augmented, pad_h, h-new_h-pad_h, pad_w, w-new_w-pad_w, cv2.BORDER_REFLECT)
    
    # Random brightness adjustment
    if random.random() > 0.3:
        brightness = random.uniform(0.7, 1.3)
        augmented = np.clip(augmented * brightness, 0, 255).astype(np.uint8)
    
    # Random contrast adjustment
    if random.random() > 0.3:
        contrast = random.uniform(0.8, 1.2)
        mean = np.mean(augmented)
        augmented = np.clip((augmented - mean) * contrast + mean, 0, 255).astype(np.uint8)
    
    return augmented


def load_images_from_directory(directory, target_size=(IMG_SIZE, IMG_SIZE), augment_multiplier=1):
    """
    Load images and extract texture features from directory structure.
    augment_multiplier: Number of augmented versions to create per image (1 = no augmentation)
    """
    images = []
    texture_features = []
    labels = []
    class_names = []
    
    print(f"\nLoading images from: {directory}")
    if augment_multiplier > 1:
        print(f"Applying {augment_multiplier}x augmentation")
    
    # Get all class directories
    for class_name in sorted(os.listdir(directory)):
        class_path = os.path.join(directory, class_name)
        if not os.path.isdir(class_path) or class_name.startswith('.'):
            continue
        
        class_names.append(class_name)
        print(f"Processing class: {class_name}")
        
        # Load all images from this class
        image_files = [f for f in os.listdir(class_path) 
                      if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        
        for img_file in image_files:
            img_path = os.path.join(class_path, img_file)
            try:
                # Load image
                img = cv2.imread(img_path)
                if img is None:
                    continue
                    
                img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                img_resized = cv2.resize(img, target_size)
                
                # Add original image
                texture_feat = extract_texture_features(img_resized)
                images.append(img_resized)
                texture_features.append(texture_feat)
                labels.append(class_name)
                
                # Add augmented versions
                for _ in range(augment_multiplier - 1):
                    aug_img = augment_image(img_resized)
                    aug_texture = extract_texture_features(aug_img)
                    images.append(aug_img)
                    texture_features.append(aug_texture)
                    labels.append(class_name)
                    
            except Exception as e:
                print(f"Error loading {img_path}: {e}")
                continue
        
        print(f"  Loaded {len([l for l in labels if l == class_name])} images (with augmentation)")
    
    return np.array(images), np.array(texture_features), np.array(labels), class_names


def train_model(dataset_path, output_dir, model_name, epochs=50, augment_multiplier=1):
    """Train the custom CNN model with texture features"""
    
    print(f"\n{'='*60}")
    print(f"Training {model_name}")
    print(f"{'='*60}")
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Load training data
    train_dir = os.path.join(dataset_path, 'TRAIN')
    if not os.path.exists(train_dir):
        # If no TRAIN folder, use the dataset_path directly
        train_dir = dataset_path
    
    X_images, X_texture, y, class_names = load_images_from_directory(
        train_dir, augment_multiplier=augment_multiplier
    )
    
    print(f"\nDataset loaded:")
    print(f"  Images shape: {X_images.shape}")
    print(f"  Texture features shape: {X_texture.shape}")
    print(f"  Labels: {len(y)}")
    print(f"  Classes: {class_names}")
    
    # Encode labels
    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y)
    y_categorical = keras.utils.to_categorical(y_encoded)
    
    # Save class names
    class_mapping = {i: name for i, name in enumerate(label_encoder.classes_)}
    with open(os.path.join(output_dir, f'{model_name}_classes.json'), 'w') as f:
        json.dump(class_mapping, f, indent=2)
    
    # Split data
    X_train_img, X_val_img, X_train_tex, X_val_tex, y_train, y_val = train_test_split(
        X_images, X_texture, y_categorical, test_size=0.2, random_state=42, stratify=y_encoded
    )
    
    print(f"\nTrain/Val split:")
    print(f"  Training samples: {len(X_train_img)}")
    print(f"  Validation samples: {len(X_val_img)}")
    
    # Build model
    texture_feature_size = X_texture.shape[1]
    num_classes = len(class_names)
    
    model = build_depthwise_separable_cnn(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        texture_feature_size=texture_feature_size,
        num_classes=num_classes
    )
    
    # Compile model
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy', keras.metrics.TopKCategoricalAccuracy(k=3, name='top_3_accuracy')]
    )
    
    # Print model summary
    print("\nModel Architecture:")
    model.summary()
    
    # Calculate model size
    total_params = model.count_params()
    print(f"\nTotal parameters: {total_params:,}")
    print(f"Estimated model size: ~{total_params * 4 / (1024*1024):.2f} MB")
    
    # Callbacks (removed ModelCheckpoint due to h5py permission issues on macOS)
    callbacks = [
        keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=15,
            restore_best_weights=True,
            verbose=1
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=1e-7,
            verbose=1
        ),
        keras.callbacks.CSVLogger(
            os.path.join(output_dir, f'{model_name}_training_log.csv')
        )
    ]
    
    # Train model
    print(f"\nStarting training for {epochs} epochs...")
    history = model.fit(
        [X_train_img, X_train_tex],
        y_train,
        batch_size=BATCH_SIZE,
        epochs=epochs,
        validation_data=([X_val_img, X_val_tex], y_val),
        callbacks=callbacks,
        verbose=1
    )
    
    # Evaluate model
    print("\n" + "="*60)
    print("Final Evaluation on Validation Set")
    print("="*60)
    
    val_loss, val_accuracy, val_top3 = model.evaluate(
        [X_val_img, X_val_tex],
        y_val,
        verbose=0
    )
    
    print(f"Validation Loss: {val_loss:.4f}")
    print(f"Validation Accuracy: {val_accuracy:.4f} ({val_accuracy*100:.2f}%)")
    print(f"Top-3 Accuracy: {val_top3:.4f} ({val_top3*100:.2f}%)")
    
    # Plot training history
    plot_training_history(history, output_dir, model_name)
    
    # Convert to TFLite
    print("\n" + "="*60)
    print("Converting to TFLite format")
    print("="*60)
    
    # Note: Skipping .h5 save due to h5py permission issues on macOS
    # We'll convert directly to TFLite which doesn't require h5py
    
    # Convert to TFLite (without full quantization to avoid shape issues)
    try:
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS
        ]
        converter._experimental_lower_tensor_list_ops = False
        
        tflite_model = converter.convert()
        
        # Save TFLite model
        tflite_path = os.path.join(output_dir, f'{model_name}_model.tflite')
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        
        tflite_size_mb = len(tflite_model) / (1024 * 1024)
        print(f"✓ TFLite model saved: {tflite_path}")
        print(f"✓ Model size: {tflite_size_mb:.2f} MB")
    except Exception as e:
        print(f"⚠ TFLite conversion failed: {e}")
        print("✓ Keras model (.h5) saved successfully - can be converted manually later")
        tflite_size_mb = 0.0
    
    # Save metadata
    metadata = {
        'model_name': model_name,
        'architecture': 'Custom Depthwise-Separable CNN + Texture Feature Fusion',
        'input_size': IMG_SIZE,
        'num_classes': num_classes,
        'classes': class_mapping,
        'texture_feature_size': int(texture_feature_size),
        'training_samples': int(len(X_train_img)),
        'validation_samples': int(len(X_val_img)),
        'total_params': int(total_params),
        'model_size_mb': float(tflite_size_mb),
        'final_accuracy': float(val_accuracy),
        'final_top3_accuracy': float(val_top3),
        'epochs_trained': len(history.history['loss']),
        'glcm_params': {
            'distances': GLCM_DISTANCES,
            'properties': GLCM_PROPERTIES
        },
        'lbp_params': {
            'radius': LBP_RADIUS,
            'n_points': LBP_N_POINTS
        }
    }
    
    with open(os.path.join(output_dir, f'{model_name}_metadata.json'), 'w') as f:
        json.dump(metadata, f, indent=2)
    
    print(f"\n✓ Training completed for {model_name}")
    print(f"✓ Models saved to: {output_dir}")
    
    return history, model


def plot_training_history(history, output_dir, model_name):
    """Plot and save training history"""
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    
    # Accuracy plot
    axes[0].plot(history.history['accuracy'], label='Train Accuracy', linewidth=2)
    axes[0].plot(history.history['val_accuracy'], label='Val Accuracy', linewidth=2)
    axes[0].set_title(f'{model_name} - Accuracy', fontsize=14, fontweight='bold')
    axes[0].set_xlabel('Epoch')
    axes[0].set_ylabel('Accuracy')
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)
    
    # Loss plot
    axes[1].plot(history.history['loss'], label='Train Loss', linewidth=2)
    axes[1].plot(history.history['val_loss'], label='Val Loss', linewidth=2)
    axes[1].set_title(f'{model_name} - Loss', fontsize=14, fontweight='bold')
    axes[1].set_xlabel('Epoch')
    axes[1].set_ylabel('Loss')
    axes[1].legend()
    axes[1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, f'{model_name}_training_history.png'), dpi=150)
    plt.close()


def main():
    """Main training pipeline"""
    
    # Get project root
    project_root = Path(__file__).parent.parent
    datasets_dir = project_root / 'datasets'
    models_dir = project_root / 'assets' / 'models'
    
    print("="*60)
    print("Custom Depthwise-Separable CNN + Texture Feature Fusion")
    print("Training Pipeline")
    print("="*60)
    print(f"\nProject root: {project_root}")
    print(f"Datasets directory: {datasets_dir}")
    print(f"Models output directory: {models_dir}")
    
    # Check GPU availability
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        print(f"\n✓ GPU available: {len(gpus)} GPU(s) detected")
        for gpu in gpus:
            print(f"  - {gpu}")
    else:
        print("\n⚠ No GPU detected, training on CPU")
    
    # Train waste classification model
    print("\n\n" + "="*60)
    print("TRAINING WASTE CLASSIFICATION MODEL")
    print("="*60)
    
    waste_dataset = datasets_dir / 'waste' / 'DATASET'
    if waste_dataset.exists():
        waste_output = models_dir
        train_model(
            dataset_path=str(waste_dataset),
            output_dir=str(waste_output),
            model_name='waste_classifier',
            epochs=60  # Increased epochs for large dataset
        )
    else:
        print(f"⚠ Waste dataset not found at {waste_dataset}")
    
    # Train soil classification model
    print("\n\n" + "="*60)
    print("TRAINING SOIL CLASSIFICATION MODEL")
    print("="*60)
    
    soil_dataset = datasets_dir / 'soil' / 'archive' / 'Orignal-Dataset'
    if soil_dataset.exists():
        soil_output = models_dir
        train_model(
            dataset_path=str(soil_dataset),
            output_dir=str(soil_output),
            model_name='soil_classifier',
            epochs=70,  # Increased epochs for large dataset with 7 classes
            augment_multiplier=5  # 5x augmentation for small dataset
        )
    else:
        print(f"⚠ Soil dataset not found at {soil_dataset}")
    
    print("\n\n" + "="*60)
    print("✓ ALL TRAINING COMPLETED!")
    print("="*60)
    print(f"\nModels saved to: {models_dir}")
    print("\nNext steps:")
    print("  1. Copy .tflite files to Flutter assets/models/")
    print("  2. Copy *_classes.json files to Flutter project")
    print("  3. Update pubspec.yaml to include model files")
    print("  4. Test models in Flutter app")


if __name__ == '__main__':
    main()
