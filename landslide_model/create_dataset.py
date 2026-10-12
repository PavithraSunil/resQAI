
import pandas as pd
import numpy as np

# Generate a dummy dataset for testing only
np.random.seed(42)
n = 1000

rainfall_24h = np.random.uniform(0, 250, n)
rainfall_3day = rainfall_24h + np.random.uniform(0, 300, n)
soil_moisture = np.random.uniform(10, 100, n)
slope_angle = np.random.uniform(0, 60, n)

latitude = np.random.uniform(8.2, 12.8, n)
longitude = np.random.uniform(74.8, 77.4, n)

# Synthetic rule for demonstration, not a real hazard model
risk_score = (
    (rainfall_24h > 100).astype(int)
    + (rainfall_3day > 200).astype(int)
    + (soil_moisture > 70).astype(int)
    + (slope_angle > 30).astype(int)
)

landslide = (risk_score >= 3).astype(int)

df = pd.DataFrame({
    "rainfall_24h_mm": rainfall_24h.round(2),
    "rainfall_3day_mm": rainfall_3day.round(2),
    "soil_moisture_pct": soil_moisture.round(2),
    "slope_angle_deg": slope_angle.round(2),
    "latitude": latitude.round(5),
    "longitude": longitude.round(5),
    "landslide": landslide
})

df.to_csv("landslide_data.csv", index=False)

print("Dummy dataset created successfully!")
print("Rows:", len(df))
print("Landslide examples:", int(df["landslide"].sum()))
print("No-landslide examples:", int((df["landslide"] == 0).sum()))
print("Saved as landslide_data.csv")
