import base64
import json
import os
import io

import numpy as np
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image
from skimage.feature import graycomatrix, graycoprops, local_binary_pattern


def _load_interpreter(model_path: str):
    try:
        from tflite_runtime.interpreter import Interpreter
    except Exception:
        from tensorflow.lite.python.interpreter import Interpreter

    interpreter = Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    return interpreter


def _read_classes_json(path: str):
    with open(path, "r", encoding="utf-8") as f:
        decoded = json.load(f)
    items = sorted(((int(k), str(v)) for k, v in decoded.items()), key=lambda x: x[0])
    return [v for _, v in items]


def _preprocess_image_rgb(image_bytes: bytes, size: int):
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB").resize((size, size))
    arr = np.asarray(image).astype(np.float32)
    return np.expand_dims(arr, axis=0)


def _texture_features(image_bytes: bytes, size: int):
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB").resize((size, size))
    arr = np.asarray(image).astype(np.float32)
    gray = (0.299 * arr[..., 0] + 0.587 * arr[..., 1] + 0.114 * arr[..., 2]).astype(np.uint8)

    glcm_distances = [1, 2, 3]
    glcm_angles = [0, np.pi / 4, np.pi / 2, 3 * np.pi / 4]
    glcm_properties = ["contrast", "dissimilarity", "homogeneity", "energy", "correlation", "ASM"]

    glcm = graycomatrix(
        gray,
        distances=glcm_distances,
        angles=glcm_angles,
        levels=256,
        symmetric=True,
        normed=True,
    )

    glcm_features = []
    for prop in glcm_properties:
        glcm_features.extend(graycoprops(glcm, prop).flatten().tolist())

    lbp_radius = 3
    lbp_points = 8 * lbp_radius
    lbp = local_binary_pattern(gray, lbp_points, lbp_radius, method="uniform")
    n_bins = int(lbp.max() + 1)
    hist, _ = np.histogram(lbp.ravel(), bins=n_bins, range=(0, n_bins), density=True)

    features = np.concatenate([np.array(glcm_features, dtype=np.float32), hist.astype(np.float32)])
    return features


class PredictRequest(BaseModel):
    image_base64: str


app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSETS_MODELS = os.path.join(ROOT, "assets", "models")

SOIL_MODEL = os.path.join(ASSETS_MODELS, "soil_classifier_model.tflite")
SOIL_CLASSES = os.path.join(ASSETS_MODELS, "soil_classifier_classes.json")
WASTE_MODEL = os.path.join(ASSETS_MODELS, "waste_classifier_model.tflite")
WASTE_CLASSES = os.path.join(ASSETS_MODELS, "waste_classifier_classes.json")

_soil_interpreter = None
_waste_interpreter = None
_soil_labels = None
_waste_labels = None


@app.on_event("startup")
def _startup():
    global _soil_interpreter, _waste_interpreter, _soil_labels, _waste_labels
    _soil_interpreter = _load_interpreter(SOIL_MODEL)
    _waste_interpreter = _load_interpreter(WASTE_MODEL)
    _soil_labels = _read_classes_json(SOIL_CLASSES)
    _waste_labels = _read_classes_json(WASTE_CLASSES)


def _predict(interpreter, image_bytes: bytes, labels):
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    image_input = _preprocess_image_rgb(image_bytes, 224)
    texture = _texture_features(image_bytes, 224).astype(np.float32)
    texture_input = np.expand_dims(texture, axis=0)

    def _set_input_tensor(detail, value):
        value = np.asarray(value)
        expected_dtype = detail.get("dtype", value.dtype)
        if value.dtype != expected_dtype:
            value = value.astype(expected_dtype)

        if expected_dtype == np.uint8:
            scale, zero_point = detail.get("quantization", (0.0, 0))
            if scale and scale > 0:
                value = np.round(value / scale + zero_point).clip(0, 255).astype(np.uint8)

        interpreter.set_tensor(detail["index"], value)

    if len(input_details) == 1:
        _set_input_tensor(input_details[0], image_input)
    else:
        image_detail = None
        texture_detail = None
        for d in input_details:
            shape = d.get("shape", [])
            if len(shape) == 4:
                image_detail = d
            elif len(shape) == 2:
                texture_detail = d

        if image_detail is None or texture_detail is None:
            image_detail = input_details[0]
            texture_detail = input_details[1]

        _set_input_tensor(image_detail, image_input)
        _set_input_tensor(texture_detail, texture_input)

    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]["index"])
    probs = output[0].astype(np.float32)
    max_index = int(np.argmax(probs))
    label = labels[max_index] if max_index < len(labels) else labels[0]
    confidence = float(probs[max_index]) if probs.size else 0.0
    return label, confidence, probs.tolist()


@app.post("/predict/soil")
def predict_soil(req: PredictRequest):
    image_bytes = base64.b64decode(req.image_base64)
    label, confidence, probs = _predict(_soil_interpreter, image_bytes, _soil_labels)
    return {"label": label, "confidence": confidence, "probabilities": probs, "labels": _soil_labels}


@app.post("/predict/waste")
def predict_waste(req: PredictRequest):
    image_bytes = base64.b64decode(req.image_base64)
    label, confidence, probs = _predict(_waste_interpreter, image_bytes, _waste_labels)
    return {"label": label, "confidence": confidence, "probabilities": probs, "labels": _waste_labels}
