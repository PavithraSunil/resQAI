"""Quick tests for the trained flood model.

Run from the ai_model folder:
    python test_model.py
    python test_model.py --csv dataset/Kerala_flood_synthetic_v2.csv
"""
import argparse
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import (average_precision_score, confusion_matrix,
                             roc_auc_score)

from features import RAW_FEATURES, add_features

BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "models"

model = joblib.load(MODEL_DIR / "flood_model.joblib")
meta = json.load(open(MODEL_DIR / "flood_meta.json"))
THRESHOLD = float(meta["threshold"])


def predict(rows):
    df = pd.DataFrame(rows, columns=RAW_FEATURES)
    return model.predict_proba(add_features(df))[:, 1]


# ------------------------------------------------------------------ 1. scenarios
# order: rain24, rain3d, rain7d, rain14d, max3d, soil%, river level, river km, elev, slope
SCENARIOS = {
    "Dry highland":                 ([2, 5, 10, 20, 4, 25, 1.2, 5.0, 300, 10], "low"),
    "Normal monsoon day":           ([30, 70, 140, 250, 35, 45, 2.2, 2.2, 20, 3], "low"),
    "Heavy rain, wet soil":         ([90, 180, 260, 330, 100, 55, 4.2, 1.0, 40, 6], "high"),
    "Extreme, low area near river": ([120, 250, 350, 450, 140, 70, 5.0, 0.3, 5, 1], "high"),
}


def test_scenarios():
    print("1. SCENARIOS (does the model respond sensibly?)")
    ok = True
    for name, (values, expect) in SCENARIOS.items():
        p = float(predict([values])[0])
        alert = p >= THRESHOLD
        passed = alert if expect == "high" else not alert
        ok &= passed
        print(f"   {'PASS' if passed else 'FAIL'}  {name:30s} "
              f"probability {p:6.1%}  alert={'YES' if alert else 'no '} "
              f"(expected {'alert' if expect == 'high' else 'no alert'})")
    return ok


# ------------------------------------------------------------------ 2. sweeps
def test_monotonic():
    print("\n2. TREND CHECKS (risk should rise with rain / river level, fall with elevation)")
    base = np.array(SCENARIOS["Normal monsoon day"][0], dtype=float)
    sweeps = {
        "rainfall (all windows x0.5 -> x4)": lambda k: base * np.array([k] * 5 + [1] * 5),
        "river level (1 -> 6 m)": lambda k: np.where(np.arange(10) == 6, 1 + 5 * k, base),
        "elevation (5 -> 300 m)": lambda k: np.where(np.arange(10) == 8, 5 + 295 * k, base),
    }
    ok = True
    for name, make in sweeps.items():
        ks = np.linspace(0.5, 4, 8) if name.startswith("rain") else np.linspace(0, 1, 8)
        probs = predict([make(k) for k in ks])
        increasing = bool(np.all(np.diff(probs) >= -1e-6))
        decreasing = bool(np.all(np.diff(probs) <= 1e-6))
        want_up = not name.startswith("elevation")
        passed = increasing if want_up else decreasing
        ok &= passed
        print(f"   {'PASS' if passed else 'WARN'}  {name:36s} "
              f"{probs[0]:.1%} -> {probs[-1]:.1%}")
    return ok


# ------------------------------------------------------------------ 3. held-out data
def test_holdout(csv_path):
    print("\n3. HELD-OUT TEST DATA (last 20% by date, never used for training)")
    df = pd.read_csv(csv_path)
    df.columns = df.columns.str.strip()
    df["date"] = pd.to_datetime(df["date"], errors="coerce")
    df = df.dropna(subset=["date", "flood_event"] + RAW_FEATURES)
    df = df.sort_values("date", kind="stable").reset_index(drop=True)
    test = df.iloc[int(len(df) * 0.8):]
    y = test["flood_event"].astype(int).values
    p = model.predict_proba(add_features(test[RAW_FEATURES]))[:, 1]
    pred = (p >= THRESHOLD).astype(int)
    tn, fp, fn, tp = confusion_matrix(y, pred, labels=[0, 1]).ravel()
    print(f"   rows {len(y)}, floods {y.sum()} (baseline rate {y.mean():.1%})")
    print(f"   PR-AUC  {average_precision_score(y, p):.3f}   ROC-AUC {roc_auc_score(y, p):.3f}")
    print(f"   at threshold {THRESHOLD:.2f}: caught {tp} of {tp + fn} floods "
          f"(recall {tp / max(tp + fn, 1):.0%}), {fp} false alarms "
          f"(precision {tp / max(tp + fp, 1):.0%})")
    print("   Reminder: this is synthetic data, so it says nothing about real-world accuracy.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default=str(BASE_DIR / "dataset" / "Kerala_flood_synthetic_v2.csv"))
    args = ap.parse_args()

    print(f"Model: {meta['model']}   alert threshold: {THRESHOLD}\n")
    a = test_scenarios()
    b = test_monotonic()
    if Path(args.csv).exists():
        test_holdout(args.csv)
    else:
        print(f"\n3. Skipped hold-out test: CSV not found at {args.csv}")
    print("\nRESULT:", "all checks passed" if (a and b) else "some checks need a look")