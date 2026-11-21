from pathlib import Path
import joblib
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

API_DIR = Path(__file__).parent
ORIGINAL_DATA = API_DIR / "retrain_sample.csv"
MODEL_PATH = API_DIR / "best_model.pkl"

def retrain_model(new_rows: pd.DataFrame, encode) -> tuple[Pipeline, int]:
    original = pd.read_csv(ORIGINAL_DATA)
    combined = pd.concat([original, new_rows], ignore_index=True)
    X = encode(combined.drop(columns=["monthly_income"]))
    y = combined["monthly_income"]
    new_model = Pipeline([("scaler", StandardScaler()), ("model", LinearRegression())]).fit(X, y)
    joblib.dump(new_model, MODEL_PATH)
    return new_model, len(combined)