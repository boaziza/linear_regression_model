from pathlib import Path
from typing import Literal

import joblib
import pandas as pd
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

MODEL_PATH = Path(__file__).parent / "best_model.pkl"

model = joblib.load(MODEL_PATH)

app = FastAPI(
    title="Rwanda Youth Wage Predictor",
    description="Predicts the monthly income (RWF) of employed youth aged 16-30 "
                "using NISR EICV VUP microdata.",
    version="1.0.0",
)

@app.exception_handler(RequestValidationError)
async def validation_error_handler(request: Request, exc: RequestValidationError):
    errors = [
        {
            "field": ".".join(str(part) for part in err["loc"][1:]) or "body",
            "message": err["msg"],
        }
        for err in exc.errors()
    ]
    return JSONResponse(status_code=400, content={"detail": errors})

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
            "age": 30,
            "sex": "Female",
            "area": "Urban",
            "province": "City of Kigali",
            "poverty_status": "Non Poor",
            "attended_school_last_12m": False,
            "consumption_quintile": "Upper",
        }
    }

def encode(raw: pd.DataFrame) -> pd.DataFrame:
    raw = raw.copy()
    raw["s1q3y"] = raw["s1q3y"].astype(float)
    X = pd.get_dummies(raw, drop_first=False)
    return X.reindex(columns=model.feature_names_in_, fill_value=0).astype(float)

@app.get("/")
def home():
    return {
        "message": "API is running. Go to /docs to test it.",
        "model": type(model.named_steps["model"]).__name__,
        "n_features": len(model.feature_names_in_),
    }

@app.post('/predict')
def predict(profile: YouthProfile):
    row = pd.DataFrame([{
        "s1q3y": profile.age,
        "s1q1": profile.sex,
        "ur": profile.area,
        "province": profile.province,
        "poverty": profile.poverty_status,
        "s4aq7": "Yes" if profile.attended_school_last_12m else "No",
        "quintile": profile.consumption_quintile,
    }])

    X = encode(row)
    prediction = float(model.predict(X)[0])

    return {"predicted_monthly_income_rwf": round(max(prediction, 0.0), 2)}