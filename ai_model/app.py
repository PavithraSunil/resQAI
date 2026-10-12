import json
from pathlib import Path
from typing import Optional

import joblib
import pandas as pd
import requests
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from features import RAW_FEATURES, add_features
from live_data import get_live_inputs

BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "models"

app = FastAPI(title="Kerala Flood Prediction API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = joblib.load(MODEL_DIR / "flood_model.joblib")
with open(MODEL_DIR / "flood_meta.json") as f:
    meta = json.load(f)
THRESHOLD = float(meta["threshold"])
HIGH_RISK = 0.30  # simple display tier above the alert threshold

NOTE = ("Experimental prediction based on a synthetic dataset; "
        "not an official flood warning.")


class FloodInput(BaseModel):
    rainfall_24h_mm: float = Field(ge=0)
    rainfall_3d_mm: float = Field(ge=0)
    rainfall_7d_mm: float = Field(ge=0)
    rainfall_14d_mm: float = Field(ge=0)
    max_rainfall_3day_mm: float = Field(ge=0)
    soil_moisture_pct: float = Field(ge=0, le=100)
    river_level_m: float
    river_distance_km: float = Field(ge=0)
    elevation_m: float
    slope_deg: float = Field(ge=0, le=90)

    # Accepted so older frontends keep working; the model ignores them.
    wind_speed_kmph: Optional[float] = None
    temperature_c: Optional[float] = None
    humidity_pct: Optional[float] = None
    rainfall_change_24h_pct: Optional[float] = None
    previous_event_7d: Optional[int] = None
    days_since_previous_event: Optional[float] = None
    latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    longitude: Optional[float] = Field(default=None, ge=-180, le=180)


def run_model(values: dict) -> dict:
    row = {name: float(values[name]) for name in RAW_FEATURES}
    # log1p() in add_features needs non-negative inputs (coastal DEM can be < 0)
    for name in ("elevation_m", "river_distance_km", "slope_deg"):
        row[name] = max(row[name], 0.0)
    raw = pd.DataFrame([row], columns=RAW_FEATURES)
    probability = float(model.predict_proba(add_features(raw))[0][1])
    prediction = int(probability >= THRESHOLD)
    if probability >= HIGH_RISK:
        level = "high"
    elif prediction == 1:
        level = "elevated"
    else:
        level = "low"
    return {
        "flood_prediction": prediction,
        "flood_probability": round(probability, 4),
        "risk_level": level,
        "threshold_used": THRESHOLD,
        "message": (
            "Flood conditions predicted by the model"
            if prediction == 1
            else "Flood conditions not predicted by the model"
        ),
        "note": NOTE,
    }


def fetch_live(latitude, longitude, river_level_m, river_distance_km):
    if not (-90 <= latitude <= 90):
        raise HTTPException(400, "Invalid latitude")
    if not (-180 <= longitude <= 180):
        raise HTTPException(400, "Invalid longitude")
    try:
        values, notes = get_live_inputs(
            latitude, longitude,
            river_level_m=river_level_m,
            river_distance_km=river_distance_km,
        )
    except (requests.RequestException, ValueError, KeyError) as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Could not retrieve live weather data: {exc}",
        ) from exc
    missing = [k for k in RAW_FEATURES if values.get(k) is None]
    return values, notes, missing


@app.get("/live-inputs")
def live_inputs(latitude: float, longitude: float,
                river_level_m: Optional[float] = None,
                river_distance_km: Optional[float] = None):
    values, notes, missing = fetch_live(
        latitude, longitude, river_level_m, river_distance_km)
    return {
        "latitude": latitude,
        "longitude": longitude,
        "observed_at": notes.get("observed_at"),
        "inputs": values,
        "sources": notes["sources"],
        "warnings": notes["warnings"],
        "missing_features": missing,
        "prediction_ready": len(missing) == 0,
    }


@app.get("/predict-live")
def predict_live(latitude: float, longitude: float,
                 river_level_m: Optional[float] = None,
                 river_distance_km: Optional[float] = None):
    """Fetch real-time inputs for a location and predict in one call."""
    values, notes, missing = fetch_live(
        latitude, longitude, river_level_m, river_distance_km)
    if missing:
        raise HTTPException(
            status_code=422,
            detail={
                "error": "Some inputs are unavailable",
                "missing_features": missing,
                "warnings": notes["warnings"],
                "hint": "Pass river_level_m / river_distance_km as query "
                        "parameters if you have them.",
            },
        )
    try:
        result = run_model(values)
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error)) from error
    result.update({
        "latitude": latitude,
        "longitude": longitude,
        "observed_at": notes.get("observed_at"),
        "inputs": {k: values[k] for k in RAW_FEATURES},
        "sources": notes["sources"],
        "warnings": notes["warnings"],
    })
    return result


@app.get("/")
def home():
    return {
        "message": "Kerala Flood Prediction API is running",
        "model": meta["model"],
        "docs": "/docs",
    }


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": model is not None}


@app.post("/predict")
def predict_flood(data: FloodInput):
    try:
        return run_model(data.model_dump())
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error)) from error