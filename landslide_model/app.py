
from flask import Flask, request, jsonify
import os
import pickle
import pandas as pd

app = Flask(__name__)

MODEL_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "landslide_model.pkl"
)

with open(MODEL_PATH, "rb") as file:
    saved_data = pickle.load(file)

model = saved_data["model"]
features = saved_data["features"]


@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "message": "ResQAI Landslide Prediction API is running"
    })


@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "JSON input is required"}), 400

        missing = [feature for feature in features if feature not in data]
        if missing:
            return jsonify({
                "error": "Missing required features",
                "missing_features": missing
            }), 400

        input_data = pd.DataFrame(
            [[float(data[feature]) for feature in features]],
            columns=features
        )

        prediction = int(model.predict(input_data)[0])

        result = {
            "prediction": prediction,
            "risk": "High" if prediction == 1 else "Low",
            "note": "Experimental model output; not an official warning."
        }

        if hasattr(model, "predict_proba"):
            probabilities = model.predict_proba(input_data)[0]
            result["class_probabilities"] = {
                str(label): round(float(probability), 4)
                for label, probability in zip(
                    model.classes_, probabilities
                )
            }

        return jsonify(result)

    except (TypeError, ValueError):
        return jsonify({
            "error": "All six input values must be valid numbers"
        }), 400

    except Exception:
        app.logger.exception("Prediction failed")
        return jsonify({
            "error": "Prediction failed. Check the server logs."
        }), 500



if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=False)

