
import pickle
import pandas as pd

# Load the saved model
with open("landslide_model.pkl", "rb") as file:
    saved_data = pickle.load(file)

model = saved_data["model"]
features = saved_data["features"]

# Sample input for testing only
sample = pd.DataFrame([{
    "rainfall_24h_mm": 150,
    "rainfall_3day_mm": 280,
    "soil_moisture_pct": 85,
    "slope_angle_deg": 40,
    "latitude": 10.52,
    "longitude": 76.21
}], columns=features)

# Predict using the trained model
prediction = model.predict(sample)[0]
probabilities = model.predict_proba(sample)[0]

print("\n--- ResQAI Landslide Model Test ---")
print("Sample rainfall (24 hours): 150 mm")
print("Sample rainfall (3 days): 280 mm")
print("Sample soil moisture: 85%")
print("Sample slope: 40 degrees")

print("\nModel output:",
      "Landslide example (1)" if prediction == 1
      else "No-landslide example (0)")

print("Model probability for each class:")
for label, probability in zip(model.classes_, probabilities):
    print(f"Class {label}: {probability:.2%}")

print("\nTest completed successfully.")
print("This is a synthetic-data demonstration, not a real risk warning.")
