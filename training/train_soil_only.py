"""
Train only the Soil Classification Model with aggressive augmentation
Saves to training/soil_output to avoid permission issues
"""
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from training.train_custom_cnn_with_texture import train_model

if __name__ == "__main__":
    datasets_dir = project_root / 'datasets'
    # Use training/soil_output to avoid permission issues with existing files
    output_dir = project_root / 'training' / 'soil_output'
    output_dir.mkdir(parents=True, exist_ok=True)
    
    soil_dataset = datasets_dir / 'soil' / 'archive' / 'Orignal-Dataset'
    if soil_dataset.exists():
        print("="*60)
        print("TRAINING SOIL CLASSIFICATION MODEL")
        print("With 5x Aggressive Data Augmentation")
        print("="*60)
        print(f"\nOutput directory: {output_dir}")
        train_model(
            dataset_path=str(soil_dataset),
            output_dir=str(output_dir),
            model_name='soil_classifier',
            epochs=70,
            augment_multiplier=5  # 5x augmentation for small dataset
        )
        print("\n✓ Training complete!")
        print(f"\nModels saved to: {output_dir}")
        print("\nTo move to final location, run:")
        print(f"  cp {output_dir}/*.tflite {project_root}/assets/models/")
        print(f"  cp {output_dir}/*_classes.json {project_root}/assets/models/")
    else:
        print(f"Soil dataset not found at {soil_dataset}")
