"""
Train only the Soil Classification Model from a soil image dataset.
"""
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from training.train_custom_cnn_with_texture import train_model

if __name__ == "__main__":
    output_dir = project_root / 'assets' / 'models'
    output_dir.mkdir(parents=True, exist_ok=True)

    soil_dataset = project_root / 'Orignal-Dataset'
    if soil_dataset.exists():
        print("="*60)
        print("TRAINING SOIL CLASSIFICATION MODEL")
        print("EfficientNetV2B0 + Texture Feature Fusion")
        print("="*60)
        print(f"\nOutput directory: {output_dir}")
        train_model(
            dataset_path=str(soil_dataset),
            output_dir=str(output_dir),
            model_name='soil_classifier',
            epochs=40,
            augment_multiplier=2,
            use_pretrained_backbone=True,
            trainable_layers=40,
            use_class_weights=True,
            label_smoothing=0.03,
            use_texture_features=True,
            backbone_name='efficientnetv2b0',
            val_size=0.15,
            test_size=0.15,
        )
        print("\n✓ Training complete!")
        print(f"\nModels saved to: {output_dir}")
    else:
        print(f"Soil dataset not found at {soil_dataset}")
