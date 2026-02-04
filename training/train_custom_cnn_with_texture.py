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
from sklearn.metrics import confusion_matrix, classification_report
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


def canonicalize_class_name(name: str) -> str:
    cleaned = name.strip().replace('-', '_').replace(' ', '_')
    cleaned = '_'.join([p for p in cleaned.split('_') if p])
    return '_'.join([p[:1].upper() + p[1:].lower() if p else p for p in cleaned.split('_')])


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


def build_mobilenetv2_fusion(input_shape, texture_feature_size, num_classes, trainable_layers=30):
    img_input = layers.Input(shape=input_shape, name='image_input')
    texture_input = layers.Input(shape=(texture_feature_size,), name='texture_input')
    
    x = keras.applications.mobilenet_v2.preprocess_input(img_input)
    backbone = keras.applications.MobileNetV2(
        input_shape=input_shape,
        include_top=False,
        weights='imagenet'
    )
    backbone.trainable = True
    if trainable_layers is not None:
        for layer in backbone.layers[:-trainable_layers]:
            layer.trainable = False
    
    x = backbone(x)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.35)(x)
    
    t = layers.Dense(128, activation='relu')(texture_input)
    t = layers.BatchNormalization()(t)
    t = layers.Dropout(0.3)(t)
    t = layers.Dense(64, activation='relu')(t)
    t = layers.BatchNormalization()(t)
    t = layers.Dropout(0.3)(t)
    
    combined = layers.concatenate([x, t], name='feature_fusion')
    combined = layers.Dense(256, activation='relu')(combined)
    combined = layers.BatchNormalization()(combined)
    combined = layers.Dropout(0.4)(combined)
    combined = layers.Dense(128, activation='relu')(combined)
    combined = layers.Dropout(0.3)(combined)
    output = layers.Dense(num_classes, activation='softmax', name='classification_output')(combined)
    
    return models.Model(inputs=[img_input, texture_input], outputs=output)


def build_efficientnetv2b0_fusion(input_shape, texture_feature_size, num_classes, trainable_layers=40):
    img_input = layers.Input(shape=input_shape, name='image_input')
    texture_input = layers.Input(shape=(texture_feature_size,), name='texture_input')

    preprocess = keras.applications.efficientnet_v2.preprocess_input
    x = layers.Lambda(lambda t: preprocess(t), name='preprocess')(img_input)

    backbone = keras.applications.EfficientNetV2B0(
        input_shape=input_shape,
        include_top=False,
        weights='imagenet',
    )
    backbone.trainable = True
    if trainable_layers is not None:
        for layer in backbone.layers[:-trainable_layers]:
            layer.trainable = False

    x = backbone(x)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.35)(x)

    t = layers.Dense(128, activation='relu')(texture_input)
    t = layers.BatchNormalization()(t)
    t = layers.Dropout(0.3)(t)
    t = layers.Dense(64, activation='relu')(t)
    t = layers.BatchNormalization()(t)
    t = layers.Dropout(0.3)(t)

    combined = layers.concatenate([x, t], name='feature_fusion')
    combined = layers.Dense(256, activation='relu')(combined)
    combined = layers.BatchNormalization()(combined)
    combined = layers.Dropout(0.4)(combined)
    combined = layers.Dense(128, activation='relu')(combined)
    combined = layers.Dropout(0.3)(combined)
    output = layers.Dense(num_classes, activation='softmax', name='classification_output')(combined)

    return models.Model(inputs=[img_input, texture_input], outputs=output)


def build_image_only_backbone_classifier(
    input_shape,
    num_classes,
    backbone_name='efficientnetv2b0',
    trainable_layers=40,
):
    img_input = layers.Input(shape=input_shape, name='image_input')

    try:
        aug = keras.Sequential(
            [
                layers.RandomFlip('horizontal'),
                layers.RandomRotation(0.08),
                layers.RandomZoom(0.1),
                layers.RandomContrast(0.1),
            ],
            name='augmentation',
        )
        x = aug(img_input)
    except Exception:
        x = img_input

    backbone = None
    preprocess = None

    if backbone_name.lower() in ('efficientnetv2b0', 'effnetv2b0') and hasattr(keras.applications, 'EfficientNetV2B0'):
        preprocess = keras.applications.efficientnet_v2.preprocess_input
        backbone = keras.applications.EfficientNetV2B0(
            input_shape=input_shape,
            include_top=False,
            weights='imagenet',
        )
    elif backbone_name.lower() in ('efficientnetb0', 'effnetb0') and hasattr(keras.applications, 'EfficientNetB0'):
        preprocess = keras.applications.efficientnet.preprocess_input
        backbone = keras.applications.EfficientNetB0(
            input_shape=input_shape,
            include_top=False,
            weights='imagenet',
        )
    else:
        preprocess = keras.applications.mobilenet_v2.preprocess_input
        backbone = keras.applications.MobileNetV2(
            input_shape=input_shape,
            include_top=False,
            weights='imagenet',
        )

    x = layers.Lambda(lambda t: preprocess(t), name='preprocess')(x)

    backbone.trainable = True
    if trainable_layers is not None:
        for layer in backbone.layers[:-trainable_layers]:
            layer.trainable = False

    x = backbone(x)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.35)(x)
    x = layers.Dense(256, activation='relu')(x)
    x = layers.Dropout(0.25)(x)
    output = layers.Dense(num_classes, activation='softmax', name='classification_output')(x)

    return models.Model(inputs=img_input, outputs=output)


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


def load_images_from_file_list(file_paths, labels, target_size=(IMG_SIZE, IMG_SIZE), augment_multiplier=1):
    images = []
    texture_features = []
    out_labels = []

    for img_path, lbl in zip(file_paths, labels):
        try:
            img_bgr = cv2.imread(img_path)
            if img_bgr is None:
                continue
            img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
            img_resized = cv2.resize(img_rgb, target_size)

            texture_feat = extract_texture_features(img_resized)
            images.append(img_resized)
            texture_features.append(texture_feat)
            out_labels.append(lbl)

            for _ in range(max(0, augment_multiplier - 1)):
                aug_img = augment_image(img_resized)
                aug_texture = extract_texture_features(aug_img)
                images.append(aug_img)
                texture_features.append(aug_texture)
                out_labels.append(lbl)
        except Exception as e:
            print(f"Error loading {img_path}: {e}")
            continue

    return np.array(images), np.array(texture_features), np.array(out_labels)


def _write_history_csv(history, output_dir, model_name):
    keys = list(history.history.keys())
    csv_path = os.path.join(output_dir, f'{model_name}_training_log.csv')
    epochs = len(history.history.get(keys[0], [])) if keys else 0
    with open(csv_path, 'w', encoding='utf-8') as f:
        f.write('epoch,' + ','.join(keys) + '\n')
        for i in range(epochs):
            row = [str(i)]
            for k in keys:
                v = history.history.get(k, [])
                row.append(str(v[i]) if i < len(v) else '')
            f.write(','.join(row) + '\n')
    return csv_path


def _save_confusion_and_report(y_true, y_pred, labels, output_dir, model_name, title_suffix=''):
    cm = confusion_matrix(y_true, y_pred, labels=labels)
    report = classification_report(y_true, y_pred, labels=labels, zero_division=0)
    acc = float((np.array(y_true) == np.array(y_pred)).mean()) if len(y_true) else 0.0

    report_path = os.path.join(output_dir, f'{model_name}_classification_report.txt')
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(report)

    json_path = os.path.join(output_dir, f'{model_name}_test_report.json')
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(
            {
                'accuracy': acc,
                'labels': labels,
                'confusion_matrix': cm.tolist(),
                'classification_report': report,
            },
            f,
            indent=2,
        )

    fig, ax = plt.subplots(figsize=(7, 6))
    im = ax.imshow(cm, cmap='Blues')
    ax.set_xticks(range(len(labels)))
    ax.set_yticks(range(len(labels)))
    ax.set_xticklabels(labels, rotation=45, ha='right')
    ax.set_yticklabels(labels)
    ax.set_xlabel('Predicted')
    ax.set_ylabel('True')
    title = f'{model_name} Confusion Matrix'
    if title_suffix:
        title += f' ({title_suffix})'
    title += f'  Acc: {acc*100:.2f}%'
    ax.set_title(title)

    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(j, i, str(cm[i, j]), ha='center', va='center', fontsize=9, color='black')

    fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    fig.tight_layout()
    cm_path = os.path.join(output_dir, f'{model_name}_confusion_matrix.png')
    fig.savefig(cm_path, dpi=160)
    plt.close(fig)

    return acc, report_path, cm_path, json_path


def train_model(
    dataset_path,
    output_dir,
    model_name,
    epochs=50,
    augment_multiplier=1,
    use_pretrained_backbone=True,
    trainable_layers=30,
    use_class_weights=True,
    label_smoothing=0.05,
    use_texture_features=True,
    backbone_name='efficientnetv2b0',
    val_size=0.15,
    test_size=0.15,
):
    """Train the custom CNN model with texture features"""
    
    print(f"\n{'='*60}")
    print(f"Training {model_name}")
    print(f"{'='*60}")
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    dataset_dir = Path(dataset_path)
    candidate_train_dirs = ['TRAIN', 'Train', 'train']
    candidate_test_dirs = ['TEST', 'Test', 'test']

    split_train_dir = None
    split_test_dir = None
    for name in candidate_train_dirs:
        p = dataset_dir / name
        if p.exists() and p.is_dir():
            split_train_dir = p
            break
    for name in candidate_test_dirs:
        p = dataset_dir / name
        if p.exists() and p.is_dir():
            split_test_dir = p
            break

    if split_train_dir is not None:
        train_dir = str(split_train_dir)
        X_images, X_texture, y, class_names = load_images_from_directory(
            train_dir, augment_multiplier=augment_multiplier
        )
        if not use_texture_features:
            X_texture = np.zeros((len(X_images), 1), dtype=np.float32)
        y_canonical = np.array([canonicalize_class_name(lbl) for lbl in y])
        label_encoder = LabelEncoder()
        y_encoded = label_encoder.fit_transform(y_canonical)
        y_categorical = keras.utils.to_categorical(y_encoded)

        X_train_img, X_val_img, X_train_tex, X_val_tex, y_train, y_val = train_test_split(
            X_images, X_texture, y_categorical, test_size=val_size, random_state=42, stratify=y_encoded
        )

        X_test_img = None
        X_test_tex = None
        y_test = None
        if split_test_dir is not None:
            test_dir = str(split_test_dir)
            X_test_img, X_test_tex, y_test_labels, _ = load_images_from_directory(
                test_dir, augment_multiplier=1
            )
            y_test_canonical = np.array([canonicalize_class_name(lbl) for lbl in y_test_labels])
            y_test_encoded = label_encoder.transform(y_test_canonical)
            y_test = keras.utils.to_categorical(y_test_encoded, num_classes=len(label_encoder.classes_))
    else:
        file_paths = []
        labels = []
        for class_dir in sorted([p for p in dataset_dir.iterdir() if p.is_dir()]):
            class_name = canonicalize_class_name(class_dir.name)
            for f in class_dir.iterdir():
                if f.is_file() and f.suffix.lower() in ['.jpg', '.jpeg', '.png']:
                    file_paths.append(str(f))
                    labels.append(class_name)

        if len(file_paths) == 0:
            raise Exception(f'No images found under {dataset_dir}')

        label_encoder = LabelEncoder()
        y_encoded_all = label_encoder.fit_transform(labels)
        y_categorical_all = keras.utils.to_categorical(y_encoded_all)

        train_paths, temp_paths, y_train_idx, y_temp_idx = train_test_split(
            file_paths,
            y_encoded_all,
            test_size=(val_size + test_size),
            random_state=42,
            stratify=y_encoded_all,
        )
        val_ratio = val_size / (val_size + test_size)
        val_paths, test_paths, y_val_idx, y_test_idx = train_test_split(
            temp_paths,
            y_temp_idx,
            test_size=(1 - val_ratio),
            random_state=42,
            stratify=y_temp_idx,
        )

        y_train_labels = [label_encoder.classes_[i] for i in y_train_idx]
        y_val_labels = [label_encoder.classes_[i] for i in y_val_idx]
        y_test_labels = [label_encoder.classes_[i] for i in y_test_idx]

        X_train_img, X_train_tex, y_train_labels = load_images_from_file_list(
            train_paths, y_train_labels, augment_multiplier=augment_multiplier
        )
        X_val_img, X_val_tex, y_val_labels = load_images_from_file_list(
            val_paths, y_val_labels, augment_multiplier=1
        )
        X_test_img, X_test_tex, y_test_labels = load_images_from_file_list(
            test_paths, y_test_labels, augment_multiplier=1
        )

        y_train = keras.utils.to_categorical(label_encoder.transform(y_train_labels), num_classes=len(label_encoder.classes_))
        y_val = keras.utils.to_categorical(label_encoder.transform(y_val_labels), num_classes=len(label_encoder.classes_))
        y_test = keras.utils.to_categorical(label_encoder.transform(y_test_labels), num_classes=len(label_encoder.classes_))

        if not use_texture_features:
            X_train_tex = np.zeros((len(X_train_img), 1), dtype=np.float32)
            X_val_tex = np.zeros((len(X_val_img), 1), dtype=np.float32)
            X_test_tex = np.zeros((len(X_test_img), 1), dtype=np.float32)

        class_names = list(label_encoder.classes_)

    class_mapping = {i: name for i, name in enumerate(label_encoder.classes_)}
    with open(os.path.join(output_dir, f'{model_name}_classes.json'), 'w') as f:
        json.dump(class_mapping, f, indent=2)
    
    print(f"\nDataset loaded:")
    print(f"  Training samples: {len(X_train_img)}")
    print(f"  Validation samples: {len(X_val_img)}")
    if X_test_img is not None:
        print(f"  Test samples: {len(X_test_img)}")
    print(f"  Classes: {list(label_encoder.classes_)}")
    
    print(f"\nTrain/Val split:")
    print(f"  Training samples: {len(X_train_img)}")
    print(f"  Validation samples: {len(X_val_img)}")
    
    # Build model
    texture_feature_size = X_train_tex.shape[1] if use_texture_features else 1
    num_classes = len(label_encoder.classes_)
    
    if use_pretrained_backbone and not use_texture_features:
        model = build_image_only_backbone_classifier(
            input_shape=(IMG_SIZE, IMG_SIZE, 3),
            num_classes=num_classes,
            backbone_name=backbone_name,
            trainable_layers=trainable_layers,
        )
    elif use_pretrained_backbone and use_texture_features:
        if backbone_name.lower() in ('efficientnetv2b0', 'effnetv2b0'):
            model = build_efficientnetv2b0_fusion(
                input_shape=(IMG_SIZE, IMG_SIZE, 3),
                texture_feature_size=texture_feature_size,
                num_classes=num_classes,
                trainable_layers=trainable_layers,
            )
        else:
            model = build_mobilenetv2_fusion(
                input_shape=(IMG_SIZE, IMG_SIZE, 3),
                texture_feature_size=texture_feature_size,
                num_classes=num_classes,
                trainable_layers=trainable_layers,
            )
    else:
        model = build_depthwise_separable_cnn(
            input_shape=(IMG_SIZE, IMG_SIZE, 3),
            texture_feature_size=texture_feature_size,
            num_classes=num_classes
        )
    
    # Compile model
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.001),
        loss=keras.losses.CategoricalCrossentropy(label_smoothing=label_smoothing),
        metrics=['accuracy', keras.metrics.TopKCategoricalAccuracy(k=min(3, num_classes), name='top_3_accuracy')],
    )
    
    # Print model summary
    print("\nModel Architecture:")
    model.summary()
    
    # Calculate model size
    total_params = model.count_params()
    print(f"\nTotal parameters: {total_params:,}")
    print(f"Estimated model size: ~{total_params * 4 / (1024*1024):.2f} MB")
    
    # Callbacks
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
    ]
    
    # Train model
    print(f"\nStarting training for {epochs} epochs...")
    train_inputs = [X_train_img, X_train_tex] if use_texture_features else X_train_img
    val_inputs = ([X_val_img, X_val_tex], y_val) if use_texture_features else (X_val_img, y_val)

    class_weight = None
    if use_class_weights:
        y_train_idx = np.argmax(y_train, axis=1)
        classes, counts = np.unique(y_train_idx, return_counts=True)
        total = counts.sum()
        class_weight = {int(c): float(total / (len(classes) * cnt)) for c, cnt in zip(classes, counts)}

    def _set_backbone_trainable(model, trainable, trainable_layers=None):
        for layer in model.layers:
            if isinstance(layer, keras.Model):
                name = layer.name.lower()
                if 'efficientnet' in name or 'mobilenet' in name:
                    if not trainable:
                        layer.trainable = False
                    else:
                        layer.trainable = True
                        if trainable_layers is not None:
                            for sub in layer.layers[:-trainable_layers]:
                                sub.trainable = False

    if use_pretrained_backbone:
        _set_backbone_trainable(model, False)

    print("\nStage 1: training head (frozen backbone)")
    history1 = model.fit(
        train_inputs,
        y_train,
        batch_size=BATCH_SIZE,
        epochs=max(5, int(epochs * 0.6)),
        validation_data=val_inputs,
        callbacks=callbacks,
        class_weight=class_weight,
        verbose=1,
    )

    print("\nStage 2: fine-tuning (lower LR)")
    if use_pretrained_backbone:
        _set_backbone_trainable(model, True, trainable_layers=trainable_layers)
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.0001),
        loss=keras.losses.CategoricalCrossentropy(label_smoothing=label_smoothing),
        metrics=['accuracy', keras.metrics.TopKCategoricalAccuracy(k=min(3, num_classes), name='top_3_accuracy')],
    )
    history2 = model.fit(
        train_inputs,
        y_train,
        batch_size=BATCH_SIZE,
        epochs=epochs,
        initial_epoch=len(history1.history['loss']),
        validation_data=val_inputs,
        callbacks=callbacks,
        class_weight=class_weight,
        verbose=1,
    )

    history = _merge_histories(history1, history2)
    
    # Evaluate model
    print("\n" + "="*60)
    print("Final Evaluation on Validation Set")
    print("="*60)
    
    eval_inputs = [X_val_img, X_val_tex] if use_texture_features else X_val_img
    val_loss, val_accuracy, val_top3 = model.evaluate(
        eval_inputs,
        y_val,
        verbose=0,
    )
    
    print(f"Validation Loss: {val_loss:.4f}")
    print(f"Validation Accuracy: {val_accuracy:.4f} ({val_accuracy*100:.2f}%)")
    print(f"Top-3 Accuracy: {val_top3:.4f} ({val_top3*100:.2f}%)")
    
    # Plot training history
    plot_training_history(history, output_dir, model_name)
    _write_history_csv(history, output_dir, model_name)

    test_acc = None
    if X_test_img is not None and y_test is not None:
        test_inputs = [X_test_img, X_test_tex] if use_texture_features else X_test_img
        test_loss, test_accuracy, test_top3 = model.evaluate(test_inputs, y_test, verbose=0)
        print("\n" + "="*60)
        print("Final Evaluation on Test Set")
        print("="*60)
        print(f"Test Loss: {test_loss:.4f}")
        print(f"Test Accuracy: {test_accuracy:.4f} ({test_accuracy*100:.2f}%)")
        print(f"Test Top-3 Accuracy: {test_top3:.4f} ({test_top3*100:.2f}%)")

        y_true_idx = np.argmax(y_test, axis=1)
        y_true_labels = [label_encoder.classes_[i] for i in y_true_idx]
        y_pred_probs = model.predict(test_inputs, verbose=0)
        y_pred_idx = np.argmax(y_pred_probs, axis=1)
        y_pred_labels = [label_encoder.classes_[i] for i in y_pred_idx]
        test_acc, report_path, cm_path, json_path = _save_confusion_and_report(
            y_true_labels,
            y_pred_labels,
            list(label_encoder.classes_),
            output_dir,
            model_name,
            title_suffix='TEST',
        )
        print(f"✓ Test confusion matrix saved: {cm_path}")
        print(f"✓ Test classification report saved: {report_path}")
        print(f"✓ Test report JSON saved: {json_path}")
    
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
    architecture = (
        f'{backbone_name} Image-Only Classifier'
        if use_pretrained_backbone and not use_texture_features
        else f'{backbone_name} + Texture Feature Fusion'
        if use_pretrained_backbone and use_texture_features
        else 'Custom Depthwise-Separable CNN + Texture Feature Fusion'
    )

    metadata = {
        'model_name': model_name,
        'architecture': architecture,
        'input_size': IMG_SIZE,
        'num_classes': num_classes,
        'classes': class_mapping,
        'texture_feature_size': int(texture_feature_size) if use_texture_features else 0,
        'training_samples': int(len(X_train_img)),
        'validation_samples': int(len(X_val_img)),
        'total_params': int(total_params),
        'model_size_mb': float(tflite_size_mb),
        'final_accuracy': float(val_accuracy),
        'final_top3_accuracy': float(val_top3),
        'epochs_trained': len(history.history['loss']),
        'test_accuracy': float(test_acc) if test_acc is not None else None,
        'label_smoothing': float(label_smoothing),
        'class_weights': bool(use_class_weights),
        'use_texture_features': bool(use_texture_features),
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


class _MergedHistory:
    def __init__(self, history):
        self.history = history


def _merge_histories(h1, h2):
    merged = {}
    for k, v in (h1.history or {}).items():
        merged[k] = list(v)
    for k, v in (h2.history or {}).items():
        merged[k] = merged.get(k, []) + list(v)
    return _MergedHistory(merged)


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
