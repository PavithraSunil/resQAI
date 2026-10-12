
import pandas as pd
import pickle

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

# 1. Load the dataset
data = pd.read_csv("landslide_data.csv")

# 2. Select the input features and target
features = [
    "rainfall_24h_mm",
    "rainfall_3day_mm",
    "soil_moisture_pct",
    "slope_angle_deg",
    "latitude",
    "longitude"
]

X = data[features]
y = data["landslide"]

# 3. Split data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

# 4. Create and train the Random Forest model
model = RandomForestClassifier(
    n_estimators=100,
    random_state=42,
    class_weight="balanced"
)

model.fit(X_train, y_train)

# 5. Evaluate the model
predictions = model.predict(X_test)

print("\n--- Random Forest Training Results ---")
print("Training rows:", len(X_train))
print("Testing rows:", len(X_test))
print("Test accuracy:", round(accuracy_score(y_test, predictions), 4))

print("\nClassification Report:")
print(classification_report(y_test, predictions, zero_division=0))

print("Confusion Matrix:")
print(confusion_matrix(y_test, predictions))

# 6. Save the trained model and feature names
with open("landslide_model.pkl", "wb") as file:
    pickle.dump(
        {"model": model, "features": features},
        file
    )

print("\nModel saved successfully as landslide_model.pkl")
