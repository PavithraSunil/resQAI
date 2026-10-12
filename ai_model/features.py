import numpy as np
import pandas as pd
 
# Only the columns that carry signal. Dropped on purpose:
# latitude/longitude (random per row), wind, temperature, humidity (no signal),
# previous_event_7d / days_since_previous_event (inconsistent in the dataset).
RAW_FEATURES = [
    "rainfall_24h_mm",
    "rainfall_3d_mm",
    "rainfall_7d_mm",
    "rainfall_14d_mm",
    "max_rainfall_3day_mm",
    "soil_moisture_pct",
    "river_level_m",
    "river_distance_km",
    "elevation_m",
    "slope_deg",
]
 
# Physically sensible direction of effect for XGBoost (1 = risk up, -1 = down, 0 = free)
MONOTONE = {
    "log_rainfall_24h_mm": 1,
    "log_rainfall_3d_mm": 1,
    "log_rainfall_7d_mm": 1,
    "log_rainfall_14d_mm": 0,
    "log_max_rainfall_3day_mm": 0,
    "soil_moisture_pct": 1,
    "river_level_m": 1,
    "log_river_distance_km": -1,
    "log_elevation_m": -1,
    "slope_deg": 0,
    "rain_burst_ratio": 0,
    "soil_x_rain3d": 0,
}
 
 
def add_features(df: pd.DataFrame) -> pd.DataFrame:
    X = pd.DataFrame(index=df.index)
    for c in ["rainfall_24h_mm", "rainfall_3d_mm", "rainfall_7d_mm",
              "rainfall_14d_mm", "max_rainfall_3day_mm"]:
        X[f"log_{c}"] = np.log1p(df[c])
    X["soil_moisture_pct"] = df["soil_moisture_pct"]
    X["river_level_m"] = df["river_level_m"]
    X["log_river_distance_km"] = np.log1p(df["river_distance_km"])
    X["log_elevation_m"] = np.log1p(df["elevation_m"])
    X["slope_deg"] = df["slope_deg"]
    # how "bursty" the rain was: share of the week's rain that fell in the last 24h
    X["rain_burst_ratio"] = df["rainfall_24h_mm"] / (df["rainfall_7d_mm"] + 1.0)
    # wet soil AND heavy 3-day rain
    X["soil_x_rain3d"] = df["soil_moisture_pct"] / 100.0 * X["log_rainfall_3d_mm"]
    return X
 
