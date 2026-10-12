import argparse
import json
from pathlib import Path
 
import joblib
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (average_precision_score, brier_score_loss,
                             confusion_matrix, roc_auc_score)
from sklearn.model_selection import RepeatedStratifiedKFold, cross_val_score
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
 
from features import MONOTONE, RAW_FEATURES, add_features
 
try:
    from xgboost import XGBClassifier
except ImportError:  # lets the script still run without xgboost
    XGBClassifier = None
 
BASE_DIR = Path(__file__).resolve().parent
DEFAULT_CSV = BASE_DIR / "dataset" / "Kerala_flood_synthetic_v2.csv"
MODEL_DIR = BASE_DIR / "models"
 
# Cost of a missed flood relative to a false alarm. Set this from how
# ResQAI will actually be used; 10 means "a miss is 10x worse than a false alarm".
FN_COST, FP_COST = 10.0, 1.0
SEED = 42
 
 
def make_logreg():
    return make_pipeline(StandardScaler(),
                         LogisticRegression(C=1.0, max_iter=3000))
 
 
def make_xgb(cols, early_stopping=False):
    return XGBClassifier(
        objective="binary:logistic", eval_metric="aucpr",
        n_estimators=400 if early_stopping else 200,
        learning_rate=0.05, max_depth=3, min_child_weight=5,
        reg_lambda=5.0, subsample=0.8, colsample_bytree=0.8,
        monotone_constraints=tuple(MONOTONE[c] for c in cols),
        early_stopping_rounds=30 if early_stopping else None,
        random_state=SEED, n_jobs=-1,
    )
 
 
def bootstrap_ci(y, p, metric, n=1000):
    rng = np.random.default_rng(SEED)
    vals = []
    for _ in range(n):
        i = rng.integers(0, len(y), len(y))
        if y[i].sum() == 0:
            continue
        vals.append(metric(y[i], p[i]))
    return np.percentile(vals, [2.5, 97.5])
 
 
def best_threshold(y, p):
    grid = np.arange(0.01, 0.91, 0.01)
    costs = []
    for t in grid:
        pred = p >= t
        fn = ((~pred) & (y == 1)).sum()
        fp = (pred & (y == 0)).sum()
        costs.append(FN_COST * fn + FP_COST * fp)
    return float(grid[int(np.argmin(costs))])
 
 
def main(csv_path):
    df = pd.read_csv(csv_path)
    df.columns = df.columns.str.strip()
    df["date"] = pd.to_datetime(df["date"], errors="coerce")
    df = df.dropna(subset=["date", "flood_event"] + RAW_FEATURES)
    df = df.sort_values("date", kind="stable").reset_index(drop=True)
    y_all = df["flood_event"].astype(int).values
    X_all = add_features(df)
    cols = list(X_all.columns)
    print(f"Rows: {len(df)}  floods: {y_all.sum()}  features: {len(cols)}")
 
    # ---- 1. Compare models with repeated CV (more stable than one 71-flood test set)
    cv = RepeatedStratifiedKFold(n_splits=5, n_repeats=3, random_state=SEED)
    candidates = {"logreg": make_logreg()}
    if XGBClassifier is not None:
        candidates["xgb_constrained"] = make_xgb(cols)
    print("\nRepeated 5x3 CV (PR-AUC, higher is better):")
    cv_scores = {}
    for name, model in candidates.items():
        s = cross_val_score(model, X_all, y_all, cv=cv,
                            scoring="average_precision", n_jobs=1)
        cv_scores[name] = s.mean()
        print(f"  {name:18s} {s.mean():.3f} +/- {s.std():.3f}")
    best = max(cv_scores, key=cv_scores.get)
    print(f"Selected: {best}")
 
    # ---- 2. Chronological 60/20/20 split: train / validation / test
    n = len(df)
    a, b = int(n * 0.6), int(n * 0.8)
    Xtr, Xva, Xte = X_all.iloc[:a], X_all.iloc[a:b], X_all.iloc[b:]
    ytr, yva, yte = y_all[:a], y_all[a:b], y_all[b:]
    print(f"\nTrain {len(ytr)} ({ytr.sum()} floods) | "
          f"Val {len(yva)} ({yva.sum()}) | Test {len(yte)} ({yte.sum()})")
 
    if best == "logreg":
        model = make_logreg().fit(Xtr, ytr)
    else:
        model = make_xgb(cols, early_stopping=True)
        model.fit(Xtr, ytr, eval_set=[(Xva, yva)], verbose=False)
 
    p_va = model.predict_proba(Xva)[:, 1]
    p_te = model.predict_proba(Xte)[:, 1]
 
    # ---- 3. Threshold chosen on VALIDATION only, then applied once to TEST
    thr = best_threshold(yva, p_va)
    pred = (p_te >= thr).astype(int)
    tn, fp, fn, tp = confusion_matrix(yte, pred, labels=[0, 1]).ravel()
    pr_lo, pr_hi = bootstrap_ci(yte, p_te, average_precision_score)
    print(f"\nThreshold (val, FN:FP cost {FN_COST:.0f}:{FP_COST:.0f}) = {thr:.2f}")
    print(f"TEST  PR-AUC {average_precision_score(yte, p_te):.3f} "
          f"(95% CI {pr_lo:.3f}-{pr_hi:.3f}) | "
          f"ROC-AUC {roc_auc_score(yte, p_te):.3f} | "
          f"Brier {brier_score_loss(yte, p_te):.4f}")
    print(f"      baseline PR-AUC (prevalence) = {yte.mean():.3f}")
    print(f"      TP {tp}  FN {fn}  FP {fp}  TN {tn}  "
          f"precision {tp / max(tp + fp, 1):.3f}  recall {tp / max(tp + fn, 1):.3f}")
 
    # ---- 4. Calibration check: predicted vs observed flood rate per risk bin
    bins = pd.qcut(p_te, 5, duplicates="drop")
    cal = pd.DataFrame({"p": p_te, "y": yte}).groupby(bins, observed=True).agg(
        predicted=("p", "mean"), observed=("y", "mean"), n=("y", "size"))
    print("\nCalibration (quintiles of predicted risk):")
    print(cal.round(3).to_string(index=False))
 
    # ---- 5. Save
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, MODEL_DIR / "flood_model.joblib")
    json.dump({"threshold": thr, "raw_features": RAW_FEATURES,
               "engineered_features": cols, "model": best},
              open(MODEL_DIR / "flood_meta.json", "w"), indent=2)
    print(f"\nSaved to {MODEL_DIR}. Metrics are for this synthetic dataset only.")
 
 
if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default=str(DEFAULT_CSV))
    main(ap.parse_args().csv)