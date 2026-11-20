from pathlib import Path

import joblib
from fastapi import FastAPI

MODEL_PATH = Path(__file__).parent / "best_model.pkl"

model = joblib.load(MODEL_PATH)

app = FastAPI(
    title="Rwanda Youth Wage Predictor",
    description="Predicts the monthly income (RWF) of employed youth aged 16-30 "
                "using NISR EICV VUP microdata.",
    version="1.0.0",
)

@app.get("/")
def home():
    return {
        "message": "API is running. Go to /docs to test it.",
        "model": type(model.named_steps["model"]).__name__,
        "n_features": len(model.feature_names_in_),
    }