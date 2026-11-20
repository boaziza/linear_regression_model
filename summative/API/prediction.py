from pathlib import Path
from typing import Literal

import joblib
from fastapi import FastAPI
from pydantic import BaseModel, Field

MODEL_PATH = Path(__file__).parent / "best_model.pkl"

model = joblib.load(MODEL_PATH)

app = FastAPI(
    title="Rwanda Youth Wage Predictor",
    description="Predicts the monthly income (RWF) of employed youth aged 16-30 "
                "using NISR EICV VUP microdata.",
    version="1.0.0",
)

class YouthProfile(BaseModel):
    model_config = {"extra": "forbid"}

    age: int = Field(..., ge=16, le=30, description="Age in years (youth range 16-30)")
    sex: Literal["Male", "Female"]
    area: Literal["Urban", "Rural"]
    province: Literal["City of Kigali", "Eastern", "Northern", "Southern", "Western"]
    poverty_status: Literal["Non Poor", "Moderately poor", "Severaly Poor"]
    attended_school_last_12m: bool
    consumption_quintile: Literal["Poor", "Poor/mid", "Mid", "Mid/upper", "Upper"]

    model_config["json_schema_extra"] = {
        "example": {
            "age": 25,
            "sex": "Female",
            "area": "Urban",
            "province": "City of Kigali",
            "poverty_status": "Non Poor",
            "attended_school_last_12m": False,
            "consumption_quintile": "Upper",
        }
    }

@app.get("/")
def home():
    return {
        "message": "API is running. Go to /docs to test it.",
        "model": type(model.named_steps["model"]).__name__,
        "n_features": len(model.feature_names_in_),
    }