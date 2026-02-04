# Web ML Inference Server

Flutter web (Chrome) can’t run `tflite_flutter` in the browser, so the web app calls this local server to run the real `.tflite` models and return predictions.

## Start

```bash
python -m pip install -r server/requirements.txt
```

Then install **one** TFLite runtime option:

- Option A (preferred if available): `tflite-runtime`
- Option B: `tensorflow` (provides `tf.lite.Interpreter`)

Run:

```bash
python -m uvicorn server.inference_server:app --host 127.0.0.1 --port 8000
```

The Flutter web app calls:
- `POST http://127.0.0.1:8000/predict/soil`
- `POST http://127.0.0.1:8000/predict/waste`

Base URL is configured in [constants.dart](file:///c:/NGO-Project/lib/utils/constants.dart).

