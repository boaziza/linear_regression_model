from pathlib import Path

import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

# Cleaned training data exported by the notebook (the original 1,381 rows)
ORIGINAL_DATA_PATH = Path(__file__).parent / "retrain_sample.csv"

FEATURES = ["s1q3y", "s1q1", "ur", "province", "poverty", "s4aq7", "quintile", "s4aq2"]
TARGET = "monthly_income"
REQUIRED_COLUMNS = FEATURES + [TARGET]

VALID_VALUES = {
    "s1q1": {"Male", "Female"},
    "ur": {"Urban", "Rural"},
    "province": {"City of Kigali", "Eastern", "Northern", "Southern", "Western"},
    "poverty": {"Non Poor", "Moderately poor", "Severaly Poor"},
    "s4aq7": {"Yes", "No"},
    "quintile": {"Poor", "Poor/mid", "Mid", "Mid/upper", "Upper"},
    "s4aq2": {"Primary", "INGOBOKA /Vocational training", "Lower secondary", "Upper secondary", "Tertiary"},
}


def encode_features(raw: pd.DataFrame, columns) -> pd.DataFrame:
    raw = raw.copy()
    raw["s1q3y"] = raw["s1q3y"].astype(float)
    X = pd.get_dummies(raw, drop_first=False)
    return X.reindex(columns=columns, fill_value=0).astype(float)


def clean(df: pd.DataFrame) -> pd.DataFrame:
    df = df[REQUIRED_COLUMNS].copy()
    df["s1q3y"] = pd.to_numeric(df["s1q3y"], errors="coerce")
    df[TARGET] = pd.to_numeric(df[TARGET], errors="coerce")
    df = df.dropna()
    df = df[df["s1q3y"].between(16, 30)]
    for col, allowed in VALID_VALUES.items():
        df = df[df[col].isin(allowed)]
    return df


def retrain_model(new_rows: pd.DataFrame, columns):
    new_clean = clean(new_rows)
    if new_clean.empty:
        raise ValueError("The uploaded file has no valid rows.")

    original = clean(pd.read_csv(ORIGINAL_DATA_PATH))
    combined = pd.concat([original, new_clean], ignore_index=True)

    X = encode_features(combined[FEATURES], columns)
    y = combined[TARGET]

    new_model = Pipeline([("scaler", StandardScaler()), ("model", LinearRegression())])
    new_model.fit(X, y)

    stats = {
        "original_rows": len(original),
        "new_rows": len(new_clean),
        "rows_used": len(combined),
        "train_r2": round(new_model.score(X, y), 4),
    }
    return new_model, stats
