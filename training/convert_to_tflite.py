"""
Script to convert trained Keras models to TFLite format
"""
import tensorflow as tf
import os
from pathlib import Path

def convert_to_tflite(h5_path, output_path):
    """Convert a Keras .h5 model to TFLite format"""
    print(f"Loading model from: {h5_path}")
    model = tf.keras.models.load_model(h5_path)
    
    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    converter._experimental_lower_tensor_list_ops = False
    
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    size_mb = len(tflite_model) / (1024 * 1024)
    print(f"✓ Saved: {output_path} ({size_mb:.2f} MB)")
    return True

if __name__ == "__main__":
    project_root = Path(__file__).parent.parent
    models_dir = project_root / 'assets' / 'models'
    
    # Convert waste classifier
    waste_h5 = models_dir / 'waste_classifier_best.h5'
    waste_tflite = models_dir / 'waste_classifier_model.tflite'
    
    if waste_h5.exists():
        convert_to_tflite(str(waste_h5), str(waste_tflite))
    else:
        print(f"Model not found: {waste_h5}")
    
    # Convert soil classifier if exists
    soil_h5 = models_dir / 'soil_classifier_best.h5'
    soil_tflite = models_dir / 'soil_classifier_model.tflite'
    
    if soil_h5.exists():
        convert_to_tflite(str(soil_h5), str(soil_tflite))
    else:
        print(f"Soil model not found yet: {soil_h5}")
