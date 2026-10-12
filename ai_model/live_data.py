"""Real-time inputs for the flood model, built from free public APIs.

Sources
  * Open-Meteo forecast API : hourly rain + soil moisture (past 14 days up to now),
                              current temperature/humidity/wind, elevation
  * Open-Meteo elevation API: 4 neighbouring DEM points -> slope
  * OpenStreetMap (Overpass): distance to nearest river
  * Open-Meteo flood API    : GloFAS river discharge -> river-level PROXY

Honest limits: there is no free live gauge API for Kerala rivers, so river_level_m
is a proxy unless you pass a real gauge reading. See the notes returned with the data.
"""
import math
from functools import lru_cache

import numpy as np
import requests

TIMEOUT = 25
HEADERS = {"User-Agent": "ResQAI-flood-student-project/1.0"}
# Typical river distance in the training data (median, km). Used ONLY as a flagged
# fallback when the OpenStreetMap lookup fails.
DEFAULT_RIVER_DISTANCE_KM = 2.24
FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
FLOOD_URL = "https://flood-api.open-meteo.com/v1/flood"
ELEV_URL = "https://api.open-meteo.com/v1/elevation"
OVERPASS_URL = "https://overpass-api.de/api/interpreter"

# River-level distribution of the training dataset (every 5th percentile, metres).
# Used to turn "how high is the river's discharge vs. the last 60 days" into metres.
_PCT = list(range(0, 101, 5))
_LEVEL_Q = [0.2, 0.51, 0.84, 1.06, 1.25, 1.42, 1.58, 1.71, 1.84, 1.98, 2.11, 2.25, 2.38, 2.52, 2.68, 2.85, 3.04, 3.27, 3.58, 4.07, 8.28]


# ---------------------------------------------------------------- weather
def _window_sum(arr, end, hours):
    window = arr[end - hours + 1: end + 1]
    if len(window) < hours or any(v is None for v in window):
        raise ValueError("Incomplete precipitation data from Open-Meteo")
    return float(sum(window))


def get_weather(lat, lon):
    r = requests.get(
        FORECAST_URL,
        params={
            "latitude": lat,
            "longitude": lon,
            "hourly": "precipitation,soil_moisture_0_to_7cm",
            "current": "temperature_2m,relative_humidity_2m,wind_speed_10m",
            "past_days": 14,
            "forecast_days": 1,
            "timezone": "Asia/Kolkata",
        },
        timeout=TIMEOUT,
    )
    r.raise_for_status()
    d = r.json()

    times = d["hourly"]["time"]
    precip = d["hourly"]["precipitation"]
    soil = d["hourly"]["soil_moisture_0_to_7cm"]
    now = d["current"]["time"]

    idx = max(i for i, t in enumerate(times) if t <= now[:13] + ":59")

    rain_24h = _window_sum(precip, idx, 24)
    rain_3d = _window_sum(precip, idx, 72)
    rain_7d = _window_sum(precip, idx, 168)
    rain_14d = _window_sum(precip, idx, 336)
    # largest 24h block among the last three 24h blocks
    max_3day = max(_window_sum(precip, idx - 24 * k, 24) for k in range(3))

    soil_val = next((soil[i] for i in range(idx, -1, -1) if soil[i] is not None), None)
    if soil_val is None:
        raise ValueError("No soil moisture data from Open-Meteo")

    cur = d["current"]
    return {
        "rainfall_24h_mm": round(rain_24h, 2),
        "rainfall_3d_mm": round(rain_3d, 2),
        "rainfall_7d_mm": round(rain_7d, 2),
        "rainfall_14d_mm": round(rain_14d, 2),
        "max_rainfall_3day_mm": round(max_3day, 2),
        "soil_moisture_pct": round(float(soil_val) * 100.0, 2),  # m3/m3 -> %
        "elevation_m": round(float(d.get("elevation", 0.0)), 1),
        "temperature_c": cur.get("temperature_2m"),
        "humidity_pct": cur.get("relative_humidity_2m"),
        "wind_speed_kmph": cur.get("wind_speed_10m"),
        "_observed_at": now,
    }


# ---------------------------------------------------------------- terrain
@lru_cache(maxsize=512)
def _slope_cached(lat, lon):
    step = 0.0025  # ~275 m
    lats = [lat + step, lat - step, lat, lat]
    lons = [lon, lon, lon + step, lon - step]
    r = requests.get(
        ELEV_URL,
        params={
            "latitude": ",".join(f"{v:.5f}" for v in lats),
            "longitude": ",".join(f"{v:.5f}" for v in lons),
        },
        timeout=TIMEOUT,
    )
    r.raise_for_status()
    n, s, e, w = r.json()["elevation"]
    dy = 2 * step * 111_320.0
    dx = 2 * step * 111_320.0 * math.cos(math.radians(lat))
    dzdy = (n - s) / dy
    dzdx = (e - w) / dx
    return round(math.degrees(math.atan(math.hypot(dzdx, dzdy))), 2)


def get_slope_deg(lat, lon):
    return _slope_cached(round(lat, 3), round(lon, 3))


# ---------------------------------------------------------------- river distance
def _point_segment_m(px, py, ax, ay, bx, by):
    vx, vy = bx - ax, by - ay
    L2 = vx * vx + vy * vy
    t = 0.0 if L2 == 0 else max(0.0, min(1.0, ((px - ax) * vx + (py - ay) * vy) / L2))
    return math.hypot(px - (ax + t * vx), py - (ay + t * vy))


OVERPASS_URLS = [
    OVERPASS_URL,
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
]


@lru_cache(maxsize=512)
def _river_distance_cached(lat, lon):
    radius = 10000
    query = (
        f'[out:json][timeout:20];'
        f'way["waterway"="river"](around:{radius},{lat},{lon});out geom;'
    )
    data, errors = None, []
    for url in OVERPASS_URLS:
        try:
            r = requests.post(url, data={"data": query}, headers=HEADERS, timeout=25)
            r.raise_for_status()
            data = r.json()
            break
        except (requests.RequestException, ValueError) as exc:
            errors.append(f"{url.split('/')[2]}: {exc}")
    if data is None:
        raise requests.RequestException("all Overpass servers failed -> " + " | ".join(errors))

    kx = 111_320.0 * math.cos(math.radians(lat))
    ky = 111_320.0
    best = None
    for el in data.get("elements", []):
        pts = [((p["lon"] - lon) * kx, (p["lat"] - lat) * ky) for p in el.get("geometry", [])]
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            dist = _point_segment_m(0.0, 0.0, ax, ay, bx, by)
            if best is None or dist < best:
                best = dist
    return round((best if best is not None else radius) / 1000.0, 2)


def get_river_distance_km(lat, lon):
    return _river_distance_cached(round(lat, 3), round(lon, 3))


# ---------------------------------------------------------------- river level (proxy)
def get_river_level_proxy(lat, lon):
    r = requests.get(
        FLOOD_URL,
        params={
            "latitude": lat,
            "longitude": lon,
            "daily": "river_discharge",
            "past_days": 60,
            "forecast_days": 1,
        },
        timeout=TIMEOUT,
    )
    r.raise_for_status()
    vals = [v for v in r.json()["daily"]["river_discharge"] if v is not None]
    if len(vals) < 20:
        return None
    current = vals[-1]
    pct = 100.0 * sum(v <= current for v in vals) / len(vals)
    # Cap at the 95th percentile: being the highest value in a 60-day window says
    # little about absolute level, so don't map it to the dataset's extreme tail.
    pct = min(pct, 95.0)
    return round(float(np.interp(pct, _PCT, _LEVEL_Q)), 2)


# ---------------------------------------------------------------- public entry point
def get_live_inputs(latitude, longitude, river_level_m=None, river_distance_km=None):
    """Returns (values, notes). values holds numbers (None = unavailable)."""
    notes = {"sources": {}, "warnings": []}
    w = get_weather(latitude, longitude)  # core data: errors propagate (-> HTTP 502)
    notes["observed_at"] = w.pop("_observed_at")
    values = dict(w)
    notes["sources"].update({
        "rainfall_*": "Open-Meteo hourly precipitation summed over trailing 24h/3d/7d/14d",
        "soil_moisture_pct": "Open-Meteo soil_moisture_0_to_7cm x 100 (topsoil, model estimate)",
        "elevation_m": "Open-Meteo DEM (~90 m)",
    })

    try:
        values["slope_deg"] = get_slope_deg(latitude, longitude)
        notes["sources"]["slope_deg"] = "computed from 4 neighbouring DEM points ~275 m apart"
    except (requests.RequestException, KeyError, ValueError) as exc:
        values["slope_deg"] = None
        notes["warnings"].append(f"slope unavailable: {exc}")

    if river_distance_km is not None:
        values["river_distance_km"] = river_distance_km
        notes["sources"]["river_distance_km"] = "supplied by user"
    else:
        try:
            values["river_distance_km"] = get_river_distance_km(latitude, longitude)
            notes["sources"]["river_distance_km"] = (
                "OpenStreetMap waterway=river (capped at 10 km if none found)"
            )
        except (requests.RequestException, KeyError, ValueError) as exc:
            values["river_distance_km"] = DEFAULT_RIVER_DISTANCE_KM
            notes["sources"]["river_distance_km"] = (
                "ASSUMED typical value from the training data (lookup failed) - "
                "NOT measured; enter the real distance for a better prediction"
            )
            notes["warnings"].append(
                f"river distance lookup failed, assumed {DEFAULT_RIVER_DISTANCE_KM} km: {exc}"
            )

    if river_level_m is not None:
        values["river_level_m"] = river_level_m
        notes["sources"]["river_level_m"] = "supplied by user (gauge reading)"
    else:
        try:
            values["river_level_m"] = get_river_level_proxy(latitude, longitude)
            notes["sources"]["river_level_m"] = (
                "PROXY: GloFAS discharge percentile (last 60 days) mapped onto the "
                "training dataset's river-level distribution. Not a gauge reading."
            )
            if values["river_level_m"] is None:
                notes["warnings"].append("river discharge unavailable at this point")
        except (requests.RequestException, KeyError, ValueError) as exc:
            values["river_level_m"] = None
            notes["warnings"].append(f"river level unavailable: {exc}")

    return values, notes